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

    // add to global XP and handle leveling
    await _statsRepo.addXp(_task.xpReward);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Global XP +${_task.xpReward}, Coins +${_task.coinsReward}',
        ),
      ),
    );
  }

  Future<void> _markFailed() async {
    // Subtract HP when task is not completed
    await _statsRepo.subtractHp(5);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task incompleted. HP -5')));
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
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _editTask() async {
    final updated = await showDialog<Task?>(
      context: context,
      builder: (ctx) {
        final _formKey = GlobalKey<FormState>();
        final _titleController = TextEditingController(text: _task.title);
        final _descController = TextEditingController(
          text: _task.description ?? '',
        );
        TaskFrequency _freq = _task.frequency;
        TaskDifficulty _diff = _task.difficulty;

        return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter a title' : null,
                  ),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TaskFrequency>(
                    value: _freq,
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
                      if (v != null) _freq = v;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TaskDifficulty>(
                    value: _diff,
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
                      if (v != null) _diff = v;
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
                if (_formKey.currentState?.validate() ?? false) {
                  final t = Task(
                    id: _task.id,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim().isEmpty
                        ? null
                        : _descController.text.trim(),
                    frequency: _freq,
                    difficulty: _diff,
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
      // update fields and persist
      setState(() {
        _task.title = updated.title;
        _task.description = updated.description;
        _task.frequency = updated.frequency;
        _task.difficulty = updated.difficulty;
      });
      await _repo.updateTask(_task);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task actualizat')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _task.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_task.description != null) Text(_task.description!),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    'Freq: ${_task.frequency.toString().split('.').last}',
                  ),
                ),
                Chip(
                  label: Text(
                    'Diff: ${_task.difficulty.toString().split('.').last}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text('Coins: ${_task.coinsReward}')],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _markFailed,
                  icon: const Icon(Icons.remove),
                  label: const Text('-'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _markDone,
                  icon: const Icon(Icons.add),
                  label: const Text('+'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _editTask,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _deleteTask,
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
