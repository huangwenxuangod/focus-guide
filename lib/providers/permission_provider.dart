import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../services/permission_service.dart';

class PermissionProvider extends ChangeNotifier {
  final StorageService _storage;
  Map<String, bool> _permissions = {};
  bool _isInitialized = false;

  PermissionProvider(this._storage) {
    _loadData();
    _initializePermissionService();
  }
  
  Map<String, bool> get permissions => Map.unmodifiable(_permissions);
  bool get allGranted => _permissions.values.every((granted) => granted);
  int get grantedCount => _permissions.values.where((granted) => granted).length;

  /// 从存储加载权限数据
  void _loadData() {
    _permissions = _storage.getPermissions();
    notifyListeners();
  }

  /// 更新权限状态 - 乐观更新
  Future<void> updatePermission(String type, bool isGranted) async {
    final oldValue = _permissions[type];
    
    // 立即更新UI
    _permissions[type] = isGranted;
    notifyListeners();
    
    // 异步保存，失败时回滚
    try {
      await _storage.updatePermission(type, isGranted);
    } catch (error) {
      // 保存失败，回滚UI状态
      _permissions[type] = oldValue ?? false;
      notifyListeners();
      debugPrint('保存权限状态失败: $error');
    }
  }

  /// 初始化权限服务
  Future<void> _initializePermissionService() async {
    try {
      // 设置权限状态变化监听
      PermissionService.instance.onPermissionChanged = _handlePermissionChanged;
      
      // 检查当前权限状态
      await refreshPermissions();
      
      _isInitialized = true;
      debugPrint('✅ 权限服务初始化完成');
    } catch (error) {
      debugPrint('❌ 权限服务初始化失败: $error');
    }
  }
  
  /// 刷新权限状态
  Future<void> refreshPermissions() async {
    try {
      final currentPermissions = await PermissionService.instance.checkAllPermissions();
      
      // 更新本地状态
      for (final entry in currentPermissions.entries) {
        _permissions[entry.key] = entry.value;
      }
      
      // 保存到存储
      for (final entry in _permissions.entries) {
        await _storage.updatePermission(entry.key, entry.value);
      }
      
      notifyListeners();
      debugPrint('🔄 权限状态已刷新: $_permissions');
    } catch (error) {
      debugPrint('刷新权限状态失败: $error');
    }
  }
  
  /// 处理权限状态变化
  void _handlePermissionChanged(String permissionType, bool isGranted) {
    debugPrint('🔐 权限状态变化: $permissionType = $isGranted');
    
    // 更新本地状态
    _permissions[permissionType] = isGranted;
    notifyListeners();
    
    // 异步保存到存储
    _storage.updatePermission(permissionType, isGranted).catchError((error) {
      debugPrint('保存权限状态失败: $error');
    });
  }
  
  /// 请求特定权限
  Future<bool> requestPermission(String permissionType) async {
    try {
      bool result = false;
      
      switch (permissionType) {
        case PermissionService.usageStats:
          result = await PermissionService.instance.requestUsageStatsPermission();
          break;
        case PermissionService.systemAlert:
          result = await PermissionService.instance.requestSystemAlertPermission();
          break;
        case PermissionService.foregroundService:
          result = await PermissionService.instance.requestForegroundServicePermission();
          break;
        default:
          debugPrint('未知权限类型: $permissionType');
          return false;
      }
      
      // 更新状态
      await updatePermission(permissionType, result);
      return result;
    } catch (error) {
      debugPrint('请求权限失败: $permissionType, $error');
      return false;
    }
  }
  
  /// 请求所有权限
  Future<Map<String, bool>> requestAllPermissions() async {
    try {
      final results = await PermissionService.instance.requestAllPermissions();
      
      // 更新本地状态
      for (final entry in results.entries) {
        await updatePermission(entry.key, entry.value);
      }
      
      return results;
    } catch (error) {
      debugPrint('批量请求权限失败: $error');
      return {};
    }
  }

  /// 检查特定权限是否已授予
  bool isPermissionGranted(String type) {
    return _permissions[type] ?? false;
  }
  
  /// 获取权限描述
  String getPermissionDescription(String permissionType) {
    return PermissionService.instance.getPermissionDescription(permissionType);
  }
  
  /// 获取权限重要性级别
  int getPermissionPriority(String permissionType) {
    return PermissionService.instance.getPermissionPriority(permissionType);
  }
  
  /// 检查核心权限是否都已授予
  Future<bool> areAllCorePermissionsGranted() async {
    return await PermissionService.instance.areAllCorePermissionsGranted();
  }
  
  /// 打开应用设置页面
  Future<bool> openAppSettings() async {
    return await PermissionService.instance.openAppSettings();
  }
  
  /// 获取权限申请指导文本
  String getPermissionGuidanceText() {
    return PermissionService.instance.getPermissionGuidanceText();
  }
  
  /// 获取初始化状态
  bool get isInitialized => _isInitialized;
  
  /// 获取权限列表（按重要性排序）
  List<String> get sortedPermissionTypes {
    final types = _permissions.keys.toList();
    types.sort((a, b) => getPermissionPriority(a).compareTo(getPermissionPriority(b)));
    return types;
  }
}