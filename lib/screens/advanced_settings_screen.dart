import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_widgets.dart';
import '../services/personalization_service.dart';
import '../services/analytics_service.dart';
import '../services/smart_guidance_service.dart';

/// 高级设置页面
class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late PersonalizationService _personalizationService;
  late AnalyticsService _analyticsService;
  PersonalizationSettings _settings = const PersonalizationSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _initializeServices();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    _personalizationService = PersonalizationService.instance;
    _analyticsService = AnalyticsService.instance;
    
    await _personalizationService.initialize();
    await _analyticsService.initialize();
    
    setState(() {
      _settings = _personalizationService.settings;
      _isLoading = false;
    });
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('高级设置'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedWidgets.fadeInContainer(
                  delay: const Duration(milliseconds: 0),
                  child: _buildSmartGuidanceSection(),
                ),
                const SizedBox(height: 24),
                AnimatedWidgets.fadeInContainer(
                  delay: const Duration(milliseconds: 100),
                  child: _buildPersonalizationSection(),
                ),
                const SizedBox(height: 24),
                AnimatedWidgets.fadeInContainer(
                  delay: const Duration(milliseconds: 200),
                  child: _buildAnalyticsSection(),
                ),
                const SizedBox(height: 24),
                AnimatedWidgets.fadeInContainer(
                  delay: const Duration(milliseconds: 300),
                  child: _buildAdvancedOptionsSection(),
                ),
                const SizedBox(height: 32),
                AnimatedWidgets.fadeInContainer(
                  delay: const Duration(milliseconds: 400),
                  child: _buildActionButtons(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSmartGuidanceSection() {
    return _buildSection(
      title: '🧠 智能引导',
      children: [
        _buildSwitchTile(
          title: '启用智能引导',
          subtitle: '基于使用模式提供个性化建议',
          value: _settings.enableSmartGuidance,
          onChanged: (value) async {
            await _personalizationService.updateSmartGuidance(value);
            _updateSettings();
          },
        ),
        _buildSwitchTile(
          title: '激励消息',
          subtitle: '显示鼓励和动机相关的消息',
          value: _settings.enableMotivationalMessages,
          onChanged: (value) async {
            await _personalizationService.updateMotivationalMessages(value);
            _updateSettings();
          },
        ),
        _buildSwitchTile(
          title: '教育提示',
          subtitle: '提供数字健康相关的知识和技巧',
          value: _settings.enableEducationalTips,
          onChanged: (value) async {
            await _personalizationService.updateEducationalTips(value);
            _updateSettings();
          },
        ),
      ],
    );
  }

  Widget _buildPersonalizationSection() {
    return _buildSection(
      title: '🎨 个性化设置',
      children: [
        _buildSliderTile(
          title: '引导频率',
          subtitle: '${_settings.guidanceFrequency}分钟',
          value: _settings.guidanceFrequency.toDouble(),
          min: 5,
          max: 120,
          divisions: 23,
          onChanged: (value) async {
            await _personalizationService.updateGuidanceFrequency(value.round());
            _updateSettings();
          },
        ),
        _buildDropdownTile(
          title: '引导风格',
          subtitle: _getGuidanceStyleDescription(_settings.guidanceStyle),
          value: _settings.guidanceStyle,
          items: const [
            DropdownMenuItem(value: 'gentle', child: Text('温和')),
            DropdownMenuItem(value: 'balanced', child: Text('平衡')),
            DropdownMenuItem(value: 'firm', child: Text('坚定')),
          ],
          onChanged: (value) async {
            if (value != null) {
              await _personalizationService.updateGuidanceStyle(value);
              _updateSettings();
            }
          },
        ),
        _buildSwitchTile(
          title: '夜间模式',
          subtitle: '22:00-06:00期间使用温和引导',
          value: _settings.enableNightMode,
          onChanged: (value) async {
            await _personalizationService.updateNightMode(value);
            _updateSettings();
          },
        ),
        _buildSwitchTile(
          title: '工作时间模式',
          subtitle: '09:00-18:00期间使用更严格的引导',
          value: _settings.enableWorkTimeMode,
          onChanged: (value) async {
            await _personalizationService.updateWorkTimeMode(value);
            _updateSettings();
          },
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection() {
    return _buildSection(
      title: '📊 数据分析',
      children: [
        _buildActionTile(
          title: '查看使用模式',
          subtitle: '分析不同时间段的应用使用习惯',
          icon: Icons.timeline,
          onTap: () => _showUsagePatterns(),
        ),
        _buildActionTile(
          title: '进步趋势',
          subtitle: '查看最近的改进情况和趋势',
          icon: Icons.trending_up,
          onTap: () => _showProgressTrends(),
        ),
        _buildActionTile(
          title: '个人洞察',
          subtitle: '获取基于数据的个性化建议',
          icon: Icons.lightbulb_outline,
          onTap: () => _showPersonalInsights(),
        ),
        _buildActionTile(
          title: '周报',
          subtitle: '生成详细的周度使用报告',
          icon: Icons.assessment,
          onTap: () => _generateWeeklyReport(),
        ),
      ],
    );
  }

  Widget _buildAdvancedOptionsSection() {
    return _buildSection(
      title: '⚙️ 高级选项',
      children: [
        _buildActionTile(
          title: '偏好活动设置',
          subtitle: '自定义推荐的替代活动',
          icon: Icons.favorite_outline,
          onTap: () => _showPreferredActivities(),
        ),
        _buildActionTile(
          title: '应用特定设置',
          subtitle: '为不同应用设置个性化规则',
          icon: Icons.apps,
          onTap: () => _showAppSpecificSettings(),
        ),
        _buildActionTile(
          title: '导出数据',
          subtitle: '导出使用数据和设置',
          icon: Icons.download,
          onTap: () => _exportData(),
        ),
        _buildActionTile(
          title: '重置设置',
          subtitle: '恢复所有设置到默认值',
          icon: Icons.restore,
          onTap: () => _showResetDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _saveAndExit(),
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: Text(subtitle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppTheme.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getGuidanceStyleDescription(String style) {
    switch (style) {
      case 'gentle':
        return '温和友好的提醒方式';
      case 'firm':
        return '坚定明确的引导方式';
      case 'balanced':
        return '平衡适中的引导方式';
      default:
        return '未知风格';
    }
  }

  void _updateSettings() {
    setState(() {
      _settings = _personalizationService.settings;
    });
  }

  Future<void> _showUsagePatterns() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用模式分析'),
        content: const Text('正在分析您的使用模式...\n\n这个功能将显示您在不同时间段的应用使用习惯。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showProgressTrends() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('进步趋势'),
        content: const Text('正在分析您的进步趋势...\n\n这个功能将显示您最近的改进情况和发展趋势。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPersonalInsights() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('个人洞察'),
        content: const Text('正在生成个人洞察...\n\n这个功能将基于您的数据提供个性化的建议和洞察。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateWeeklyReport() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('周报生成'),
        content: const Text('正在生成您的周度报告...\n\n这个功能将创建一份详细的使用分析报告。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showPreferredActivities() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('偏好活动设置'),
        content: const Text('在这里您可以自定义推荐的替代活动列表。\n\n当触发引导时，系统将优先推荐您设置的活动。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAppSpecificSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('应用特定设置'),
        content: const Text('在这里您可以为不同的应用设置个性化的引导规则。\n\n例如，为工作应用设置更严格的引导，为娱乐应用设置更温和的提醒。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: const Text('这个功能将导出您的使用数据和设置配置。\n\n导出的数据可以用于备份或迁移到其他设备。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResetDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置设置'),
        content: const Text('确定要重置所有设置到默认值吗？\n\n这个操作无法撤销，所有个性化配置都将丢失。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _personalizationService.resetSettings();
              _updateSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置已重置')),
              );
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAndExit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('设置已保存')),
    );
    Navigator.pop(context);
  }
}