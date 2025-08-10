import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../utils/performance_monitor.dart';

/// 极简本地存储服务 - 统一管理所有数据存储
class StorageService with PerformanceTrackingMixin {
  static const String _appsBoxName = 'monitored_apps';
  static const String _statsBoxName = 'daily_stats';
  
  // SharedPreferences 键名
  static const String _monitoringEnabledKey = 'monitoring_enabled';
  static const String _permissionsKey = 'permissions';

  late Box<MonitoredApp> _appsBox;
  late Box<DailyStats> _statsBox;
  late SharedPreferences _prefs;

  /// 初始化存储服务
  static Future<StorageService> init() async {
    final service = StorageService._();
    await service._initialize();
    return service;
  }

  StorageService._();

  Future<void> _initialize() async {
    try {
    
      await Hive.initFlutter();

      // 注册适配器
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MonitoredAppAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(DailyStatsAdapter());
      }

      // 并行初始化
      final results = await Future.wait([
        SharedPreferences.getInstance(),
        Hive.openBox<MonitoredApp>(_appsBoxName),
        Hive.openBox<DailyStats>(_statsBoxName),
      ]);
      
      _prefs = results[0] as SharedPreferences;
      _appsBox = results[1] as Box<MonitoredApp>;
      _statsBox = results[2] as Box<DailyStats>;
      
      // 初始化默认数据
      await _initializeDefaultData();
      
      print('✅ StorageService 初始化成功');
    } catch (error) {
      print('❌ StorageService 初始化失败: $error');
      // 使用内存模式作为降级方案
      await _initializeFallbackMode();
    }
  }

  /// 降级方案：纯内存存储
  Future<void> _initializeFallbackMode() async {
    print('🔄 启用纯内存存储模式');
    
    try {
      // 初始化SharedPreferences
      _prefs = await SharedPreferences.getInstance();
      
      // 使用内存中的临时Box
      _appsBox = await Hive.openBox<MonitoredApp>('temp_apps');
      _statsBox = await Hive.openBox<DailyStats>('temp_stats');
      
      await _initializeDefaultData();
      print('✅ 内存存储模式启动成功');
    } catch (error) {
      print('❌ 连内存模式都失败了: $error');
      // 最后的降级方案 - 创建假的存储对象
      rethrow;
    }
  }

  /// 初始化默认监控应用数据
  Future<void> _initializeDefaultData() async {
    if (_appsBox.isEmpty) {
      final defaultApps = [
        const MonitoredApp(packageName: 'com.tencent.mm', displayName: '微信', isEnabled: true),
        const MonitoredApp(packageName: 'com.ss.android.ugc.aweme', displayName: '抖音', isEnabled: true),
        const MonitoredApp(packageName: 'com.taobao.taobao', displayName: '淘宝', isEnabled: true),
        const MonitoredApp(packageName: 'com.sina.weibo', displayName: '微博', isEnabled: false),
        const MonitoredApp(packageName: 'com.tencent.tmgp.sgame', displayName: '王者荣耀', isEnabled: true),
      ];
      
      for (final app in defaultApps) {
        await _appsBox.put(app.packageName, app);
      }
    }
  }

  // =================== 监控应用管理 ===================
  
  /// 获取所有监控应用
  List<MonitoredApp> getMonitoredApps() {
    // 同步操作，直接返回结果
    return _appsBox.values.toList();
  }

  /// 更新应用监控状态
  Future<void> updateAppStatus(String packageName, bool isEnabled) async {
    final app = _appsBox.get(packageName);
    if (app != null) {
      await _appsBox.put(packageName, app.copyWith(isEnabled: isEnabled));
    }
  }

  // =================== 监控总开关 ===================
  
  /// 获取监控总开关状态
  bool getMonitoringEnabled() {
    return _prefs.getBool(_monitoringEnabledKey) ?? false;
  }

  /// 设置监控总开关状态
  Future<void> setMonitoringEnabled(bool enabled) async {
    await _prefs.setBool(_monitoringEnabledKey, enabled);
  }

  // =================== 权限状态管理 ===================
  
  /// 获取权限状态
  Map<String, bool> getPermissions() {
    final permissionsJson = _prefs.getString(_permissionsKey);
    if (permissionsJson == null) {
      return {
        'usage_stats': false,
        'system_alert': false,
        'foreground_service': false,
      };
    }
    
    // 简单的JSON解析
    final permissions = <String, bool>{};
    permissionsJson.split(',').forEach((item) {
      final parts = item.split(':');
      if (parts.length == 2) {
        permissions[parts[0]] = parts[1] == 'true';
      }
    });
    
    return permissions;
  }

  /// 更新权限状态
  Future<void> updatePermission(String type, bool isGranted) async {
    final permissions = getPermissions();
    permissions[type] = isGranted;
    
    // 简单的JSON序列化
    final permissionsJson = permissions.entries
        .map((e) => '${e.key}:${e.value}')
        .join(',');
    
    await _prefs.setString(_permissionsKey, permissionsJson);
  }

  // =================== 统计数据管理 ===================
  
  /// 获取今日统计
  DailyStats getTodayStats() {
    final today = DailyStats.getTodayKey();
    return _statsBox.get(today) ?? DailyStats(
      date: DateTime.now(),
      guidanceCount: 0,
      activitiesCompleted: 0,
    );
  }

  /// 增加引导次数
  Future<void> incrementGuidanceCount() async {
    final today = getTodayStats();
    final updated = today.copyWith(guidanceCount: today.guidanceCount + 1);
    await _statsBox.put(DailyStats.getTodayKey(), updated);
  }

  /// 增加完成活动次数
  Future<void> incrementActivitiesCompleted() async {
    final today = getTodayStats();
    final updated = today.copyWith(activitiesCompleted: today.activitiesCompleted + 1);
    await _statsBox.put(DailyStats.getTodayKey(), updated);
  }

  // =================== 清理方法 ===================
  
  /// 清理旧的统计数据 (保留最近7天)
  Future<void> cleanOldStats() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
    final keysToDelete = <String>[];
    
    for (final key in _statsBox.keys) {
      if (key is String) {
        final parts = key.split('-');
        if (parts.length == 3) {
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          if (date.isBefore(cutoffDate)) {
            keysToDelete.add(key);
          }
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _statsBox.delete(key);
    }
  }

  /// 关闭存储服务
  Future<void> close() async {
    await _appsBox.close();
    await _statsBox.close();
  }
}