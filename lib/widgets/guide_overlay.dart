import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/stats_provider.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/activity_widgets.dart';

/// 引导覆盖层 - 全屏引导界面
class GuideOverlay extends StatefulWidget {
  final String appName;
  final String packageName;
  final VoidCallback onDismiss;
  
  const GuideOverlay({
    super.key,
    required this.appName,
    required this.packageName,
    required this.onDismiss,
  });
  
  @override
  State<GuideOverlay> createState() => _GuideOverlayState();
}

class _GuideOverlayState extends State<GuideOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isActivityInProgress = false;
  String? _selectedActivity;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化动画控制器
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    // 创建动画
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    // 启动入场动画
    _fadeController.forward();
    _scaleController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    // 优化：简化动画，减少重绘
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildOverlayContent(context),
      ),
    );
  }
  
  Widget _buildOverlayContent(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeader(context),
              const SizedBox(height: 32),
              if (!_isActivityInProgress) ..._buildActivitySelection(context),
              if (_isActivityInProgress) _buildActivityInProgress(context),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            '温和提醒',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '检测到您正在打开 ${widget.appName}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 8),
          Text(
            '不如先做个小活动，让身心更加放松？',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 600.ms),
        ],
      ),
    );
  }
  
  List<Widget> _buildActivitySelection(BuildContext context) {
    return [
      const Text(
        '选择一个替代活动',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ).animate().fadeIn(delay: 300.ms),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: _buildActivityOption(
              context,
              'breathing',
              Icons.air,
              '深呼吸',
              '1分钟',
              Colors.blue,
              '缓解压力，放松身心',
            ).animate().slideX(begin: -0.3, delay: 400.ms),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActivityOption(
              context,
              'water',
              Icons.local_drink,
              '喝水',
              '30秒',
              Colors.cyan,
              '补充水分，保持健康',
            ).animate().slideY(begin: 0.3, delay: 500.ms),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActivityOption(
              context,
              'stretch',
              Icons.accessibility_new,
              '伸展',
              '2分钟',
              Colors.green,
              '活动筋骨，提升活力',
            ).animate().slideX(begin: 0.3, delay: 600.ms),
          ),
        ],
      ),
    ];
  }
  
  Widget _buildActivityOption(
    BuildContext context,
    String activityId,
    IconData icon,
    String title,
    String duration,
    Color color,
    String description,
  ) {
    final isSelected = _selectedActivity == activityId;
    return GestureDetector(
      onTap: () => _selectActivity(activityId),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              duration,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityInProgress(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '正在进行：$_selectedActivity',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            '请跟随指导完成活动',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _dismissOverlay,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('稍后再说'),
          ).animate().slideX(begin: -0.5, delay: 800.ms),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _selectedActivity != null ? () => _startActivity(_selectedActivity!, _selectedActivity!) : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('开始活动'),
          ).animate().slideX(begin: 0.5, delay: 800.ms),
        ),
      ],
    );
  }
  
  void _selectActivity(String activityId) {
    setState(() {
      _selectedActivity = activityId;
    });
  }
  
  void _startActivity(String activityId, String activityName) {
    setState(() {
      _isActivityInProgress = true;
    });
    
    // 显示对应的活动组件
    _showActivityWidget(context, activityId);
  }
  
  void _showActivityWidget(BuildContext context, String activityId) {
    Widget activityWidget;
    
    switch (activityId) {
      case 'breathing':
        activityWidget = BreathingActivity(
          onComplete: _completeActivity,
          onCancel: _cancelActivity,
        );
        break;
      case 'water':
        activityWidget = DrinkWaterActivity(
          onComplete: _completeActivity,
          onCancel: _cancelActivity,
        );
        break;
      case 'stretch':
        activityWidget = StretchActivity(
          onComplete: _completeActivity,
          onCancel: _cancelActivity,
        );
        break;
      default:
        return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: activityWidget,
      ),
    ).then((_) {
      // 对话框关闭后重置状态
      if (mounted) {
        setState(() {
          _isActivityInProgress = false;
        });
      }
    });
  }
  
  void _cancelActivity() {
    if (mounted) {
      Navigator.of(context).pop(); // 关闭活动对话框
    }
  }
  
  void _completeActivity() {
    if (mounted) {
      // 增加活动完成统计
      context.read<StatsProvider>().incrementActivitiesCompleted();
      
      // 关闭活动对话框
      Navigator.of(context).pop();
      
      // 显示完成提示
      _showCompletionMessage();
      
      // 延迟关闭覆盖层
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _dismissOverlay();
        }
      });
    }
  }
  
  void _showCompletionMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('太棒了！您完成了$_selectedActivity活动'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  void _dismissOverlay() {
    if (mounted) {
      // 直接关闭，不播放动画避免问题
      context.read<MonitoringProvider>().hideGuideOverlay();
      widget.onDismiss();
    }
  }
}

/// 覆盖层管理器 - 管理引导覆盖层的显示和隐藏
class GuideOverlayManager {
  static GuideOverlayManager? _instance;
  static GuideOverlayManager get instance => _instance ??= GuideOverlayManager._();
  
  GuideOverlayManager._();
  
  OverlayEntry? _currentOverlay;
  bool _isShowing = false;
  
  /// 显示引导覆盖层
  void showGuideOverlay(
    BuildContext context,
    String appName,
    String packageName,
  ) {
    if (_isShowing) {
      debugPrint('⚠️ 引导覆盖层已在显示中');
      return;
    }
    
    _isShowing = true;
    
    _currentOverlay = OverlayEntry(
      builder: (context) => GuideOverlay(
        appName: appName,
        packageName: packageName,
        onDismiss: hideGuideOverlay,
      ),
    );
    
    Overlay.of(context).insert(_currentOverlay!);
    debugPrint('🎯 显示引导覆盖层: $appName');
  }
  
  /// 隐藏引导覆盖层
  void hideGuideOverlay() {
    if (!_isShowing || _currentOverlay == null) return;
    
    _currentOverlay!.remove();
    _currentOverlay = null;
    _isShowing = false;
    
    // 通知监控提供者更新状态
    // 这里需要传入context来访问provider
    
    debugPrint('✅ 隐藏引导覆盖层');
  }
  
  /// 检查是否正在显示
  bool get isShowing => _isShowing;
  
  /// 强制清理
  void dispose() {
    hideGuideOverlay();
    _instance = null;
  }
}