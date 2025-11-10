class JournalEntry {
  String id;
  DateTime date;
  List<TaskLog> taskLogs; // what tasks were completed that day

  JournalEntry({
    required this.id,
    required this.date,
    this.taskLogs = const [],
  });
}

class TaskLog {
  String taskId;
  bool completed; // true = +XP, false = -XP

  TaskLog({
    required this.taskId,
    required this.completed,
  });
}
