import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/permission_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../theme/app_theme.dart';
import '../utils/debouncer.dart';
import 'advanced_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _switchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));
  final _permissionDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void dispose() {
    _switchDebouncer.dispose();
    _permissionDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          '设置',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<PermissionProvider>().refreshPermissions();
        },
        child: ListView(
          padding: EdgeInsets.all(AppTheme.spacingL),
          children: [
            _buildPermissionSection(context),
            SizedBox(height: AppTheme.spacingXL),
            _buildAppSelectionSection(context),
            SizedBox(height: AppTheme.spacingXL),
            _buildAdvancedSettingsSection(context),
            SizedBox(height: AppTheme.spacingXL),
            _buildAboutSection(context),
            SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionSection(BuildContext context) {
    return Consumer<PermissionProvider>(
      builder: (context, permissions, child) {
        final permissionItems = [
           {
             'title': '应用使用统计',
             'description': '监控应用启动和使用时间',
             'icon': Icons.analytics_outlined,
             'type': 'usage_stats',
             'priority': 'high',
           },
           {
             'title': '系统覆盖层',
             'description': '显示引导页面覆盖层',
             'icon': Icons.layers_outlined,
             'type': 'system_alert',
             'priority': 'high',
           },
           {
             'title': '后台服务',
             'description': '保持应用监控服务运行',
             'icon': Icons.settings_applications_outlined,
             'type': 'foreground_service',
             'priority': 'medium',
           },
         ];

        return AnimatedWidgets.slideInLeft(
          delay: const Duration(milliseconds: 200),
          child: Container(
            decoration: AppTheme.cardDecoration,
            padding: EdgeInsets.all(AppTheme.spacingL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security_outlined,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    SizedBox(width: AppTheme.spacingM),
                    Text(
                      '权限管理',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacingL),
                ...permissionItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return AnimatedWidgets.staggeredListItem(
                    index: index,
                    baseDelay: const Duration(milliseconds: 300),
                    child: Column(
                      children: [
                        PermissionItem(
                           title: item['title'] as String,
                           description: item['description'] as String,
                           icon: item['icon'] as IconData,
                           isGranted: permissions.isPermissionGranted(item['type'] as String),
                           onTap: () => _permissionDebouncer.run(() => 
                             permissions.requestPermission(item['type'] as String)),
                           priority: item['priority'] as String,
                         ),
                        if (index < permissionItems.length - 1)
                          SizedBox(height: AppTheme.spacingM),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppSelectionSection(BuildContext context) {
    return AnimatedWidgets.slideInLeft(
      delay: const Duration(milliseconds: 600),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.apps_outlined,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacingM),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '监控应用选择',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Text(
                      '选择需要温和引导的应用',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            Consumer<MonitoringProvider>(
              builder: (context, monitoring, child) {
                return Column(
                  children: monitoring.apps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final app = entry.value;
                    return AnimatedWidgets.staggeredListItem(
                      index: index,
                      baseDelay: const Duration(milliseconds: 700),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        secondary: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          child: CircleAvatar(
                            backgroundColor: app.isEnabled ? AppTheme.primaryColor : AppTheme.textLight,
                            child: Icon(
                              _getAppIcon(app.packageName),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          app.displayName,
                          style: AppTheme.bodyLarge.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: app.isEnabled,
                        onChanged: (value) {
                          _switchDebouncer.run(() => monitoring.updateAppStatus(app.packageName, value));
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSettingsSection(BuildContext context) {
    return AnimatedWidgets.slideInLeft(
      delay: const Duration(milliseconds: 800),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.tune,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  '高级设置',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                '智能引导与个性化',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                '配置智能引导、个性化设置和数据分析',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdvancedSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final aboutItems = [
      {
        'icon': Icons.info_outline,
        'title': '版本',
        'subtitle': 'v0.1.0 (MVP)',
      },
      {
        'icon': Icons.psychology,
        'title': '核心理念',
        'subtitle': '温和引导替代强制阻止',
      },
      {
        'icon': Icons.privacy_tip,
        'title': '隐私保护',
        'subtitle': '所有数据仅本地存储，不上传',
      },
    ];

    return AnimatedWidgets.slideInLeft(
      delay: const Duration(milliseconds: 1000),
      child: Container(
        decoration: AppTheme.cardDecoration,
        padding: EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: AppTheme.spacingM),
                Text(
                  '关于应用',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacingL),
            ...aboutItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return AnimatedWidgets.staggeredListItem(
                index: index,
                baseDelay: const Duration(milliseconds: 1100),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item['icon'] as IconData,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    item['title'] as String,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    item['subtitle'] as String,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  IconData _getAppIcon(String packageName) {
    switch (packageName) {
      case 'com.tencent.mm':
        return Icons.chat;
      case 'com.ss.android.ugc.aweme':
        return Icons.video_library;
      case 'com.taobao.taobao':
        return Icons.shopping_cart;
      case 'com.sina.weibo':
        return Icons.public;
      case 'com.tencent.tmgp.sgame':
        return Icons.sports_esports;
      default:
        return Icons.apps;
    }
  }
}