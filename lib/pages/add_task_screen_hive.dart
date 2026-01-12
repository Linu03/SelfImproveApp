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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1625), // Dark fantasy background
      appBar: TopNavbar(
        onUserTap: () => Navigator.pushNamed(context, '/profile'),
        onShopTap: () => Navigator.pushNamed(context, '/shop'),
        title: 'Add Quest',
        userSelected: false,
        shopSelected: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quest Creation Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                      color: Colors.amber.shade700.withOpacity(0.3),
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: Colors.amber.shade300,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Create New Quest',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade200,
                            letterSpacing: 1.0,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Quest Scroll Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2d1b3d),
                        const Color(0xFF1f1529),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.purple.shade700.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quest Name
                      _buildLabel('Quest Name', Icons.edit_note),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          color: Colors.amber.shade100,
                          fontSize: 16,
                        ),
                        decoration: _buildInputDecoration(
                          'Enter quest name...',
                          Colors.amber.shade700,
                        ),
                        validator: (value) => value == null || value.trim().isEmpty
                            ? 'Enter a quest name'
                            : null,
                      ),

                      const SizedBox(height: 20),

                      // Quest Description
                      _buildLabel('Quest Description', Icons.description),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          'Describe your quest... (optional)',
                          Colors.purple.shade700,
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      // Frequency
                      _buildLabel('Quest Type', Icons.calendar_today),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TaskFrequency>(
                        value: _frequency,
                        dropdownColor: const Color(0xFF2d1b3d),
                        style: TextStyle(
                          color: Colors.blue.shade300,
                          fontSize: 16,
                        ),
                        decoration: _buildInputDecoration(
                          'Select frequency',
                          Colors.blue.shade700,
                        ),
                        items: TaskFrequency.values
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.toString().split('.').last,
                                  style: TextStyle(color: Colors.blue.shade300),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _frequency = val);
                        },
                      ),

                      const SizedBox(height: 20),

                      // Difficulty
                      _buildLabel('Difficulty Level', Icons.trending_up),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TaskDifficulty>(
                        value: _difficulty,
                        dropdownColor: const Color(0xFF2d1b3d),
                        style: TextStyle(
                          color: _getDifficultyColor(_difficulty),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: _buildInputDecoration(
                          'Select difficulty',
                          _getDifficultyColor(_difficulty),
                        ),
                        items: TaskDifficulty.values
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  d.toString().split('.').last,
                                  style: TextStyle(
                                    color: _getDifficultyColor(d),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

                      const SizedBox(height: 20),

                      // Category
                      _buildLabel('Quest Category', Icons.category),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TaskCategory>(
                        value: _category,
                        dropdownColor: const Color(0xFF2d1b3d),
                        style: TextStyle(
                          color: Colors.cyan.shade300,
                          fontSize: 15,
                        ),
                        decoration: _buildInputDecoration(
                          'Select category',
                          Colors.cyan.shade700,
                        ),
                        items: TaskCategory.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(
                                  Task.getCategoryLabel(c),
                                  style: TextStyle(color: Colors.cyan.shade300),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _category = val);
                        },
                      ),

                      const SizedBox(height: 28),

                      // Rewards Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.3),
                              Colors.black.withOpacity(0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.shade900.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.card_giftcard,
                                  color: Colors.amber.shade400,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Quest Rewards',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade300,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // XP Reward
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.shade700.withOpacity(0.3),
                                          Colors.purple.shade900.withOpacity(0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.purple.shade400.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.purple.shade300,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '+$_xp XP',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.purple.shade200,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Experience',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.purple.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Coins Reward
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.amber.shade700.withOpacity(0.3),
                                          Colors.amber.shade900.withOpacity(0.3),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.amber.shade400.withOpacity(0.4),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.monetization_on,
                                          color: Colors.amber.shade300,
                                          size: 28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '+$_coins',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber.shade200,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Gold Coins',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.amber.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Create Quest Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _saving
                          ? [Colors.grey.shade700, Colors.grey.shade800]
                          : [
                              Colors.amber.shade600,
                              Colors.amber.shade800,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _saving
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.amber.shade900.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _saving ? null : _saveTask,
                      borderRadius: BorderRadius.circular(16),
                      splashColor: Colors.white.withOpacity(0.2),
                      highlightColor: Colors.white.withOpacity(0.1),
                      child: Center(
                        child: _saving
                            ? CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_task,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'CREATE QUEST',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.2,
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
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildLabel(String text, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.amber.shade400,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.amber.shade300,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, Color accentColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade600,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: accentColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Colors.red.shade400,
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
