import 'package:flutter/foundation.dart';
import '../utils/performance_monitor.dart';
import 'storage_service.dart';

/// 个性化设置
class PersonalizationSettings {
  final bool enableSmartGuidance;
  final bool enableMotivationalMessages;
  final bool enableEducationalTips;
  final int guidanceFrequency; // 分钟
  final List<String> preferredActivities;
  final String guidanceStyle; // 'gentle', 'firm', 'balanced'
  final bool enableNightMode;
  final bool enableWorkTimeMode;
  final Map<String, bool> appSpecificSettings;

  const PersonalizationSettings({
    this.enableSmartGuidance = true,
    this.enableMotivationalMessages = true,
    this.enableEducationalTips = true,
    this.guidanceFrequency = 30,
    this.preferredActivities = const [],
    this.guidanceStyle = 'balanced',
    this.enableNightMode = false,
    this.enableWorkTimeMode = true,
    this.appSpecificSettings = const {},
  });

  PersonalizationSettings copyWith({
    bool? enableSmartGuidance,
    bool? enableMotivationalMessages,
    bool? enableEducationalTips,
    int? guidanceFrequency,
    List<String>? preferredActivities,
    String? guidanceStyle,
    bool? enableNightMode,
    bool? enableWorkTimeMode,
    Map<String, bool>? appSpecificSettings,
  }) {
    return PersonalizationSettings(
      enableSmartGuidance: enableSmartGuidance ?? this.enableSmartGuidance,
      enableMotivationalMessages: enableMotivationalMessages ?? this.enableMotivationalMessages,
      enableEducationalTips: enableEducationalTips ?? this.enableEducationalTips,
      guidanceFrequency: guidanceFrequency ?? this.guidanceFrequency,
      preferredActivities: preferredActivities ?? this.preferredActivities,
      guidanceStyle: guidanceStyle ?? this.guidanceStyle,
      enableNightMode: enableNightMode ?? this.enableNightMode,
      enableWorkTimeMode: enableWorkTimeMode ?? this.enableWorkTimeMode,
      appSpecificSettings: appSpecificSettings ?? this.appSpecificSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableSmartGuidance': enableSmartGuidance,
      'enableMotivationalMessages': enableMotivationalMessages,
      'enableEducationalTips': enableEducationalTips,
      'guidanceFrequency': guidanceFrequency,
      'preferredActivities': preferredActivities,
      'guidanceStyle': guidanceStyle,
      'enableNightMode': enableNightMode,
      'enableWorkTimeMode': enableWorkTimeMode,
      'appSpecificSettings': appSpecificSettings,
    };
  }

  factory PersonalizationSettings.fromJson(Map<String, dynamic> json) {
    return PersonalizationSettings(
      enableSmartGuidance: json['enableSmartGuidance'] ?? true,
      enableMotivationalMessages: json['enableMotivationalMessages'] ?? true,
      enableEducationalTips: json['enableEducationalTips'] ?? true,
      guidanceFrequency: json['guidanceFrequency'] ?? 30,
      preferredActivities: List<String>.from(json['preferredActivities'] ?? []),
      guidanceStyle: json['guidanceStyle'] ?? 'balanced',
      enableNightMode: json['enableNightMode'] ?? false,
      enableWorkTimeMode: json['enableWorkTimeMode'] ?? true,
      appSpecificSettings: Map<String, bool>.from(json['appSpecificSettings'] ?? {}),
    );
  }
}

/// 个性化服务 - 管理用户偏好和自定义设置
class PersonalizationService with PerformanceTrackingMixin {
  static PersonalizationService? _instance;
  static PersonalizationService get instance => _instance ??= PersonalizationService._();
  PersonalizationService._();

  late final StorageService _storage;
  PersonalizationSettings _settings = const PersonalizationSettings();
  
  static const String _settingsKey = 'personalization_settings';

  /// 初始化服务
  Future<void> initialize() async {
    _storage = await StorageService.init();
    await _loadSettings();
  }

  /// 获取当前设置
  PersonalizationSettings get settings => _settings;

  /// 加载设置
  Future<void> _loadSettings() async {
    try {
      // 这里需要实现从存储加载设置的逻辑
      // 暂时使用默认设置
      _settings = const PersonalizationSettings();
      debugPrint('✅ 个性化设置已加载');
    } catch (error) {
      debugPrint('❌ 加载个性化设置失败: $error');
      _settings = const PersonalizationSettings();
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      // 这里需要实现保存设置到存储的逻辑
      debugPrint('✅ 个性化设置已保存');
    } catch (error) {
      debugPrint('❌ 保存个性化设置失败: $error');
    }
  }

  /// 更新智能引导开关
  Future<void> updateSmartGuidance(bool enabled) async {
    _settings = _settings.copyWith(enableSmartGuidance: enabled);
    await _saveSettings();
    debugPrint('🧠 智能引导已${enabled ? "启用" : "禁用"}');
  }

