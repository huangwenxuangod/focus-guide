import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/app_models.dart';
import '../providers/stats_provider.dart';
import '../utils/performance_monitor.dart';

/// 应用监控服务 - 核心功能实现
class MonitorService with PerformanceTrackingMixin {
  static MonitorService? _instance;
  static MonitorService get instance => _instance ??= MonitorService._();
  
  MonitorService._();
  
  bool _isMonitoring = false;
  Timer? _monitorTimer;
  Set<String> _lastRunningApps = {};
  List<MonitoredApp> _monitoredApps = [];
  StatsProvider? _statsProvider;
  
  /// 监控状态回调
  Function(String packageName, String appName)? onAppLaunched;
  
  /// 预设的监控应用包名映射
  static const Map<String, String> _presetApps = {
    'com.tencent.mm': '微信',
    'com.ss.android.ugc.aweme': '抖音',
    'com.taobao.taobao': '淘宝',
    'com.sina.weibo': '微博',
    'com.tencent.tmgp.sgame': '王者荣耀',
  };
  
  /// 初始化监控服务
  Future<bool> initialize(List<MonitoredApp> apps, [StatsProvider? statsProvider]) async {
    try {
      _monitoredApps = apps;
      _statsProvider = statsProvider;
      
      // 检查权限
      if (!await _checkPermissions()) {
        debugPrint('❌ 监控服务初始化失败：权限不足');
        return false;
      }
      
      debugPrint('✅ 监控服务初始化成功');
      return true;
    } catch (error) {
      debugPrint('❌ 监控服务初始化异常: $error');
      return false;
    }
  }
  
  /// 开始监控
  Future<bool> startMonitoring() async {
    if (_isMonitoring) {
      debugPrint('⚠️ 监控服务已在运行');
      return true;
    }
    
    try {
      // 检查权限
      if (!await _checkPermissions()) {
        debugPrint('❌ 启动监控失败：权限不足');
        return false;
      }
      
      _isMonitoring = true;
      
      // 启动定时检测 (优化为每10秒检查一次，大幅减少CPU使用)
      _monitorTimer = Timer.periodic(
        const Duration(seconds: 10),
        _checkRunningApps,
      );
      
      debugPrint('🚀 应用监控服务已启动');
      return true;
    } catch (error) {
      debugPrint('❌ 启动监控服务异常: $error');
      _isMonitoring = false;
      return false;
    }
  }
  
  /// 停止监控
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _lastRunningApps.clear();
    
    debugPrint('⏹️ 应用监控服务已停止');
  }
  
  /// 检查运行中的应用
  Future<void> _checkRunningApps(Timer timer) async {
    if (!_isMonitoring) return;
    
    try {
      // 获取当前运行的应用
      final runningApps = await _getCurrentRunningApps();
      
      // 优化：只检查新启动的应用，避免重复处理
      final newApps = runningApps.difference(_lastRunningApps);
      
      // 检查新启动的监控应用
      for (final packageName in newApps) {
        if (_isMonitoredApp(packageName)) {
          await _handleAppLaunched(packageName);
        }
      }
      
      _lastRunningApps = runningApps;
    } catch (error) {
      debugPrint('检查运行应用时出错: $error');
      // 发生错误时暂停一段时间，避免连续错误
      await Future.delayed(const Duration(seconds: 5));
    }
  }
  
  /// 获取当前运行的应用包名
  Future<Set<String>> _getCurrentRunningApps() async {
    try {
      if (Platform.isAndroid) {
        // Android: 使用 installed_apps 获取已安装应用
        // 注意：由于权限限制，这里使用模拟检测
        // 实际项目中需要使用 UsageStatsManager 或其他方法
        return await _simulateRunningAppsDetection();
      } else {
        // iOS 不支持应用监控
        return {};
      }
    } catch (error) {
      debugPrint('获取运行应用失败: $error');
      return {};
    }
  }
  
  /// 模拟应用检测 (开发阶段使用)
  Future<Set<String>> _simulateRunningAppsDetection() async {
    // 大幅优化模拟检测逻辑，减少不必要的计算
    final enabledApps = _monitoredApps.where((app) => app.isEnabled).toList();
    if (enabledApps.isEmpty) return {};
    
    // 大幅降低检测频率，减少CPU使用 (每60秒才可能触发一次)
    final now = DateTime.now();
    if (now.second % 60 == 0 && now.millisecond < 100) {
      final randomApp = enabledApps[now.minute % enabledApps.length];
      return {randomApp.packageName};
    }
    return {};
  }
  
  /// 检查应用是否在监控列表中
  bool _isMonitoredApp(String packageName) {
    return _monitoredApps.any(
      (app) => app.packageName == packageName && app.isEnabled,
    );
  }
  
  /// 处理应用启动事件
  Future<void> _handleAppLaunched(String packageName) async {
    try {
      final appName = _getAppDisplayName(packageName);
      
      debugPrint('🎯 检测到监控应用启动: $appName ($packageName)');
      
      // 增加引导次数统计
      if (_statsProvider != null) {
        await _statsProvider!.incrementGuidanceCount();
      }
      
      // 触发引导页面显示
      onAppLaunched?.call(packageName, appName);
      
    } catch (error) {
      debugPrint('处理应用启动事件失败: $error');
    }
  }
  
  /// 获取应用显示名称
  String _getAppDisplayName(String packageName) {
    // 优先从监控列表获取
    final monitoredApp = _monitoredApps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => MonitoredApp(
        packageName: packageName,
        displayName: _presetApps[packageName] ?? '未知应用',
        isEnabled: false,
      ),
    );
    
    return monitoredApp.displayName;
  }
  
  /// 检查必要权限
  Future<bool> _checkPermissions() async {
    try {
      if (Platform.isAndroid) {
        // 检查应用使用统计权限
        // 注意：permission_handler 可能不支持 PACKAGE_USAGE_STATS
        // 实际项目中需要使用原生代码检查
        return true; // 暂时返回 true 用于开发
      }
      return false;
    } catch (error) {
      debugPrint('检查权限失败: $error');
      return false;
    }
  }
  
  /// 获取监控状态
  bool get isMonitoring => _isMonitoring;
  
  /// 获取监控的应用数量
  int get monitoredAppsCount => _monitoredApps.where((app) => app.isEnabled).length;
  
  /// 更新监控应用列表
  void updateMonitoredApps(List<MonitoredApp> apps) {
    _monitoredApps = apps;
    debugPrint('📱 更新监控应用列表: ${apps.where((app) => app.isEnabled).length} 个应用');
  }
  
  /// 手动触发应用启动事件（用于测试）
  void triggerAppLaunch(String packageName) {
    final appName = _getAppDisplayName(packageName);
    debugPrint('🧪 手动触发应用启动: $appName ($packageName)');
    _handleAppLaunched(packageName);
  }
  
  /// 释放资源
  void dispose() {
    stopMonitoring();
    _instance = null;
  }
}