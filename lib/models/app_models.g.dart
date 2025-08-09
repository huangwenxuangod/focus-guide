// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MonitoredAppAdapter extends TypeAdapter<MonitoredApp> {
  @override
  final int typeId = 0;

  @override
  MonitoredApp read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MonitoredApp(
      packageName: fields[0] as String,
      displayName: fields[1] as String,
      isEnabled: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, MonitoredApp obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.packageName)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.isEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonitoredAppAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DailyStatsAdapter extends TypeAdapter<DailyStats> {
  @override
  final int typeId = 1;

  @override
  DailyStats read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStats(
      date: fields[0] as DateTime,
      guidanceCount: fields[1] as int,
      activitiesCompleted: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStats obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.guidanceCount)
      ..writeByte(2)
      ..write(obj.activitiesCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStatsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
