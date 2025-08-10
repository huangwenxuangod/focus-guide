import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../utils/performance_monitor.dart';
import 'storage_service.dart';

/// 引导策略类型
enum GuidanceStrategy {
  gentle,     // 温和引导
  firm,       // 坚定引导
  motivational, // 激励引导
  educational,  // 教育引导
}

/// 引导建议
class GuidanceSuggestion {
  final String title;
  final String message;
  final List<String> activities;
  final GuidanceStrategy strategy;
  final int priority; // 1-10，数字越大优先级越高

  const GuidanceSuggestion({
    required this.title,
    required this.message,
    required this.activities,
    required this.strategy,
    required this.priority,
  });
}

/// 智能引导服务 - 基于用户行为的个性化引导
class SmartGuidanceService with PerformanceTrackingMixin {
  static SmartGuidanceService? _instance;
  static SmartGuidanceService get instance => _instance ??= SmartGuidanceService._();
  SmartGuidanceService._();

  late final StorageService _storage;
  
  /// 初始化服务
  Future<void> initialize() async {
    _storage = await StorageService.init();
  }
  final Random _random = Random();

  /// 获取智能引导建议
  Future<GuidanceSuggestion> getSmartGuidance(String packageName) async {
    final stats = _storage.getTodayStats();
    final userPattern = await _analyzeUserPattern();
    final timeContext = _getTimeContext();
    
    // 基于多维度分析生成个性化引导
    final strategy = _determineStrategy(stats, userPattern, timeContext);
    final suggestion = _generateSuggestion(packageName, strategy, timeContext);
    
    debugPrint('🧠 智能引导生成: ${suggestion.title} (策略: ${strategy.name})');
    return suggestion;
  }

  /// 分析用户行为模式
  Future<UserPattern> _analyzeUserPattern() async {
    // 简化实现，使用当前统计数据
    final todayStats = _storage.getTodayStats();
    
    // 模拟历史数据分析
    final avgGuidance = todayStats.guidanceCount.toDouble();
    final avgActivities = todayStats.activitiesCompleted.toDouble();
    final successRate = avgActivities / (avgGuidance + 1); // 避免除零

    return UserPattern(
      averageGuidancePerDay: avgGuidance,
      averageActivitiesPerDay: avgActivities,
      successRate: successRate,
      totalDays: 1, // 简化为当天
    );
  }

  /// 确定引导策略
  GuidanceStrategy _determineStrategy(
    DailyStats todayStats,
    UserPattern pattern,
    TimeContext timeContext,
  ) {
    // 新用户使用温和策略
    if (pattern.totalDays < 3) {
      return GuidanceStrategy.gentle;
    }

    // 成功率高的用户使用激励策略
    if (pattern.successRate > 0.7) {
      return GuidanceStrategy.motivational;
    }

    // 今天已经引导很多次，使用教育策略
    if (todayStats.guidanceCount > pattern.averageGuidancePerDay * 1.5) {
      return GuidanceStrategy.educational;
    }

    // 工作时间使用坚定策略
    if (timeContext.isWorkTime) {
      return GuidanceStrategy.firm;
    }

    // 默认使用温和策略
    return GuidanceStrategy.gentle;
  }

  /// 生成具体建议
  GuidanceSuggestion _generateSuggestion(
    String packageName,
    GuidanceStrategy strategy,
    TimeContext timeContext,
  ) {
    final appName = _getAppDisplayName(packageName);
    
    switch (strategy) {
      case GuidanceStrategy.gentle:
        return _generateGentleGuidance(appName, timeContext);
      case GuidanceStrategy.firm:
        return _generateFirmGuidance(appName, timeContext);
      case GuidanceStrategy.motivational:
        return _generateMotivationalGuidance(appName, timeContext);
      case GuidanceStrategy.educational:
        return _generateEducationalGuidance(appName, timeContext);
    }
  }

  /// 温和引导
  GuidanceSuggestion _generateGentleGuidance(String appName, TimeContext context) {
    final messages = [
      '也许现在是休息一下的好时机？',
      '不如先做点别的事情，稍后再回来？',
      '要不要试试其他有趣的活动？',
      '给自己一个小小的挑战如何？',
    ];

    return GuidanceSuggestion(
      title: '温和提醒',
      message: messages[_random.nextInt(messages.length)],
      activities: _getContextualActivities(context),
      strategy: GuidanceStrategy.gentle,
      priority: 3,
    );
  }

  /// 坚定引导
  GuidanceSuggestion _generateFirmGuidance(String appName, TimeContext context) {
    final messages = [
      '现在是专注时间，让我们把注意力转向更重要的事情。',
      '工作时间到了，是时候专注于目标了。',
      '让我们暂停娱乐，专注于当前的任务。',
      '现在需要集中精力，稍后再享受休闲时光。',
    ];

    return GuidanceSuggestion(
      title: '专注提醒',
      message: messages[_random.nextInt(messages.length)],
      activities: _getProductiveActivities(),
      strategy: GuidanceStrategy.firm,
      priority: 7,
    );
  }

