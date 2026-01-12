import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../models/reward_item.dart';
import '../services/user_profile_repository.dart';
import '../services/task_repository.dart';
import '../pages/my_rewards_screen.dart';

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
        Colors.red.shade700,
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
        Colors.green.shade700,
      );
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        backgroundColor: const Color(0xFF2d1b3d),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.purple.shade700,
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Colors.amber.shade300,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Create Custom Reward',
              style: TextStyle(
                color: Colors.amber.shade200,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  style: TextStyle(color: Colors.amber.shade100),
                  decoration: InputDecoration(
                    labelText: 'Reward name',
                    labelStyle: TextStyle(color: Colors.amber.shade400),
                    hintText: 'e.g., Spotify playlist',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.amber.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: priceCtrl,
                  style: TextStyle(color: Colors.amber.shade100),
                  decoration: InputDecoration(
                    labelText: 'Cost (coins)',
                    labelStyle: TextStyle(color: Colors.amber.shade400),
                    hintText: '5',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.amber.shade700,
                        width: 2,
                      ),
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
                  style: TextStyle(color: Colors.amber.shade100),
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes, optional)',
                    labelStyle: TextStyle(color: Colors.amber.shade400),
                    hintText: '30',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.amber.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: const Color(0xFF2d1b3d),
                  style: TextStyle(color: Colors.cyan.shade300),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: Colors.amber.shade400),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.purple.shade700.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.amber.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                  items: ['Entertainment', 'Gaming', 'Streaming', 'Other']
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(
                            cat,
                            style: TextStyle(color: Colors.cyan.shade300),
                          ),
                        ),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade400),
            ),
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
                _showSnackBar('✨ Reward "$name" created!', Colors.purple.shade700);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1625), // Dark fantasy background
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
              // Merchant Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF2d1b3d),
                      const Color(0xFF1a1625),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.amber.shade700.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: Colors.amber.shade300,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Merchant Shop',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade200,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // === COINS BALANCE ===
              _buildCoinsBalance(),
              const SizedBox(height: 24),

              // === DEFAULT REWARDS ===
              Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.amber.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Featured Rewards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDefaultRewardsList(),
              const SizedBox(height: 24),

              // === CUSTOM REWARDS ===
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.purple.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Your Custom Rewards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade300,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCustomRewardsList(),
              const SizedBox(height: 20),

              // === CREATE BUTTON ===
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade600,
                      Colors.purple.shade800,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.shade900.withOpacity(0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showCreateRewardDialog,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'CREATE CUSTOM REWARD',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade600,
            Colors.amber.shade800,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.amber.shade300.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade900.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      color: Colors.white.withOpacity(0.9),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your Gold',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$_coins',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Coins Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.card_giftcard,
                  size: 40,
                  color: Colors.white.withOpacity(0.95),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyRewardsScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2d1b3d),
                    foregroundColor: Colors.amber.shade300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'My Rewards',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build default rewards list (horizontal scroll)
  Widget _buildDefaultRewardsList() {
    return SizedBox(
      height: 200,
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
            color: Colors.purple.shade400,
            strokeWidth: 3,
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
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2d1b3d).withOpacity(0.5),
                  const Color(0xFF1f1529).withOpacity(0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.purple.shade800.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.card_giftcard_outlined,
                    size: 48,
                    color: Colors.purple.shade700.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No custom rewards yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create one below!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
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
          separatorBuilder: (_, __) => const SizedBox(height: 12),
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

    return Material(
      color: Colors.transparent,
      child: Container(
        width: isDefault ? 170 : double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2d1b3d),
              const Color(0xFF1f1529),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: canBuy
                ? Colors.green.shade600.withOpacity(0.4)
                : Colors.grey.shade800.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: canBuy
              ? [
                  BoxShadow(
                    color: Colors.green.shade900.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reward name
            Text(
              reward.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: canBuy ? Colors.amber.shade200 : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            // Category
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyan.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.cyan.shade700.withOpacity(0.3),
                ),
              ),
              child: Text(
                reward.category,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.cyan.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Duration (if present)
            if (reward.durationMinutes != null && reward.durationMinutes! > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${reward.durationMinutes} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade300,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            // Price and Buy button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canBuy
                          ? [
                              Colors.amber.shade700.withOpacity(0.3),
                              Colors.amber.shade900.withOpacity(0.3),
                            ]
                          : [
                              Colors.grey.shade800.withOpacity(0.3),
                              Colors.grey.shade900.withOpacity(0.3),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: canBuy
                          ? Colors.amber.shade600.withOpacity(0.4)
                          : Colors.grey.shade700.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 16,
                        color: canBuy ? Colors.amber.shade300 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${reward.price}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: canBuy ? Colors.amber.shade200 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: canBuy
                          ? [
                              Colors.green.shade600,
                              Colors.green.shade800,
                            ]
                          : [
                              Colors.grey.shade700,
                              Colors.grey.shade800,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: canBuy
                        ? [
                            BoxShadow(
                              color: Colors.green.shade900.withOpacity(0.5),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canBuy ? () => _buyReward(reward) : null,
                      borderRadius: BorderRadius.circular(10),
                      splashColor: Colors.white.withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Center(
                          child: Text(
                            'BUY',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
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