  /// 更新激励消息开关
  Future<void> updateMotivationalMessages(bool enabled) async {
    _settings = _settings.copyWith(enableMotivationalMessages: enabled);
    await _saveSettings();
    debugPrint('💪 激励消息已${enabled ? "启用" : "禁用"}');
  }

  /// 更新教育提示开关
  Future<void> updateEducationalTips(bool enabled) async {
    _settings = _settings.copyWith(enableEducationalTips: enabled);
    await _saveSettings();
    debugPrint('📚 教育提示已${enabled ? "启用" : "禁用"}');
  }

  /// 更新引导频率
  Future<void> updateGuidanceFrequency(int minutes) async {
    if (minutes < 5 || minutes > 120) {
      debugPrint('⚠️ 引导频率必须在5-120分钟之间');
      return;
    }
    
    _settings = _settings.copyWith(guidanceFrequency: minutes);
    await _saveSettings();
    debugPrint('⏰ 引导频率已更新为${minutes}分钟');
  }

  /// 更新偏好活动
  Future<void> updatePreferredActivities(List<String> activities) async {
    _settings = _settings.copyWith(preferredActivities: activities);
    await _saveSettings();
    debugPrint('🎯 偏好活动已更新: ${activities.join(", ")}');
  }

  /// 更新引导风格
  Future<void> updateGuidanceStyle(String style) async {
    if (!['gentle', 'firm', 'balanced'].contains(style)) {
      debugPrint('⚠️ 无效的引导风格: $style');
      return;
    }
    
    _settings = _settings.copyWith(guidanceStyle: style);
    await _saveSettings();
    debugPrint('🎨 引导风格已更新为: $style');
  }

  /// 更新夜间模式
  Future<void> updateNightMode(bool enabled) async {
    _settings = _settings.copyWith(enableNightMode: enabled);
    await _saveSettings();
    debugPrint('🌙 夜间模式已${enabled ? "启用" : "禁用"}');
  }

  /// 更新工作时间模式
  Future<void> updateWorkTimeMode(bool enabled) async {
    _settings = _settings.copyWith(enableWorkTimeMode: enabled);
    await _saveSettings();
    debugPrint('💼 工作时间模式已${enabled ? "启用" : "禁用"}');
  }

  /// 更新应用特定设置
  Future<void> updateAppSpecificSetting(String packageName, bool enabled) async {
    final newSettings = Map<String, bool>.from(_settings.appSpecificSettings);
    newSettings[packageName] = enabled;
    
    _settings = _settings.copyWith(appSpecificSettings: newSettings);
    await _saveSettings();
    debugPrint('📱 应用特定设置已更新: $packageName -> $enabled');
  }

  /// 获取应用特定设置
  bool getAppSpecificSetting(String packageName) {
    return _settings.appSpecificSettings[packageName] ?? true;
  }

  /// 重置所有设置
  Future<void> resetSettings() async {
    await trackPerformance('reset_personalization_settings', () async {
      _settings = const PersonalizationSettings();
      await _saveSettings();
      debugPrint('🔄 个性化设置已重置为默认值');
    });
  }

  /// 获取推荐的引导策略
  String getRecommendedStrategy() {
    final now = DateTime.now();
    final hour = now.hour;
    
    // 夜间模式
    if (_settings.enableNightMode && (hour >= 22 || hour < 6)) {
      return 'gentle';
    }
    
    // 工作时间模式
    if (_settings.enableWorkTimeMode && hour >= 9 && hour < 18) {
      return 'firm';
    }
    
    // 返回用户偏好的风格
    return _settings.guidanceStyle;
  }

  /// 检查是否应该显示引导
  bool shouldShowGuidance(String packageName, DateTime lastGuidanceTime) {
    // 检查应用特定设置
    if (!getAppSpecificSetting(packageName)) {
      return false;
    }
    
    // 检查时间间隔
    final timeSinceLastGuidance = DateTime.now().difference(lastGuidanceTime);
    final requiredInterval = Duration(minutes: _settings.guidanceFrequency);
    
    return timeSinceLastGuidance >= requiredInterval;
  }

  /// 获取个性化活动建议
  List<String> getPersonalizedActivities() {
    if (_settings.preferredActivities.isNotEmpty) {
      return _settings.preferredActivities;
    }
    
    // 返回默认活动
    return [
      '💧 喝一杯水',
      '👀 看看远方放松眼睛',
      '🤸 做几个简单运动',
      '🧘 进行深呼吸',
      '📝 记录当前想法',
    ];
  }

  /// 获取设置摘要
  Map<String, dynamic> getSettingsSummary() {
    return {
      'smart_guidance': _settings.enableSmartGuidance,
      'motivational_messages': _settings.enableMotivationalMessages,
      'educational_tips': _settings.enableEducationalTips,
      'guidance_frequency_minutes': _settings.guidanceFrequency,
      'guidance_style': _settings.guidanceStyle,
      'night_mode': _settings.enableNightMode,
      'work_time_mode': _settings.enableWorkTimeMode,
      'preferred_activities_count': _settings.preferredActivities.length,
      'app_specific_settings_count': _settings.appSpecificSettings.length,
    };
  }
}