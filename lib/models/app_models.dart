import 'package:hive/hive.dart';

part 'app_models.g.dart';

/// 监控应用数据模型 - 极简版本
@HiveType(typeId: 0)
class MonitoredApp {
  @HiveField(0)
  final String packageName;
  
  @HiveField(1)
  final String displayName;
  
  @HiveField(2)
  final bool isEnabled;

  const MonitoredApp({
    required this.packageName,
    required this.displayName,
    required this.isEnabled,
  });

  MonitoredApp copyWith({bool? isEnabled}) {
    return MonitoredApp(
      packageName: packageName,
      displayName: displayName,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'displayName': displayName,
    'isEnabled': isEnabled,
  };

  factory MonitoredApp.fromJson(Map<String, dynamic> json) => MonitoredApp(
    packageName: json['packageName'],
    displayName: json['displayName'],
    isEnabled: json['isEnabled'],
  );

  @override
  bool operator ==(Object other) =>
    identical(this, other) ||
    other is MonitoredApp && packageName == other.packageName;

  @override
  int get hashCode => packageName.hashCode;
}

/// 每日统计数据模型 - 极简版本
@HiveType(typeId: 1)
class DailyStats {
  @HiveField(0)
  final DateTime date;
  
  @HiveField(1)
  final int guidanceCount;
  
  @HiveField(2)
  final int activitiesCompleted;

  const DailyStats({
    required this.date,
    required this.guidanceCount,
    required this.activitiesCompleted,
  });

  DailyStats copyWith({
    int? guidanceCount,
    int? activitiesCompleted,
  }) {
    return DailyStats(
      date: date,
      guidanceCount: guidanceCount ?? this.guidanceCount,
      activitiesCompleted: activitiesCompleted ?? this.activitiesCompleted,
    );
  }

  /// 获取今天的日期键 (yyyy-MM-dd)
  static String getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String get dateKey => getTodayKey();
}