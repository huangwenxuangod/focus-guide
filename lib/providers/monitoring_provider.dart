import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';
import '../services/monitor_service.dart';
import '../services/permission_service.dart';
import '../widgets/guide_overlay.dart';
import 'stats_provider.dart';

class MonitoringProvider extends ChangeNotifier {
  final StorageService _storage;
  bool _isEnabled = false;
  List<MonitoredApp> _apps = [];
  bool _isInitialized = false;

  MonitoringProvider(this._storage) {
    _loadData();
    _initializeServices();
  }

  bool get isEnabled => _isEnabled;
  List<MonitoredApp> get apps => List.unmodifiable(_apps);
  int get enabledAppsCount => _apps.where((app) => app.isEnabled).length;

  /// 从存储加载数据
  void _loadData() {
    _isEnabled = _storage.getMonitoringEnabled();
    _apps = _storage.getMonitoredApps();
    notifyListeners();
  }

  /// 初始化监控和权限服务
  Future<void> _initializeServices() async {
    try {
      // 设置应用启动监听
      MonitorService.instance.onAppLaunched = _handleAppLaunched;
      
      // 设置权限状态监听
      PermissionService.instance.onPermissionChanged = _handlePermissionChanged;
      
      _isInitialized = true;
      debugPrint('✅ 监控服务初始化完成');
    } catch (error) {
      debugPrint('❌ 监控服务初始化失败: $error');
    }
  }
  
  /// 设置统计提供者（用于监控服务）
  void setStatsProvider(StatsProvider statsProvider) {
    // 更新监控服务的统计提供者
    if (_isInitialized) {
      MonitorService.instance.initialize(_apps, statsProvider);
    }
  }
  
  /// 切换监控总开关 - 乐观更新
  Future<void> toggleMonitoring() async {
    final oldState = _isEnabled;
    
    // 立即更新UI
    _isEnabled = !_isEnabled;
    notifyListeners();
    
    // 启动/停止监控
    if (_isEnabled) {
      await _startMonitoring();
    } else {
      await _stopMonitoring();
    }
    
    // 异步保存，失败时回滚
    try {
      await _storage.setMonitoringEnabled(_isEnabled);
    } catch (error) {
      // 保存失败，回滚UI状态
      _isEnabled = oldState;
      notifyListeners();
      debugPrint('保存监控状态失败: $error');
    }
  }

  /// 更新应用监控状态 - 乐观更新
  Future<void> updateAppStatus(String packageName, bool isEnabled) async {
    final index = _apps.indexWhere((app) => app.packageName == packageName);
    if (index == -1) return;
    
    final oldApp = _apps[index];
    
    // 检查状态是否真的发生变化，避免不必要的更新
    if (oldApp.isEnabled == isEnabled) return;
    
    // 立即更新UI
    _apps[index] = oldApp.copyWith(isEnabled: isEnabled);
    notifyListeners();
    
    // 异步保存，失败时回滚
    try {
      await _storage.updateAppStatus(packageName, isEnabled);
    } catch (error) {
      // 保存失败，回滚UI状态
      _apps[index] = oldApp;
      notifyListeners();
      debugPrint('保存应用状态失败: $error');
    }
  }

  /// 启动监控服务
  Future<void> _startMonitoring() async {
    try {
      // 检查权限
      final permissions = await PermissionService.instance.checkAllPermissions();
      final hasRequiredPermissions = permissions['usage_stats'] == true && 
                                   permissions['system_alert'] == true;
      
      if (!hasRequiredPermissions) {
        debugPrint('⚠️ 权限不足，无法启动监控');
        // 可以在这里提示用户申请权限
        return;
      }
      
      // 初始化并启动监控服务（暂时不传递StatsProvider，避免循环依赖）
       final success = await MonitorService.instance.initialize(_apps, null);
      if (success) {
        await MonitorService.instance.startMonitoring();
        debugPrint('🚀 监控服务已启动');
      } else {
        debugPrint('❌ 监控服务启动失败');
      }
    } catch (error) {
      debugPrint('启动监控服务异常: $error');
    }
  }

  /// 停止监控服务
  Future<void> _stopMonitoring() async {
    MonitorService.instance.stopMonitoring();
    debugPrint('⏹️ 监控服务已停止');
  }
  
  /// 处理应用启动事件
  void _handleAppLaunched(String packageName, String appName) {
    debugPrint('🎯 应用启动事件: $appName ($packageName)');
    
    // 触发引导覆盖层显示
    showGuideOverlay(appName, packageName);
    
    // 通知UI更新
    notifyListeners();
  }
  
  /// 处理权限状态变化
  void _handlePermissionChanged(String permissionType, bool isGranted) {
    debugPrint('🔐 权限状态变化: $permissionType = $isGranted');
    // 权限状态变化时可能需要重新评估监控状态
  }
  
  /// 请求所有必要权限
  Future<Map<String, bool>> requestPermissions() async {
    return await PermissionService.instance.requestAllPermissions();
  }
  
  /// 检查权限状态
  Future<Map<String, bool>> checkPermissions() async {
    return await PermissionService.instance.checkAllPermissions();
  }
  
  // 引导覆盖层相关
  bool _shouldShowGuideOverlay = false;
  String _currentAppName = '';
  String _currentPackageName = '';
  
  bool get shouldShowGuideOverlay => _shouldShowGuideOverlay;
  String get currentAppName => _currentAppName;
  String get currentPackageName => _currentPackageName;
  
  void showGuideOverlay(String appName, String packageName) {
    _shouldShowGuideOverlay = true;
    _currentAppName = appName;
    _currentPackageName = packageName;
    notifyListeners();
    debugPrint('🎯 准备显示引导覆盖层: $appName');
  }
  
  void hideGuideOverlay() {
    if (_shouldShowGuideOverlay) {
      _shouldShowGuideOverlay = false;
      notifyListeners();
      GuideOverlayManager.instance.hideGuideOverlay();
    }
  }
  
  /// 显示引导覆盖层（兼容方法）
  void showGuideOverlayWithContext(BuildContext context, String packageName) {
    final app = _apps.firstWhere(
      (app) => app.packageName == packageName,
      orElse: () => MonitoredApp(
        packageName: packageName,
        displayName: '未知应用',
        isEnabled: false,
      ),
    );
    
    showGuideOverlay(app.displayName, packageName);
  }
  
  /// 获取监控服务状态
  bool get isMonitorServiceRunning => MonitorService.instance.isMonitoring;
  
  /// 获取初始化状态
  bool get isInitialized => _isInitialized;
  
  /// 刷新数据
  Future<void> refreshData() async {
    _loadData();
    if (_isEnabled && _isInitialized) {
      await _startMonitoring();
    }
  }
  
  @override
  void dispose() {
    MonitorService.instance.dispose();
    super.dispose();
  }
}

