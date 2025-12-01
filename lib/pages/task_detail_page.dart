import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_repository.dart';
import '../services/user_stats_repository.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TaskRepository _repo = TaskRepository();
  final UserStatsRepository _statsRepo = UserStatsRepository();
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _markDone() async {
    await _repo.updateTask(_task);
    await _statsRepo.addXp(_task.xpReward);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Global XP +${_task.xpReward}, Coins +${_task.coinsReward}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _markFailed() async {
    await _statsRepo.subtractHp(5);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('❌ Task incompleted. HP -5'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Șterge task'),
        content: Text('Ești sigur că vrei să ștergi "${_task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _repo.deleteTask(_task.id);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _editTask() async {
    final updated = await showDialog<Task?>(
      context: context,
      builder: (ctx) {
        final formKey = GlobalKey<FormState>();
        final titleController = TextEditingController(text: _task.title);
        final descController = TextEditingController(
          text: _task.description ?? '',
        );
        TaskFrequency freq = _task.frequency;
        TaskDifficulty diff = _task.difficulty;

        return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a title' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskFrequency>(
                    value: freq,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: TaskFrequency.values
                        .map(
                          (f) => DropdownMenuItem(
                            value: f,
                            child: Text(f.toString().split('.').last),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) freq = v;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskDifficulty>(
                    value: diff,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                    items: TaskDifficulty.values
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.toString().split('.').last),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) diff = v;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final t = Task(
                    id: _task.id,
                    title: titleController.text.trim(),
                    description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                    frequency: freq,
                    difficulty: diff,
                    coinsReward: _task.coinsReward,
                    xpReward: _task.xpReward,
                  );
                  Navigator.pop(ctx, t);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated != null) {
      setState(() {
        _task.title = updated.title;
        _task.description = updated.description;
        _task.frequency = updated.frequency;
        _task.difficulty = updated.difficulty;
      });
      await _repo.updateTask(_task);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✏️ Task actualizat'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.blue.shade700,
        ),
      );
    }
  }

  Color _getFrequencyColor(TaskFrequency freq) {
    switch (freq) {
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

  Color _getDifficultyColor(TaskDifficulty diff) {
    switch (diff) {
      case TaskDifficulty.easy:
        return Colors.lightGreen.shade400;
      case TaskDifficulty.medium:
        return Colors.amber.shade400;
      case TaskDifficulty.hard:
        return Colors.red.shade400;
    }
  }

  String _getFrequencyLabel(TaskFrequency freq) {
    switch (freq) {
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

  String _getDifficultyLabel(TaskDifficulty diff) {
    switch (diff) {
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
    return Stack(
      children: [
        // Full-screen gradient background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 20, 93, 154),
                Colors.indigo.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // Content
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header with back button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(child: SizedBox()),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      _task.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Card
                    if (_task.description != null &&
                        _task.description!.isNotEmpty)
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _task.description!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Frequency & Difficulty Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Frequency Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getFrequencyColor(_task.frequency),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getFrequencyLabel(_task.frequency),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Difficulty Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(_task.difficulty),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.whatshot,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getDifficultyLabel(_task.difficulty),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Rewards Card
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade400,
                              Colors.amber.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  '💰 Coins',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_task.coinsReward}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: Colors.white30,
                            ),
                            Column(
                              children: [
                                const Text(
                                  '⭐ XP',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${_task.xpReward}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Column(
                      children: [
                        // Complete Button (Primary)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _markDone,
                            icon: const Icon(Icons.check_circle, size: 24),
                            label: const Text(
                              'Complete Task (+XP)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade500,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Failed Button (Secondary)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _markFailed,
                            icon: const Icon(Icons.cancel, size: 24),
                            label: const Text(
                              'Mark Incomplete (-5 HP)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade500,
                              foregroundColor: Colors.white,
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Edit & Delete Buttons (Row)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _editTask,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade400,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _deleteTask,
                                icon: const Icon(Icons.delete, size: 18),
                                label: const Text(
                                  'Delete',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade500,
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