  /// 激励引导
  GuidanceSuggestion _generateMotivationalGuidance(String appName, TimeContext context) {
    final messages = [
      '你一直做得很好！继续保持这个节奏。',
      '每一次选择都在塑造更好的自己。',
      '你的自控力正在变得越来越强！',
      '又是一个展现意志力的机会！',
    ];

    return GuidanceSuggestion(
      title: '继续加油',
      message: messages[_random.nextInt(messages.length)],
      activities: _getRewardingActivities(),
      strategy: GuidanceStrategy.motivational,
      priority: 5,
    );
  }

  /// 教育引导
  GuidanceSuggestion _generateEducationalGuidance(String appName, TimeContext context) {
    final tips = [
      '小贴士：每次使用手机前，先问自己"我真的需要这个吗？"',
      '研究表明：短暂的休息比长时间的娱乐更能恢复精力。',
      '建议：设定特定的娱乐时间，其他时间专注于目标。',
      '提醒：数字排毒有助于提高注意力和创造力。',
    ];

    return GuidanceSuggestion(
      title: '智慧分享',
      message: tips[_random.nextInt(tips.length)],
      activities: _getLearningActivities(),
      strategy: GuidanceStrategy.educational,
      priority: 4,
    );
  }

  /// 获取时间上下文
  TimeContext _getTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;
    
    return TimeContext(
      hour: hour,
      isWorkTime: hour >= 9 && hour < 18,
      isEveningTime: hour >= 18 && hour < 22,
      isNightTime: hour >= 22 || hour < 6,
      dayOfWeek: now.weekday,
    );
  }

  /// 获取应用显示名称
  String _getAppDisplayName(String packageName) {
    final appMap = {
      'com.tencent.mm': '微信',
      'com.sina.weibo': '微博',
      'com.ss.android.ugc.aweme': '抖音',
      'com.tencent.mobileqq': 'QQ',
      'com.taobao.taobao': '淘宝',
    };
    
    return appMap[packageName] ?? '应用';
  }

  /// 获取上下文相关活动
  List<String> _getContextualActivities(TimeContext context) {
    if (context.isWorkTime) {
      return _getProductiveActivities();
    } else if (context.isEveningTime) {
      return _getRelaxingActivities();
    } else {
      return _getGeneralActivities();
    }
  }

  /// 获取生产力活动
  List<String> _getProductiveActivities() {
    return [
      '📝 整理今天的工作计划',
      '📚 阅读专业相关文章',
      '💡 思考一个创新想法',
      '📊 回顾项目进度',
      '🎯 设定下一个小目标',
    ];
  }

  /// 获取放松活动
  List<String> _getRelaxingActivities() {
    return [
      '🧘 进行5分钟冥想',
      '🚶 到户外走走',
      '🎵 听一首喜欢的音乐',
      '📖 阅读几页好书',
      '☕ 泡一杯茶慢慢品味',
    ];
  }

  /// 获取奖励活动
  List<String> _getRewardingActivities() {
    return [
      '🎉 为自己的进步庆祝',
      '📱 给朋友发个鼓励消息',
      '🌟 在日记中记录今天的成就',
      '🎁 给自己一个小奖励',
      '💪 做几个伸展运动',
    ];
  }

  /// 获取学习活动
  List<String> _getLearningActivities() {
    return [
      '🧠 学习一个新技能',
      '📺 观看教育类视频',
      '🔍 研究感兴趣的话题',
      '✍️ 写下今天的思考',
      '📚 阅读一篇有价值的文章',
    ];
  }

  /// 获取通用活动
  List<String> _getGeneralActivities() {
    return [
      '💧 喝一杯水',
      '👀 看看远方放松眼睛',
      '🤸 做几个简单运动',
      '🌱 照顾一下植物',
      '🧹 整理一下周围环境',
    ];
  }
}

/// 用户行为模式
class UserPattern {
  final double averageGuidancePerDay;
  final double averageActivitiesPerDay;
  final double successRate;
  final int totalDays;

  const UserPattern({
    required this.averageGuidancePerDay,
    required this.averageActivitiesPerDay,
    required this.successRate,
    required this.totalDays,
  });

  factory UserPattern.newUser() {
    return const UserPattern(
      averageGuidancePerDay: 0,
      averageActivitiesPerDay: 0,
      successRate: 0,
      totalDays: 0,
    );
  }
}

/// 时间上下文
class TimeContext {
  final int hour;
  final bool isWorkTime;
  final bool isEveningTime;
  final bool isNightTime;
  final int dayOfWeek;

  const TimeContext({
    required this.hour,
    required this.isWorkTime,
    required this.isEveningTime,
    required this.isNightTime,
    required this.dayOfWeek,
  });
}