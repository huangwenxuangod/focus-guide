import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage_service.dart';
import 'utils/performance_monitor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 记录应用启动时间
  PerformanceMonitor().recordAppStart();
  
  // 初始化存储服务
  final storageService = await StorageService.init();
  
  // 记录启动完成
  PerformanceMonitor().recordAppStartComplete();
  
  runApp(FocusGuideApp(storageService: storageService));
  
  // 延迟启动性能监控，避免影响应用启动
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(const Duration(seconds: 2), () {
      PerformanceMonitor().startFrameRateMonitoring();
      PerformanceMonitor().logMemoryUsage('app_ready');
    });
  });
}