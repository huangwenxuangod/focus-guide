import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

class PermissionProvider extends ChangeNotifier {
  final StorageService _storage;
  Map<String, bool> _permissions = {};

  PermissionProvider(this._storage) {
    _loadData();
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

  /// 请求所有权限
  Future<void> requestAllPermissions() async {
    // TODO: 实现权限请求逻辑
    debugPrint('请求所有权限');
  }

  /// 检查特定权限是否已授予
  bool isPermissionGranted(String type) {
    return _permissions[type] ?? false;
  }
}