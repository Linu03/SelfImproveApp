part of 'category_xp.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryXpAdapter extends TypeAdapter<CategoryXp> {
  @override
  final int typeId = 5;

  @override
  CategoryXp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryXp(
      categoryName: fields[0] as String,
      totalXp: fields[1] as int,
      level: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryXp obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.categoryName)
      ..writeByte(1)
      ..write(obj.totalXp)
      ..writeByte(2)
      ..write(obj.level);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryXpAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
