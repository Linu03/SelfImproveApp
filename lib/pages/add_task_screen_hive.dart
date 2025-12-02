import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/top_navbar.dart';
import '../models/task.dart';
import '../services/task_repository.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  int? _currentIndex = 1; // already on Add Task

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/journal');
        break;
    }
  }

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskFrequency _frequency = TaskFrequency.daily;
  TaskDifficulty _difficulty = TaskDifficulty.easy;
  TaskCategory _category = TaskCategory.physical;
  int _coins = 5;
  int _xp = 10;
  bool _saving = false;

  void _updateRewards(TaskDifficulty difficulty) {
    final rewards = Task.getRewards(difficulty);
    setState(() {
      _coins = rewards['coins']!;
      _xp = rewards['xp']!;
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      frequency: _frequency,
      difficulty: _difficulty,
      coinsReward: _coins,
      xpReward: _xp,
      category: _category,
    );
    await TaskRepository().addTask(task);
    setState(() => _saving = false);
    // After saving, navigate to HomeScreen
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavbar(
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
        title: 'Add Task',
        userSelected: false,
        shopSelected: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a title'
                    : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<TaskFrequency>(
                value: _frequency,
                decoration: InputDecoration(labelText: 'Frequency'),
                items: TaskFrequency.values
                    .map(
                      (f) => DropdownMenuItem(
                        value: f,
                        child: Text(f.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _frequency = val);
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<TaskDifficulty>(
                value: _difficulty,
                decoration: InputDecoration(labelText: 'Difficulty'),
                items: TaskDifficulty.values
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d.toString().split('.').last),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _difficulty = val);
                    _updateRewards(val);
                  }
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<TaskCategory>(
                value: _category,
                decoration: InputDecoration(labelText: 'Category'),
                items: TaskCategory.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(Task.getCategoryLabel(c)),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Coins: $_coins', style: TextStyle(fontSize: 16)),
                ],
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saving ? null : _saveTask,
                child: _saving ? CircularProgressIndicator() : Text('Save'),
              ),
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
}
