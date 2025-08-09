import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../services/storage_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final StorageService _storage;
  bool _isEnabled = false;
  List<MonitoredApp> _apps = [];

  MonitoringProvider(this._storage) {
    _loadData();
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

  /// 切换监控总开关 - 乐观更新
  Future<void> toggleMonitoring() async {
    final oldState = _isEnabled;
    
    // 立即更新UI
    _isEnabled = !_isEnabled;
    notifyListeners();
    
    // 启动/停止监控
    if (_isEnabled) {
      _startMonitoring();
    } else {
      _stopMonitoring();
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

  void _startMonitoring() {
    debugPrint('开始监控应用使用');
  }

  void _stopMonitoring() {
    debugPrint('停止监控应用使用');
  }
}

