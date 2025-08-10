import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import '../models/app_models.dart';

class StatsProvider extends ChangeNotifier {
  final StorageService _storage;
  late DailyStats _todayStats;

  StatsProvider(this._storage) {
    _loadData();
  }

  int get guidanceCount => _todayStats.guidanceCount;
  int get activitiesCompleted => _todayStats.activitiesCompleted;

  /// 从存储加载今日统计数据
  void _loadData() {
    _todayStats = _storage.getTodayStats();
    notifyListeners();
  }

  /// 增加引导次数 - 立即更新UI
  Future<void> incrementGuidanceCount() async {
    final oldStats = _todayStats;
    
    // 立即更新UI
    _todayStats = _todayStats.copyWith(
      guidanceCount: _todayStats.guidanceCount + 1,
    );
    notifyListeners();
    
    // 异步保存，失败时回滚
    try {
      await _storage.incrementGuidanceCount();
    } catch (error) {
      // 保存失败，回滚UI状态
      _todayStats = oldStats;
      notifyListeners();
      debugPrint('保存引导次数失败: $error');
    }
  }

  /// 增加完成活动次数 - 立即更新UI
  Future<void> incrementActivitiesCompleted() async {
    final oldStats = _todayStats;
    
    // 立即更新UI
    _todayStats = _todayStats.copyWith(
      activitiesCompleted: _todayStats.activitiesCompleted + 1,
    );
    notifyListeners();
    
    // 异步保存，失败时回滚
    try {
      await _storage.incrementActivitiesCompleted();
    } catch (error) {
      // 保存失败，回滚UI状态
      _todayStats = oldStats;
      notifyListeners();
      debugPrint('保存活动完成次数失败: $error');
    }
  }

  /// 清理旧数据 (保留最近7天)
  Future<void> cleanOldData() async {
    await _storage.cleanOldStats();
  }
  
  /// 刷新统计数据
  Future<void> refreshStats() async {
    _loadData();
  }
}