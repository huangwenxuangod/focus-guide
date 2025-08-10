import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// 性能监控工具
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  DateTime? _appStartTime;
  final Map<String, DateTime> _operationStartTimes = {};
  final Map<String, Duration> _operationDurations = {};

  /// 记录应用启动时间
  void recordAppStart() {
    _appStartTime = DateTime.now();
    debugPrint('🚀 应用启动时间记录: ${_appStartTime!.toIso8601String()}');
  }

  /// 记录应用启动完成
  void recordAppStartComplete() {
    if (_appStartTime != null) {
      final duration = DateTime.now().difference(_appStartTime!);
      debugPrint('✅ 应用启动完成，耗时: ${duration.inMilliseconds}ms');
      
      // 检查启动时间是否超过目标（3秒）
      if (duration.inSeconds > 3) {
        debugPrint('⚠️ 应用启动时间超过目标（3秒）');
      }
    }
  }

  /// 开始记录操作时间
  void startOperation(String operationName) {
    _operationStartTimes[operationName] = DateTime.now();
    debugPrint('⏱️ 开始操作: $operationName');
  }

  /// 结束记录操作时间
  void endOperation(String operationName) {
    final startTime = _operationStartTimes[operationName];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationDurations[operationName] = duration;
      debugPrint('✅ 操作完成: $operationName，耗时: ${duration.inMilliseconds}ms');
      
      // 清理开始时间记录
      _operationStartTimes.remove(operationName);
      
      // 检查是否有性能问题
      _checkPerformanceIssues(operationName, duration);
    }
  }

  /// 检查性能问题
  void _checkPerformanceIssues(String operationName, Duration duration) {
    const performanceThresholds = {
      'permission_check': 1000, // 1秒
      'storage_operation': 500,  // 500ms
      'ui_update': 100,         // 100ms
      'app_monitoring': 200,    // 200ms
    };

    for (final entry in performanceThresholds.entries) {
      if (operationName.contains(entry.key) && 
          duration.inMilliseconds > entry.value) {
        debugPrint('⚠️ 性能警告: $operationName 耗时 ${duration.inMilliseconds}ms，超过阈值 ${entry.value}ms');
      }
    }
  }

  /// 获取内存使用情况
  Future<void> logMemoryUsage([String? context]) async {
    if (!kDebugMode) return;
    
    try {
      // 简化的内存监控，使用Process.memoryUsage（如果可用）
      final contextStr = context != null ? ' [$context]' : '';
      
      if (Platform.isAndroid || Platform.isIOS) {
        // 移动平台使用简单的内存估算
        final rss = ProcessInfo.currentRss;
        final usedMB = rss / (1024 * 1024);
        
        debugPrint('📊 内存使用$contextStr: ${usedMB.toStringAsFixed(1)}MB');
        
        // 检查内存使用是否超过目标（100MB）
        if (usedMB > 100) {
          debugPrint('⚠️ 内存使用超过目标（100MB）');
        }
      } else {
        debugPrint('📊 内存监控$contextStr: 当前平台不支持详细内存信息');
      }
    } catch (error) {
      debugPrint('❌ 获取内存信息失败: $error');
    }
  }

  /// 监控帧率
  void startFrameRateMonitoring() {
    if (!kDebugMode) return;
    
    Duration? _lastFrameTime;
    int _frameWarningCount = 0;
    DateTime? _lastWarningTime;
    
    WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
      if (_lastFrameTime != null) {
        final frameDuration = timeStamp - _lastFrameTime!;
        final frameDurationMs = frameDuration.inMicroseconds / 1000.0;
        
        // 检查帧率是否低于60fps (16.67ms per frame)
        if (frameDurationMs > 16.67) {
          _frameWarningCount++;
          final now = DateTime.now();
          
          // 限制警告频率：每5秒最多输出一次警告
          if (_lastWarningTime == null || 
              now.difference(_lastWarningTime!).inSeconds >= 5) {
            debugPrint('⚠️ 帧率警告: 最近检测到 $_frameWarningCount 次掉帧，最新帧耗时 ${frameDurationMs.toStringAsFixed(1)}ms');
            _lastWarningTime = now;
            _frameWarningCount = 0;
          }
        }
      }
      _lastFrameTime = timeStamp;
    });
  }

  /// 获取性能报告
  Map<String, dynamic> getPerformanceReport() {
    return {
      'app_start_time': _appStartTime?.toIso8601String(),
      'operation_durations': _operationDurations.map(
        (key, value) => MapEntry(key, value.inMilliseconds),
      ),
      'pending_operations': _operationStartTimes.keys.toList(),
    };
  }

  /// 清理性能数据
  void clearPerformanceData() {
    _operationStartTimes.clear();
    _operationDurations.clear();
    debugPrint('🧹 性能监控数据已清理');
  }
}

/// 性能监控装饰器 - 优化版本
mixin PerformanceTrackingMixin {
  static final PerformanceMonitor _perfMonitor = PerformanceMonitor();
  static bool _isPerformanceTrackingEnabled = false;
  
  /// 启用性能跟踪（仅在需要时启用）
  static void enablePerformanceTracking() {
    _isPerformanceTrackingEnabled = true;
  }
  
  /// 禁用性能跟踪
  static void disablePerformanceTracking() {
    _isPerformanceTrackingEnabled = false;
  }

  /// 执行带性能监控的操作（仅在启用时监控）
  Future<T> trackPerformance<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!_isPerformanceTrackingEnabled) {
      return await operation();
    }
    
    _perfMonitor.startOperation(operationName);
    try {
      final result = await operation();
      _perfMonitor.endOperation(operationName);
      return result;
    } catch (error) {
      _perfMonitor.endOperation(operationName);
      rethrow;
    }
  }

  /// 记录内存使用（仅在启用时记录）
  Future<void> logMemory([String? context]) async {
    if (_isPerformanceTrackingEnabled) {
      await _perfMonitor.logMemoryUsage(context);
    }
  }
}