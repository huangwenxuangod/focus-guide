import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import 'package:flutter/services.dart';

/// 权限管理服务 - 统一处理所有权限申请
class PermissionService {
  static PermissionService? _instance;
  static PermissionService get instance => _instance ??= PermissionService._();
  
  PermissionService._();
  
  /// 权限类型定义
  static const String usageStats = 'usage_stats';
  static const String systemAlert = 'system_alert';
  static const String foregroundService = 'foreground_service';
  
  /// 权限状态回调
  Function(String permissionType, bool isGranted)? onPermissionChanged;
  
  // 权限检查缓存，避免频繁检查
  Map<String, bool>? _cachedPermissions;
  DateTime? _lastPermissionCheck;
  static const Duration _cacheValidDuration = Duration(minutes: 5);
  
  /// 检查所有必要权限
  Future<Map<String, bool>> checkAllPermissions() async {
    // 使用缓存减少频繁的权限检查
    if (_cachedPermissions != null && 
        _lastPermissionCheck != null &&
        DateTime.now().difference(_lastPermissionCheck!) < _cacheValidDuration) {
      return _cachedPermissions!;
    }
    
    final results = <String, bool>{};
    
    try {
      // 检查应用使用统计权限
      results[usageStats] = await _checkUsageStatsPermission();
      
      // 检查系统覆盖层权限
      results[systemAlert] = await _checkSystemAlertPermission();
      
      // 检查前台服务权限
      results[foregroundService] = await _checkForegroundServicePermission();
      
      // 缓存结果
      _cachedPermissions = results;
      _lastPermissionCheck = DateTime.now();
      
      debugPrint('📋 权限检查结果: $results');
      return results;
    } catch (error) {
      debugPrint('❌ 检查权限失败: $error');
      final fallbackResults = {
        usageStats: false,
        systemAlert: false,
        foregroundService: false,
      };
      
      // 即使失败也缓存结果，避免连续失败
      _cachedPermissions = fallbackResults;
      _lastPermissionCheck = DateTime.now();
      
      return fallbackResults;
    }
  }
  
