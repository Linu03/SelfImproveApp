import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/top_navbar.dart';
import '../models/task.dart';
import 'task_detail_page.dart';
import '../services/task_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int? _currentIndex = 0;
  TaskFrequency? _filterFrequency; // null = All
  final TaskRepository _repo = TaskRepository();
  List<Task> _allTasks = [];
  List<Task> _filteredTasks = [];
  bool _loading = true;

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/add-task');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/journal');
        break;
    }
  }

  Color _colorForFrequency(TaskFrequency f) {
    switch (f) {
      case TaskFrequency.daily:
        return Colors.green.shade400;
      case TaskFrequency.weekly:
        return Colors.blue.shade400;
      case TaskFrequency.monthly:
        return Colors.orange.shade400;
      case TaskFrequency.oneTime:
        return Colors.purple.shade400;
    }
  }

  String _labelForFrequency(TaskFrequency f) {
    switch (f) {
      case TaskFrequency.daily:
        return 'Daily';
      case TaskFrequency.weekly:
        return 'Weekly';
      case TaskFrequency.monthly:
        return 'Monthly';
      case TaskFrequency.oneTime:
        return 'Special';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _loading = true;
    });
    final tasks = await _repo.getAllTasks();
    setState(() {
      _allTasks = tasks;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    if (_filterFrequency == null) {
      _filteredTasks = List.from(_allTasks);
    } else {
      _filteredTasks = _allTasks
          .where((t) => t.frequency == _filterFrequency)
          .toList();
    }
  }

  void _onSelectFilter(TaskFrequency? freq) {
    setState(() {
      _filterFrequency = freq;
      _applyFilter();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1625), // Dark fantasy background
      appBar: TopNavbar(
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
      ),
      body: Column(
        children: [
          // Quest Board Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2d1b3d),
                  const Color(0xFF1a1625),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_stories,
                  color: Colors.amber.shade300,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Quest Board',
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

          // Frequency filter as rune buttons
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0f0a14),
              border: Border(
                bottom: BorderSide(
                  color: Colors.purple.shade900.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: TaskFrequency.values.map((f) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _FrequencyCircle(
                      label: _labelForFrequency(f),
                      color: _colorForFrequency(f),
                      selected: _filterFrequency == f,
                      onTap: () {
                        // toggle: if pressing same, clear filter
                        _onSelectFilter(_filterFrequency == f ? null : f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // List area
          Expanded(
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(
                      color: Colors.amber.shade300,
                      strokeWidth: 3,
                    ),
                  )
                : _filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.purple.shade800.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No quests found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add some tasks to begin your journey!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: Colors.amber.shade300,
                        backgroundColor: const Color(0xFF2d1b3d),
                        onRefresh: _loadTasks,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = _filteredTasks[index];
                            return Dismissible(
                              key: Key(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.red.shade900,
                                      Colors.red.shade700,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.red.shade900.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
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
                                    title: Text(
                                      'Abandon Quest?',
                                      style: TextStyle(
                                        color: Colors.amber.shade200,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    content: Text(
                                      'Are you sure you want to abandon "${task.title}"?',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: Text(
                                          'Abandon',
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              onDismissed: (_) async {
                                await _repo.openBox().then(
                                  (b) => b.delete(task.id),
                                );
                                await _loadTasks();
                              },
                              child: _QuestCard(task: task),
                            );
                          },
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

// RPG-themed Quest Card
class _QuestCard extends StatelessWidget {
  final Task task;

  const _QuestCard({required this.task});

  Color _getDifficultyColor(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return Colors.green.shade400;
      case TaskDifficulty.medium:
        return Colors.orange.shade400;
      case TaskDifficulty.hard:
        return Colors.red.shade400;
    }
  }

  String _getDifficultyLabel(TaskDifficulty difficulty) {
    switch (difficulty) {
      case TaskDifficulty.easy:
        return 'Easy';
      case TaskDifficulty.medium:
        return 'Medium';
      case TaskDifficulty.hard:
        return 'Hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final difficultyColor = _getDifficultyColor(task.difficulty);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailPage(task: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.purple.shade700.withOpacity(0.3),
        highlightColor: Colors.purple.shade800.withOpacity(0.2),
        child: Container(
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
              color: difficultyColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: difficultyColor.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quest Title & Difficulty Badge
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade100,
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
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: difficultyColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: difficultyColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _getDifficultyLabel(task.difficulty),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: difficultyColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Rewards Row
                Row(
                  children: [
                    // XP Reward
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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
                          const SizedBox(width: 4),
                          Text(
                            '+${task.xpReward} XP',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Coins Reward
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
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
                            Icons.monetization_on,
                            size: 16,
                            color: Colors.amber.shade300,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${task.coinsReward}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        task.frequency.toString().split('.').last,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// RPG-themed Rune Filter Button
class _FrequencyCircle extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FrequencyCircle({
    Key? key,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.6),
                    color.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    const Color(0xFF2d1b3d).withOpacity(0.5),
                    const Color(0xFF1f1529).withOpacity(0.5),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade800,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade500,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
