import 'package:hive/hive.dart';
import '../models/task.dart';

class TaskRepository {
  static const String boxName = 'tasksBox';

  Future<Box<Task>> openBox() async {
    return await Hive.openBox<Task>(boxName);
  }

  Future<void> addTask(Task task) async {
    final box = await openBox();
    await box.put(task.id, task);
  }

  Future<List<Task>> getTasks() async {
    final box = await openBox();
    return box.values.toList();
  }

  // Backwards-compatible alias requested by callers: getAllTasks
  Future<List<Task>> getAllTasks() async => getTasks();

  Future<void> updateTask(Task task) async {
    final box = await openBox();
    await box.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    final box = await openBox();
    await box.delete(id);
  }
}
