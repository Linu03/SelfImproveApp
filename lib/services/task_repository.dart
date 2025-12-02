import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';

class TaskRepository {
  static const String boxName = 'tasksBox';

  /// Get or open the tasks box
  Future<Box<Task>> openBox() async {
    return await Hive.openBox<Task>(boxName);
  }

  /// Add a new task to Hive
  Future<void> addTask(Task task) async {
    final box = await openBox();
    await box.put(task.id, task);
  }

  /// Get all tasks from Hive (async)
  Future<List<Task>> getTasks() async {
    final box = await openBox();
    return box.values.toList();
  }

  /// Backwards-compatible alias for getTasks
  Future<List<Task>> getAllTasks() async => getTasks();

  /// Get all tasks synchronously (box must be open)
  List<Task> getTasksSync() {
    try {
      final box = Hive.box<Task>(boxName);
      return box.values.toList();
    } catch (e) {
      return [];
    }
  }

  /// Update an existing task in Hive
  Future<void> updateTask(Task task) async {
    final box = await openBox();
    await box.put(task.id, task);
  }

  /// Delete a task from Hive
  Future<void> deleteTask(String id) async {
    final box = await openBox();
    await box.delete(id);
  }

  /// Get a listenable stream for reactive updates (for HomeScreen)
  /// This allows widgets to rebuild automatically when tasks change
  Listenable getTasksListenable() {
    try {
      final box = Hive.box<Task>(boxName);
      return box.listenable();
    } catch (e) {
      return ValueNotifier(null);
    }
  }

  /// Get task count
  Future<int> getTaskCount() async {
    final box = await openBox();
    return box.length;
  }

  /// Clear all tasks (dangerous - use with caution)
  Future<void> clearAllTasks() async {
    final box = await openBox();
    await box.clear();
  }
}
