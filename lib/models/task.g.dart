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
      category: fields[7] as TaskCategory,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(8)
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
      ..write(obj.xpReward)
      ..writeByte(7)
      ..write(obj.category);
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

class TaskCategoryAdapter extends TypeAdapter<TaskCategory> {
  @override
  final int typeId = 4;

  @override
  TaskCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskCategory.physical;
      case 1:
        return TaskCategory.mental;
      case 2:
        return TaskCategory.emotional;
      case 3:
        return TaskCategory.home;
      case 4:
        return TaskCategory.social;
      case 5:
        return TaskCategory.financial;
      case 6:
        return TaskCategory.productivity;
      case 7:
        return TaskCategory.selfCare;
      case 8:
        return TaskCategory.learning;
      case 9:
        return TaskCategory.career;
      case 10:
        return TaskCategory.errands;
      case 11:
        return TaskCategory.food;
      case 12:
        return TaskCategory.digital;
      case 13:
        return TaskCategory.creativity;
      case 14:
        return TaskCategory.petCare;
      case 15:
        return TaskCategory.maintenance;
      case 16:
        return TaskCategory.travel;
      case 17:
        return TaskCategory.personalGrowth;
      default:
        return TaskCategory.physical;
    }
  }

  @override
  void write(BinaryWriter writer, TaskCategory obj) {
    switch (obj) {
      case TaskCategory.physical:
        writer.writeByte(0);
        break;
      case TaskCategory.mental:
        writer.writeByte(1);
        break;
      case TaskCategory.emotional:
        writer.writeByte(2);
        break;
      case TaskCategory.home:
        writer.writeByte(3);
        break;
      case TaskCategory.social:
        writer.writeByte(4);
        break;
      case TaskCategory.financial:
        writer.writeByte(5);
        break;
      case TaskCategory.productivity:
        writer.writeByte(6);
        break;
      case TaskCategory.selfCare:
        writer.writeByte(7);
        break;
      case TaskCategory.learning:
        writer.writeByte(8);
        break;
      case TaskCategory.career:
        writer.writeByte(9);
        break;
      case TaskCategory.errands:
        writer.writeByte(10);
        break;
      case TaskCategory.food:
        writer.writeByte(11);
        break;
      case TaskCategory.digital:
        writer.writeByte(12);
        break;
      case TaskCategory.creativity:
        writer.writeByte(13);
        break;
      case TaskCategory.petCare:
        writer.writeByte(14);
        break;
      case TaskCategory.maintenance:
        writer.writeByte(15);
        break;
      case TaskCategory.travel:
        writer.writeByte(16);
        break;
      case TaskCategory.personalGrowth:
        writer.writeByte(17);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
