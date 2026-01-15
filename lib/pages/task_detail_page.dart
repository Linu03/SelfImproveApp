import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_repository.dart';
import '../services/user_stats_repository.dart';
import '../services/user_profile_repository.dart';
import '../services/journal_service.dart';

class TaskDetailPage extends StatefulWidget {
  final Task task;

  const TaskDetailPage({Key? key, required this.task}) : super(key: key);

  @override
  _TaskDetailPageState createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final TaskRepository _repo = TaskRepository();
  final UserStatsRepository _statsRepo = UserStatsRepository();
  final UserProfileRepository _profileRepo = UserProfileRepository();
  late Task _task;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
  }

  Future<void> _markDone() async {
    await _repo.updateTask(_task);
    await _statsRepo.addXp(_task.xpReward, category: _task.category);
    // Award coins to the user
    try {
      await _profileRepo.addCoins(_task.coinsReward);
    } catch (e) {
      // ignore errors but continue
    }

    // Persist snapshot to journal
    try {
      await JournalService.addCompletedTask(
        when: DateTime.now(),
        taskName: _task.title,
        category: Task.getCategoryLabel(_task.category),
        xpEarned: _task.xpReward,
        coinsEarned: _task.coinsReward,
      );
    } catch (e) {
      // ignore journal errors
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ Global XP +${_task.xpReward} • +${_task.coinsReward} coins • ${Task.getCategoryLabel(_task.category)} +${_task.xpReward}',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _markFailed() async {
    await _statsRepo.subtractHp(5);

    // Record the failed task in the journal (record negative XP)
    try {
      await JournalService.addCompletedTask(
        when: DateTime.now(),
        taskName: _task.title,
        category: Task.getCategoryLabel(_task.category),
        xpEarned: -_task.xpReward,
        coinsEarned: 0,
        completed: false,
      );
    } catch (e) {
      // ignore
    }

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
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    frequency: freq,
                    difficulty: diff,
                    coinsReward: _task.coinsReward,
                    xpReward: _task.xpReward,
                    category: _task.category,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1a1625),
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1a1625),
                    const Color(0xFF2d1b3d),
                    const Color(0xFF1a1625),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Decorative orbs
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.purple.shade600.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              left: 10,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.indigo.shade600.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.purple.shade800.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.purple.shade600.withOpacity(0.5),
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.amber.shade300,
                              size: 24,
                            ),
                            onPressed: () => Navigator.pop(context),
                            constraints: const BoxConstraints(minHeight: 40),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Title with RPG styling
                    Text(
                      _task.title,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.amber.shade200,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.amber.shade900.withOpacity(0.6),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade700,
                            Colors.indigo.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade900.withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Text(
                        Task.getCategoryLabel(_task.category),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade200,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Card
                    if (_task.description != null &&
                        _task.description!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.purple.shade700.withOpacity(0.4),
                            width: 1.5,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade900.withOpacity(0.2),
                              Colors.indigo.shade900.withOpacity(0.1),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.shade900.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quest Details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.amber.shade400,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _task.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade300,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Frequency & Difficulty Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _getFrequencyColor(
                                  _task.frequency,
                                ).withOpacity(0.6),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  _getFrequencyColor(
                                    _task.frequency,
                                  ).withOpacity(0.15),
                                  _getFrequencyColor(
                                    _task.frequency,
                                  ).withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getFrequencyColor(
                                    _task.frequency,
                                  ).withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Frequency',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      color: _getFrequencyColor(
                                        _task.frequency,
                                      ),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getFrequencyLabel(_task.frequency),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _getFrequencyColor(
                                          _task.frequency,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _getDifficultyColor(
                                  _task.difficulty,
                                ).withOpacity(0.6),
                                width: 1.5,
                              ),
                              gradient: LinearGradient(
                                colors: [
                                  _getDifficultyColor(
                                    _task.difficulty,
                                  ).withOpacity(0.15),
                                  _getDifficultyColor(
                                    _task.difficulty,
                                  ).withOpacity(0.05),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _getDifficultyColor(
                                    _task.difficulty,
                                  ).withOpacity(0.2),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Difficulty',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.whatshot,
                                      color: _getDifficultyColor(
                                        _task.difficulty,
                                      ),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getDifficultyLabel(_task.difficulty),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _getDifficultyColor(
                                          _task.difficulty,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Rewards Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade900.withOpacity(0.4),
                            Colors.amber.shade700.withOpacity(0.2),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.amber.shade600.withOpacity(0.5),
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
                      child: Column(
                        children: [
                          Text(
                            'Quest Rewards',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade300,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  Icon(
                                    Icons.monetization_on,
                                    color: Colors.amber.shade300,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_task.coinsReward}',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Coins',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade400,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 1.5,
                                height: 60,
                                color: Colors.amber.shade600.withOpacity(0.3),
                              ),
                              Column(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.amber.shade300,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_task.xpReward}',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.amber.shade200,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'XP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Action Buttons
                    Column(
                      children: [
                        // Complete Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _markDone,
                            icon: const Icon(Icons.check_circle, size: 24),
                            label: const Text(
                              'Complete Quest',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.green.shade900.withOpacity(
                                0.6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Failed Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _markFailed,
                            icon: const Icon(Icons.cancel, size: 24),
                            label: const Text(
                              'Abandon Quest',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.red.shade900.withOpacity(0.6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Edit & Delete Row
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _editTask,
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text(
                                  'Edit',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700
                                      .withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shadowColor: Colors.blue.shade900.withOpacity(
                                    0.5,
                                  ),
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
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade800
                                      .withOpacity(0.8),
                                  foregroundColor: Colors.white,
                                  elevation: 6,
                                  shadowColor: Colors.red.shade900.withOpacity(
                                    0.5,
                                  ),
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
          ],
        ),
      ),
    );
  }
}
