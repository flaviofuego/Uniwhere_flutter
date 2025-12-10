// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_location.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoomLocationAdapter extends TypeAdapter<RoomLocation> {
  @override
  final int typeId = 0;

  @override
  RoomLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoomLocation(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      posX: fields[3] as double,
      posY: fields[4] as double,
      posZ: fields[5] as double,
      category: fields[6] as String,
      iconPath: fields[7] as String,
      tags: (fields[8] as List).cast<String>(),
      imageReference: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, RoomLocation obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.posX)
      ..writeByte(4)
      ..write(obj.posY)
      ..writeByte(5)
      ..write(obj.posZ)
      ..writeByte(6)
      ..write(obj.category)
      ..writeByte(7)
      ..write(obj.iconPath)
      ..writeByte(8)
      ..write(obj.tags)
      ..writeByte(9)
      ..write(obj.imageReference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