  /// 请求应用使用统计权限
  Future<bool> requestUsageStatsPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android: 需要跳转到系统设置页面
        final isGranted = await _requestUsageStatsPermissionAndroid();
        onPermissionChanged?.call(usageStats, isGranted);
        return isGranted;
      } else {
        // iOS 不支持此权限
        debugPrint('⚠️ iOS 不支持应用使用统计权限');
        return false;
      }
    } catch (error) {
      debugPrint('❌ 请求使用统计权限失败: $error');
      return false;
    }
  }
  
  /// 请求系统覆盖层权限
  Future<bool> requestSystemAlertPermission() async {
    try {
      if (Platform.isAndroid) {
        final status = await permission_handler.Permission.systemAlertWindow.request();
        final isGranted = status == permission_handler.PermissionStatus.granted;
        onPermissionChanged?.call(systemAlert, isGranted);
        return isGranted;
      } else {
        // iOS 不需要此权限
        debugPrint('ℹ️ iOS 不需要系统覆盖层权限');
        return true;
      }
    } catch (error) {
      debugPrint('❌ 请求系统覆盖层权限失败: $error');
      return false;
    }
  }
  
  /// 请求前台服务权限
  Future<bool> requestForegroundServicePermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 10+ 需要前台服务权限
        final status = await permission_handler.Permission.ignoreBatteryOptimizations.request();
        final isGranted = status == permission_handler.PermissionStatus.granted;
        onPermissionChanged?.call(foregroundService, isGranted);
        return isGranted;
      } else {
        // iOS 使用后台应用刷新
        debugPrint('ℹ️ iOS 使用后台应用刷新权限');
        return true;
      }
    } catch (error) {
      debugPrint('❌ 请求前台服务权限失败: $error');
      return false;
    }
  }
  
  /// 一键申请所有权限
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = <String, bool>{};
    
    try {
      debugPrint('🔐 开始申请所有权限...');
      
      // 按顺序申请权限，提供更好的用户体验
      results[usageStats] = await requestUsageStatsPermission();
      
      // 短暂延迟，避免权限弹窗重叠
      await Future.delayed(const Duration(milliseconds: 500));
      
      results[systemAlert] = await requestSystemAlertPermission();
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      results[foregroundService] = await requestForegroundServicePermission();
      
      final grantedCount = results.values.where((granted) => granted).length;
      debugPrint('✅ 权限申请完成: $grantedCount/${results.length} 个权限已授予');
      
      return results;
    } catch (error) {
      debugPrint('❌ 批量申请权限失败: $error');
      return results;
    }
  }
  
  /// 打开应用设置页面
  Future<bool> openAppSettings() async {
    try {
      return await permission_handler.openAppSettings();
    } catch (error) {
      debugPrint('❌ 打开应用设置失败: $error');
      return false;
    }
  }
  
  /// 检查应用使用统计权限 (Android)
  Future<bool> _checkUsageStatsPermission() async {
    if (!Platform.isAndroid) return false;
    
    try {
      // 使用原生方法检查 PACKAGE_USAGE_STATS 权限
      // 由于 permission_handler 不直接支持，这里使用模拟
      // 实际项目中需要通过 MethodChannel 调用原生代码
      return await _checkUsageStatsPermissionNative();
    } catch (error) {
      debugPrint('检查使用统计权限失败: $error');
      return false;
    }
  }
  
  /// 检查系统覆盖层权限
  Future<bool> _checkSystemAlertPermission() async {
    if (!Platform.isAndroid) return true; // iOS 不需要
    
    try {
      final status = await permission_handler.Permission.systemAlertWindow.status;
      return status == permission_handler.PermissionStatus.granted;
    } catch (error) {
      debugPrint('检查系统覆盖层权限失败: $error');
      return false;
    }
  }
  
  /// 检查前台服务权限
  Future<bool> _checkForegroundServicePermission() async {
    if (!Platform.isAndroid) return true; // iOS 不需要
    
    try {
      final status = await permission_handler.Permission.ignoreBatteryOptimizations.status;
      return status == permission_handler.PermissionStatus.granted;
    } catch (error) {
      debugPrint('检查前台服务权限失败: $error');
      return false;
    }
  }
  
  /// 原生方法检查使用统计权限
  Future<bool> _checkUsageStatsPermissionNative() async {
    try {
      // 这里应该通过 MethodChannel 调用原生代码
      // 暂时返回 false，需要在实际项目中实现
      const platform = MethodChannel('focus_guide/permissions');
      
      // 模拟调用原生方法
      // final result = await platform.invokeMethod('checkUsageStatsPermission');
      // return result as bool;
      
      // 开发阶段返回 false，提示用户需要手动授权
      return false;
    } catch (error) {
      debugPrint('原生权限检查失败: $error');
      return false;
    }
  }
  
  /// 请求使用统计权限 (Android)
  Future<bool> _requestUsageStatsPermissionAndroid() async {
    try {
      // 跳转到使用统计权限设置页面
      const platform = MethodChannel('focus_guide/permissions');
      
      // 模拟调用原生方法打开设置页面
      // await platform.invokeMethod('openUsageStatsSettings');
      
      debugPrint('📱 请手动在设置中授予"应用使用统计"权限');
      
      // 等待用户操作后重新检查
      await Future.delayed(const Duration(seconds: 2));
      return await _checkUsageStatsPermissionNative();
    } catch (error) {
      debugPrint('请求使用统计权限失败: $error');
      return false;
    }
  }
  
  /// 获取权限描述文本
  String getPermissionDescription(String permissionType) {
    switch (permissionType) {
      case usageStats:
        return '检测应用启动和使用情况，实现智能引导功能';
      case systemAlert:
        return '在其他应用上方显示引导页面，提供温和提醒';
      case foregroundService:
        return '在后台持续监控应用使用，确保引导功能正常工作';
      default:
        return '未知权限';
    }
  }
  
  /// 获取权限重要性级别
  int getPermissionPriority(String permissionType) {
    switch (permissionType) {
      case usageStats:
        return 1; // 最重要
      case systemAlert:
        return 2;
      case foregroundService:
        return 3;
      default:
        return 999;
    }
  }
  
  /// 检查是否所有核心权限都已授予
  Future<bool> areAllCorePermissionsGranted() async {
    final permissions = await checkAllPermissions();
    
    // 核心权限：使用统计 + 系统覆盖层
    final corePermissions = [usageStats, systemAlert];
    
    return corePermissions.every((permission) => 
      permissions[permission] == true
    );
  }
  
  /// 获取权限申请建议文本
  String getPermissionGuidanceText() {
    return '''
为了提供最佳的专注引导体验，我们需要以下权限：

1. 📊 应用使用统计
   • 检测目标应用的启动
   • 不会收集个人隐私信息

2. 🔄 系统覆盖层
   • 显示温和的引导提醒
   • 提供替代活动选择

3. ⚡ 后台服务
   • 确保监控功能持续工作
   • 优化电池使用

所有权限仅用于应用核心功能，不会被滥用。''';
  }
}