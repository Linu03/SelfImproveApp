part of 'reward_item.dart';

// ***************************************************************************
// Manual TypeAdapter for RewardItem
// ***************************************************************************

class RewardItemAdapter extends TypeAdapter<RewardItem> {
  @override
  final int typeId = 7;

  @override
  RewardItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RewardItem(
      name: fields[0] as String,
      price: fields[1] as int,
      durationMinutes: fields[2] as int?,
      category: fields[3] as String,
      isActive: fields[4] as bool? ?? false,
      startTime: fields[5] as DateTime?,
      remainingMinutes: fields[6] as int? ?? (fields[2] as int? ?? 0),
    );
  }

  @override
  void write(BinaryWriter writer, RewardItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.durationMinutes)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.startTime)
      ..writeByte(6)
      ..write(obj.remainingMinutes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
