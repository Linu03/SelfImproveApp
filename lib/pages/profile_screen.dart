import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../widgets/top_navbar.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/xp_bar.dart';
import '../widgets/hp_bar.dart';
import '../widgets/category_xp_bar.dart';
import '../widgets/avatar_display.dart';
import '../widgets/edit_profile_dialog.dart';
import '../services/user_stats_repository.dart';
import '../services/category_xp_repository.dart';
import '../services/user_profile_repository.dart';
import '../models/user_stats.dart';
import '../models/task.dart';
import '../models/category_xp.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserStatsRepository _statsRepo = UserStatsRepository();
  final CategoryXpRepository _categoryRepo = CategoryXpRepository();
  final UserProfileRepository _profileRepo = UserProfileRepository();

  UserStats? _stats;
  Map<TaskCategory, CategoryXp> _categoryStats = {};
  final Set<TaskCategory> _usedCategories = {};
  String _username = 'Player';
  List<int>? _avatarBytes;
  int _coins = 0;

  late Box<Task> _tasksBox;
  late VoidCallback _tasksListener;

  int? _currentIndex; // bottom nav

  @override
  void initState() {
    super.initState();
    // tasksBox should already be opened in main.dart
    _tasksBox = Hive.box<Task>('tasksBox');
    _tasksListener = () => _reloadFromHive();
    _tasksBox.listenable().addListener(_tasksListener);
    _reloadFromHive();
  }

  @override
  void dispose() {
    try {
      _tasksBox.listenable().removeListener(_tasksListener);
    } catch (e) {}
    super.dispose();
  }

  Future<void> _reloadFromHive() async {
    final s = await _statsRepo.getStats();
    final u = await _profileRepo.getUsername();
    final a = await _profileRepo.getAvatarBytes();
    final c = await _profileRepo.getCoins();

    // Determine used categories from tasks stored in Hive
    final tasks = _tasksBox.values.toList();
    final used = tasks.map((t) => t.category).toSet();

    // Load CategoryXp for each used category
    final Map<TaskCategory, CategoryXp> catStats = {};
    for (final c in used) {
      final cs = await _categoryRepo.getStats(c);
      catStats[c] = cs;
    }

    if (!mounted) return;
    setState(() {
      _stats = s;
      _username = u;
      _avatarBytes = a;
      _coins = c;
      _categoryStats = catStats;
      _usedCategories
        ..clear()
        ..addAll(used);
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

  Future<void> _editUsername() async {
    showDialog(
      context: context,
      builder: (ctx) => EditProfileDialog(
        currentUsername: _username,
        currentAvatarBytes: _avatarBytes,
        onSave: (newUsername, newAvatarBytes) async {
          // Save username
          await _profileRepo.setUsername(newUsername);

          // Save avatar
          if (newAvatarBytes != null) {
            await _profileRepo.setAvatarBytes(newAvatarBytes);
          } else if (_avatarBytes != null) {
            // User removed the avatar
            await _profileRepo.deleteAvatar();
          }

          // Update local state
          setState(() {
            _username = newUsername;
            _avatarBytes = newAvatarBytes;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✏️ Profile updated successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.indigo.shade700,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1625), // Dark fantasy background
      appBar: TopNavbar(
        userSelected: true,
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
      ),
      body: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2d1b3d), const Color(0xFF1a1625)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, color: Colors.amber.shade300, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Character Profile',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade200,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.amber.shade900.withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar and Username Card
                  Container(
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
                        color: Colors.purple.shade700.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.shade900.withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            AvatarDisplay(
                              avatarBytes: _avatarBytes,
                              radius: 40,
                              borderColor: Colors.amber.shade300,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.shade900.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade400,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _username,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade200,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.amber.shade300),
                          onPressed: _editUsername,
                          tooltip: 'Edit profile',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stats Section
                  Text(
                    'Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade200,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Stats Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (_stats != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.amber.shade700.withOpacity(0.3),
                                  Colors.amber.shade900.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.shade400.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.grade,
                                  size: 16,
                                  color: Colors.amber.shade300,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Level ${_stats!.level}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (_stats != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade700.withOpacity(0.3),
                                  Colors.purple.shade900.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.purple.shade400.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.purple.shade300,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'XP ${_stats!.totalXp}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.yellow.shade700.withOpacity(0.3),
                                Colors.yellow.shade900.withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.yellow.shade600.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.monetization_on,
                                size: 16,
                                color: Colors.yellow.shade300,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$_coins',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // XP Bar
                  if (_stats != null)
                    XpBar(
                      currentXp: _stats!.totalXp,
                      xpForNextLevel: _statsRepo.xpForNextLevelOf(_stats!),
                      level: _stats!.level,
                    )
                  else
                    Center(
                      child: CircularProgressIndicator(
                        color: Colors.amber.shade300,
                        strokeWidth: 3,
                      ),
                    ),

                  const SizedBox(height: 16),

                  // HP Bar
                  if (_stats != null)
                    HpBar(
                      currentHp: _stats!.totalHp,
                      maxHp: _statsRepo.getMaxHp(),
                    )
                  else
                    const SizedBox.shrink(),

                  const SizedBox(height: 24),

                  // Category Progress Section
                  Text(
                    'Category Progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade200,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // If no categories used show hint
                  if (_usedCategories.isEmpty)
                    Container(
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
                          color: Colors.purple.shade700.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: 56,
                            color: Colors.purple.shade800.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No categories yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create tasks to see category XP bars appear here.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.6,
                          ),
                      itemCount: _usedCategories.length,
                      itemBuilder: (context, index) {
                        final category = _usedCategories.elementAt(index);
                        final stats = _categoryStats[category];
                        return CategoryXpBar(category: category, stats: stats);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
