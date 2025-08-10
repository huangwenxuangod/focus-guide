import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/app_models.dart';
import '../utils/performance_monitor.dart';
import 'storage_service.dart';

/// 使用模式分析
class UsagePattern {
  final String period; // 'morning', 'afternoon', 'evening', 'night'
  final List<String> topApps;
  final double averageSessionDuration;
  final int totalSessions;
  final double focusScore; // 0-100

  const UsagePattern({
    required this.period,
    required this.topApps,
    required this.averageSessionDuration,
    required this.totalSessions,
    required this.focusScore,
  });
}

/// 进步趋势
class ProgressTrend {
  final String metric; // 'guidance_count', 'activities_completed', 'focus_score'
  final List<double> values; // 最近7天的数据
  final double changePercentage; // 相比上周的变化百分比
  final String trend; // 'improving', 'declining', 'stable'

  const ProgressTrend({
    required this.metric,
    required this.values,
    required this.changePercentage,
    required this.trend,
  });
}

/// 个人洞察
class PersonalInsight {
  final String title;
  final String description;
  final String actionSuggestion;
  final String category; // 'productivity', 'wellness', 'habit', 'achievement'
  final int priority; // 1-10

  const PersonalInsight({
    required this.title,
    required this.description,
    required this.actionSuggestion,
    required this.category,
    required this.priority,
  });
}

/// 高级统计分析服务
class AnalyticsService with PerformanceTrackingMixin {
  static AnalyticsService? _instance;
  static AnalyticsService get instance => _instance ??= AnalyticsService._();
  AnalyticsService._();

  late final StorageService _storage;
  final Random _random = Random();

  /// 初始化服务
  Future<void> initialize() async {
    _storage = await StorageService.init();
  }

  /// 获取使用模式分析
  Future<List<UsagePattern>> getUsagePatterns() async {
    final patterns = <UsagePattern>[];
    
    // 分析不同时间段的使用模式
    final periods = ['morning', 'afternoon', 'evening', 'night'];
    
    for (final period in periods) {
      final pattern = await _analyzeTimePeriod(period);
      patterns.add(pattern);
    }
    
    debugPrint('📊 使用模式分析完成，共${patterns.length}个时间段');
    return patterns;
  }

  /// 分析特定时间段
  Future<UsagePattern> _analyzeTimePeriod(String period) async {
    // 模拟数据分析
    final topApps = _getTopAppsForPeriod(period);
    final avgDuration = _random.nextDouble() * 30 + 10; // 10-40分钟
    final sessions = _random.nextInt(10) + 5; // 5-15次
    final focusScore = _calculateFocusScore(period);
    
    return UsagePattern(
      period: period,
      topApps: topApps,
      averageSessionDuration: avgDuration,
      totalSessions: sessions,
      focusScore: focusScore,
    );
  }

  /// 获取时间段的热门应用
  List<String> _getTopAppsForPeriod(String period) {
    final appsByPeriod = {
      'morning': ['微信', '新闻', '天气'],
      'afternoon': ['工作应用', '邮件', '文档'],
      'evening': ['视频', '游戏', '社交'],
      'night': ['阅读', '音乐', '冥想'],
    };
    
    return appsByPeriod[period] ?? ['未知应用'];
  }

  /// 计算专注分数
  double _calculateFocusScore(String period) {
    final baseScores = {
      'morning': 75.0,
      'afternoon': 65.0,
      'evening': 55.0,
      'night': 45.0,
    };
    
    final baseScore = baseScores[period] ?? 60.0;
    final variation = (_random.nextDouble() - 0.5) * 20; // ±10分
    
    return (baseScore + variation).clamp(0.0, 100.0);
  }

  /// 获取进步趋势
  Future<List<ProgressTrend>> getProgressTrends() async {
    final trends = <ProgressTrend>[];
    
    // 分析不同指标的趋势
    final metrics = ['guidance_count', 'activities_completed', 'focus_score'];
    
    for (final metric in metrics) {
      final trend = await _analyzeTrend(metric);
      trends.add(trend);
    }
    
    debugPrint('📈 进步趋势分析完成，共${trends.length}个指标');
    return trends;
  }

  /// 分析单个指标趋势
  Future<ProgressTrend> _analyzeTrend(String metric) async {
    // 生成模拟的7天数据
    final values = List.generate(7, (index) {
      switch (metric) {
        case 'guidance_count':
          return (_random.nextDouble() * 10 + 5).roundToDouble(); // 5-15
        case 'activities_completed':
          return (_random.nextDouble() * 8 + 2).roundToDouble(); // 2-10
        case 'focus_score':
          return (_random.nextDouble() * 40 + 60).roundToDouble(); // 60-100
        default:
          return _random.nextDouble() * 100;
      }
    });
    
    // 计算变化百分比
    final recentAvg = values.skip(4).reduce((a, b) => a + b) / 3; // 最近3天
    final earlierAvg = values.take(3).reduce((a, b) => a + b) / 3; // 前3天
    final changePercentage = ((recentAvg - earlierAvg) / earlierAvg * 100);
    
    // 确定趋势
    String trend;
    if (changePercentage > 5) {
      trend = 'improving';
    } else if (changePercentage < -5) {
      trend = 'declining';
    } else {
      trend = 'stable';
    }
    
    return ProgressTrend(
      metric: metric,
      values: values,
      changePercentage: changePercentage,
      trend: trend,
    );
  }

