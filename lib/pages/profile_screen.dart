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
    final gradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.fromARGB(255, 20, 93, 154), Colors.indigo],
    );

    return Scaffold(
      body: Stack(
        children: [
          // background gradient
          Container(decoration: BoxDecoration(gradient: gradient)),
          SafeArea(
            child: Column(
              children: [
                TopNavbar(
                  userSelected: true,
                  onShopTap: () => Navigator.pushNamed(context, '/shop'),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Card(
                      color: Colors.white.withValues(alpha: 0.95),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar and Username section with edit button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Stack(
                                      children: [
                                        AvatarDisplay(
                                          avatarBytes: _avatarBytes,
                                          radius: 40,
                                          borderColor: Colors.indigo.shade300,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.indigo,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.2),
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
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Welcome back!', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                                        const SizedBox(height: 4),
                                        Text(
                                          _username,
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.indigo),
                                  onPressed: _editUsername,
                                  tooltip: 'Edit profile',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                            // Profile stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    if (_stats != null)
                                      Chip(backgroundColor: Colors.amber.shade100, label: Text('Level ${_stats!.level}')),
                                    const SizedBox(width: 8),
                                    if (_stats != null)
                                      Chip(backgroundColor: Colors.blue.shade50, label: Text('XP ${_stats!.totalXp}')),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_stats != null)
                              XpBar(
                                currentXp: _stats!.totalXp,
                                xpForNextLevel: _statsRepo.xpForNextLevelOf(_stats!),
                                level: _stats!.level,
                              )
                            else
                              const Center(child: CircularProgressIndicator()),
                            const SizedBox(height: 16),
                            if (_stats != null)
                              HpBar(currentHp: _stats!.totalHp, maxHp: _statsRepo.getMaxHp())
                            else
                              const SizedBox.shrink(),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text(
                              'Category Progress',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // If no categories used show hint
                            if (_usedCategories.isEmpty)
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 56,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No categories yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Create tasks to see category XP bars appear here.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: RefreshIndicator(
                                  onRefresh: _reloadFromHive,
                                  color: Colors.indigo,
                                  backgroundColor: Colors.white,
                                  child: GridView.builder(
                                    padding: const EdgeInsets.only(
                                      top: 8,
                                      bottom: 8,
                                    ),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 2.6,
                                        ),
                                    itemCount: _usedCategories.length,
                                    itemBuilder: (context, index) {
                                      final category = _usedCategories
                                          .elementAt(index);
                                      final stats = _categoryStats[category];
                                      return CategoryXpBar(
                                        category: category,
                                        stats: stats,
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
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
