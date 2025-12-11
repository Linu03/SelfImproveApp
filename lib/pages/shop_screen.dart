import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../models/reward_item.dart';
import '../services/user_profile_repository.dart';
import '../services/task_repository.dart';


class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int? _currentIndex; // null => not highlighted on Shop
  final UserProfileRepository _profileRepo = UserProfileRepository();
  final TaskRepository _taskRepo = TaskRepository();

  late Box<RewardItem> _customBox;
  late Box<RewardItem> _activeBox;
  bool _customBoxReady = false;
  bool _activeBoxReady = false;

  int _coins = 0;

  // Default rewards: coins cost calculated based on task earning potential
  late List<RewardItem> _defaultRewards;

  @override
  void initState() {
    super.initState();
    _registerAdapterIfNeeded();
    _openBoxes();
    _loadProfile();
    _initializeDefaultRewards();
  }

  void _registerAdapterIfNeeded() {
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(RewardItemAdapter());
    }
  }

  void _initializeDefaultRewards() {
    // Default rewards with pricing based on earning potential
    // Average earning: ~10-20 coins per task, so rewards range from 10-100 coins
    _defaultRewards = [
      RewardItem(
        name: 'YouTube 10 min',
        price: 10,
        durationMinutes: 10,
        category: 'Streaming',
      ),
      RewardItem(
        name: 'YouTube 20 min',
        price: 18,
        durationMinutes: 20,
        category: 'Streaming',
      ),
      RewardItem(
        name: 'Netflix episode',
        price: 40,
        durationMinutes: 45,
        category: 'Streaming',
      ),
      RewardItem(
        name: 'Gaming 20 min',
        price: 15,
        durationMinutes: 20,
        category: 'Gaming',
      ),
      RewardItem(
        name: 'Gaming 1 hour',
        price: 40,
        durationMinutes: 60,
        category: 'Gaming',
      ),
      RewardItem(
        name: 'Movie',
        price: 60,
        durationMinutes: 120,
        category: 'Streaming',
      ),
    ];
  }

  Future<void> _openBoxes() async {
    try {
      _customBox = await Hive.openBox<RewardItem>('customRewardsBox');
      _customBoxReady = true;
    } catch (e) {
      debugPrint('Error opening customRewardsBox: $e');
    }

    try {
      _activeBox = await Hive.openBox<RewardItem>('activeRewardsBox');
      _activeBoxReady = true;
    } catch (e) {
      debugPrint('Error opening activeRewardsBox: $e');
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadProfile() async {
    final coins = await _profileRepo.getCoins();
    setState(() {
      _coins = coins;
    });
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/add-task');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/journal');
        break;
    }
  }

  Future<void> _buyReward(RewardItem reward) async {
    // Check coins
    final coins = await _profileRepo.getCoins();
    if (coins < reward.price) {
      _showSnackBar(
        'Not enough coins! Need ${reward.price}, you have $coins.',
        Colors.red,
      );
      return;
    }

    // Deduct coins
    await _profileRepo.addCoins(-reward.price);

    // Add to active rewards (use a copy to avoid Hive instance conflicts)
    if (!_activeBoxReady) {
      _activeBox = await Hive.openBox<RewardItem>('activeRewardsBox');
      _activeBoxReady = true;
    }
    final rewardCopy = reward.copy();
    await _activeBox.add(rewardCopy);

    // Add entertainment minutes if applicable
    if (reward.durationMinutes != null && reward.durationMinutes! > 0) {
      await _profileRepo.addEntertainmentMinutes(reward.durationMinutes!);
    }

    // Reload profile
    await _loadProfile();

    if (mounted) {
      _showSnackBar(
        '🎉 Unlocked "${reward.name}"! -${reward.price} coins',
        Colors.green,
      );
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCreateRewardDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    String selectedCategory = 'Entertainment';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Your Own Reward'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Reward name',
                    hintText: 'e.g., Spotify playlist',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  decoration: InputDecoration(
                    labelText: 'Cost (coins)',
                    hintText: '5',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null
                      ? 'Enter a valid number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: durationCtrl,
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes, optional)',
                    hintText: '30',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: ['Entertainment', 'Gaming', 'Streaming', 'Other']
                      .map(
                        (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedCategory = val;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final name = nameCtrl.text.trim();
              final price = int.parse(priceCtrl.text.trim());
              final duration = int.tryParse(durationCtrl.text.trim());

              final reward = RewardItem(
                name: name,
                price: price,
                durationMinutes: duration,
                category: selectedCategory,
              );

              // Ensure customBox is open
              if (!_customBoxReady) {
                _customBox = await Hive.openBox<RewardItem>('customRewardsBox');
                _customBoxReady = true;
              }

              await _customBox.add(reward);
              Navigator.pop(ctx);

              if (mounted) {
                _showSnackBar('✨ Reward "$name" created!', Colors.indigo);
                setState(() {});
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(
        shopSelected: true,
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === COINS BALANCE ===
              _buildCoinsBalance(),
              const SizedBox(height: 24),

              // === DEFAULT REWARDS ===
              const Text(
                'Recommended Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 12),
              _buildDefaultRewardsList(),
              const SizedBox(height: 24),

              // === CUSTOM REWARDS ===
              const Text(
                'Your Custom Rewards',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
              const SizedBox(height: 12),
              _buildCustomRewardsList(),
              const SizedBox(height: 16),

              // === CREATE BUTTON ===
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCreateRewardDialog,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Your Own Reward'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  /// Build coins balance card
  Widget _buildCoinsBalance() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade400, Colors.orange.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Coins',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_coins',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.monetization_on,
              size: 56,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Build default rewards list (horizontal scroll)
  Widget _buildDefaultRewardsList() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _defaultRewards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final reward = _defaultRewards[index];
          return _buildRewardCard(reward, isDefault: true);
        },
      ),
    );
  }

  /// Build custom rewards list
  Widget _buildCustomRewardsList() {
    if (!_customBoxReady) {
      return SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(Colors.indigo.shade400),
          ),
        ),
      );
    }

    return ValueListenableBuilder<Box<RewardItem>>(
      valueListenable: _customBox.listenable(),
      builder: (context, box, _) {
        final items = box.values.toList();

        if (items.isEmpty) {
          return Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 40,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No custom rewards yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create one below!',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final reward = items[index];
            return _buildRewardCard(reward, isDefault: false);
          },
        );
      },
    );
  }

  /// Individual reward card
  Widget _buildRewardCard(RewardItem reward, {required bool isDefault}) {
    final canBuy = _coins >= reward.price;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: isDefault ? 160 : double.infinity,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reward name
            Text(
              reward.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            // Category
            Text(
              reward.category,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            // Duration (if present)
            if (reward.durationMinutes != null && reward.durationMinutes! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 12,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.durationMinutes} min',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Price and Buy button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: canBuy ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.price}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: canBuy ? Colors.amber.shade700 : Colors.grey,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: canBuy ? () => _buyReward(reward) : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: canBuy ? Colors.indigo : Colors.grey,
                    ),
                    child: const Text('Buy', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
