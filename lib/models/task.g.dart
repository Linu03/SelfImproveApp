// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      frequency: fields[3] as TaskFrequency,
      difficulty: fields[4] as TaskDifficulty,
      coinsReward: fields[5] as int,
      xpReward: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.difficulty)
      ..writeByte(5)
      ..write(obj.coinsReward)
      ..writeByte(6)
      ..write(obj.xpReward);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskFrequencyAdapter extends TypeAdapter<TaskFrequency> {
  @override
  final int typeId = 0;

  @override
  TaskFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskFrequency.daily;
      case 1:
        return TaskFrequency.weekly;
      case 2:
        return TaskFrequency.monthly;
      case 3:
        return TaskFrequency.oneTime;
      default:
        return TaskFrequency.daily;
    }
  }

  @override
  void write(BinaryWriter writer, TaskFrequency obj) {
    switch (obj) {
      case TaskFrequency.daily:
        writer.writeByte(0);
        break;
      case TaskFrequency.weekly:
        writer.writeByte(1);
        break;
      case TaskFrequency.monthly:
        writer.writeByte(2);
        break;
      case TaskFrequency.oneTime:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskDifficultyAdapter extends TypeAdapter<TaskDifficulty> {
  @override
  final int typeId = 1;

  @override
  TaskDifficulty read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskDifficulty.easy;
      case 1:
        return TaskDifficulty.medium;
      case 2:
        return TaskDifficulty.hard;
      default:
        return TaskDifficulty.easy;
    }
  }

  @override
  void write(BinaryWriter writer, TaskDifficulty obj) {
    switch (obj) {
      case TaskDifficulty.easy:
        writer.writeByte(0);
        break;
      case TaskDifficulty.medium:
        writer.writeByte(1);
        break;
      case TaskDifficulty.hard:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskDifficultyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
