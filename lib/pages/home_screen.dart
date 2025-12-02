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
      appBar: TopNavbar(
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
      ),
      body: Column(
        children: [
          // Frequency filter as circle buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: TaskFrequency.values.map((f) {
                return _FrequencyCircle(
                  label: _labelForFrequency(f),
                  color: _colorForFrequency(f),
                  selected: _filterFrequency == f,
                  onTap: () {
                    // toggle: if pressing same, clear filter
                    _onSelectFilter(_filterFrequency == f ? null : f);
                  },
                );
              }).toList(),
            ),
          ),

          // List area
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTasks.isEmpty
                ? const Center(
                    child: Text('No tasks found. Add some tasks!'),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredTasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return Dismissible(
                          key: Key(task.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Task'),
                                content: Text(
                                  'Are you sure you want to delete "${task.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
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
                          child: Card(
                            child: ListTile(
                              title: Text(task.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (task.description != null &&
                                      task.description!.isNotEmpty)
                                    Text(task.description!),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          task.frequency
                                              .toString()
                                              .split('.')
                                              .last,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          task.difficulty
                                              .toString()
                                              .split('.')
                                              .last,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Text('${task.coinsReward} 💰')],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskDetailPage(task: task),
                                  ),
                                );
                              },
                            ),
                          ),
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
    final border = selected ? Border.all(color: Colors.black, width: 2) : null;
    final bg = selected ? color : color.withOpacity(0.25);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
