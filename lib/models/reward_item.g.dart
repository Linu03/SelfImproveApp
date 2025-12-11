
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
    );
  }

  @override
  void write(BinaryWriter writer, RewardItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.durationMinutes)
      ..writeByte(3)
      ..write(obj.category);
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