  /// 获取个人洞察
  Future<List<PersonalInsight>> getPersonalInsights() async {
    return await trackPerformance('generate_personal_insights', () async {
      final insights = <PersonalInsight>[];
      
      // 基于数据生成洞察
      final todayStats = _storage.getTodayStats();
      
      // 生成不同类型的洞察
      insights.addAll(await _generateProductivityInsights(todayStats));
      insights.addAll(await _generateWellnessInsights(todayStats));
      insights.addAll(await _generateHabitInsights(todayStats));
      insights.addAll(await _generateAchievementInsights(todayStats));
      
      // 按优先级排序
      insights.sort((a, b) => b.priority.compareTo(a.priority));
      
      debugPrint('💡 个人洞察生成完成，共${insights.length}条');
      return insights.take(5).toList(); // 返回前5条最重要的洞察
    });
  }

  /// 生成生产力洞察
  Future<List<PersonalInsight>> _generateProductivityInsights(DailyStats stats) async {
    final insights = <PersonalInsight>[];
    
    if (stats.guidanceCount > 10) {
      insights.add(const PersonalInsight(
        title: '高频引导提醒',
        description: '今天您收到了较多的引导提醒，这表明您正在积极管理数字使用习惯。',
        actionSuggestion: '考虑调整引导频率，或者设置特定的专注时间段。',
        category: 'productivity',
        priority: 7,
      ));
    }
    
    if (stats.activitiesCompleted > 5) {
      insights.add(const PersonalInsight(
        title: '活动完成度优秀',
        description: '您今天完成了多项推荐活动，展现了良好的自我管理能力。',
        actionSuggestion: '继续保持这个节奏，可以尝试挑战更有难度的活动。',
        category: 'productivity',
        priority: 8,
      ));
    }
    
    return insights;
  }

  /// 生成健康洞察
  Future<List<PersonalInsight>> _generateWellnessInsights(DailyStats stats) async {
    final insights = <PersonalInsight>[];
    
    final hour = DateTime.now().hour;
    if (hour > 22 && stats.guidanceCount > 0) {
      insights.add(const PersonalInsight(
        title: '夜间使用提醒',
        description: '您在夜间仍在使用需要引导的应用，这可能影响睡眠质量。',
        actionSuggestion: '建议设置夜间模式，或在睡前1小时停止使用电子设备。',
        category: 'wellness',
        priority: 9,
      ));
    }
    
    return insights;
  }

  /// 生成习惯洞察
  Future<List<PersonalInsight>> _generateHabitInsights(DailyStats stats) async {
    final insights = <PersonalInsight>[];
    
    final successRate = stats.activitiesCompleted / (stats.guidanceCount + 1);
    if (successRate > 0.8) {
      insights.add(const PersonalInsight(
        title: '习惯养成进展良好',
        description: '您的引导接受率很高，说明正在成功建立健康的数字使用习惯。',
        actionSuggestion: '继续保持，可以考虑逐步减少引导频率，培养自主管理能力。',
        category: 'habit',
        priority: 6,
      ));
    }
    
    return insights;
  }

  /// 生成成就洞察
  Future<List<PersonalInsight>> _generateAchievementInsights(DailyStats stats) async {
    final insights = <PersonalInsight>[];
    
    if (stats.guidanceCount == 0 && stats.activitiesCompleted > 0) {
      insights.add(const PersonalInsight(
        title: '自主管理成就',
        description: '今天您没有触发引导提醒，但仍完成了推荐活动，展现了优秀的自控力。',
        actionSuggestion: '为自己庆祝这个成就！可以给自己一个小奖励。',
        category: 'achievement',
        priority: 10,
      ));
    }
    
    return insights;
  }

  /// 获取专注分数
  Future<double> calculateFocusScore() async {
    return await trackPerformance('calculate_focus_score', () async {
      final stats = _storage.getTodayStats();
      
      // 基于多个因素计算专注分数
      double score = 100.0;
      
      // 引导次数影响（越多扣分越多）
      score -= stats.guidanceCount * 2;
      
      // 完成活动加分
      score += stats.activitiesCompleted * 5;
      
      // 时间因素
      final hour = DateTime.now().hour;
      if (hour >= 9 && hour < 18) {
        // 工作时间，专注更重要
        score -= stats.guidanceCount * 1;
      }
      
      // 确保分数在0-100范围内
      score = score.clamp(0.0, 100.0);
      
      debugPrint('🎯 今日专注分数: ${score.toStringAsFixed(1)}');
      return score;
    });
  }

  /// 获取周报数据
  Future<Map<String, dynamic>> getWeeklyReport() async {
    return await trackPerformance('generate_weekly_report', () async {
      final patterns = await getUsagePatterns();
      final trends = await getProgressTrends();
      final insights = await getPersonalInsights();
      final focusScore = await calculateFocusScore();
      
      return {
        'focus_score': focusScore,
        'usage_patterns': patterns.map((p) => {
          'period': p.period,
          'top_apps': p.topApps,
          'avg_duration': p.averageSessionDuration,
          'sessions': p.totalSessions,
          'focus_score': p.focusScore,
        }).toList(),
        'progress_trends': trends.map((t) => {
          'metric': t.metric,
          'values': t.values,
          'change_percentage': t.changePercentage,
          'trend': t.trend,
        }).toList(),
        'insights': insights.map((i) => {
          'title': i.title,
          'description': i.description,
          'action_suggestion': i.actionSuggestion,
          'category': i.category,
          'priority': i.priority,
        }).toList(),
        'generated_at': DateTime.now().toIso8601String(),
      };
    });
  }

  /// 获取简化的统计摘要
  Map<String, dynamic> getQuickStats() {
    final stats = _storage.getTodayStats();
    
    return {
      'guidance_count': stats.guidanceCount,
      'activities_completed': stats.activitiesCompleted,
      'success_rate': stats.activitiesCompleted / (stats.guidanceCount + 1),
      'last_updated': DateTime.now().toIso8601String(),
    };
  }
}