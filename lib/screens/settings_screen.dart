import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/permission_provider.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/common_widgets.dart';
import '../utils/debouncer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _switchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  @override
  void dispose() {
    _switchDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPermissionSection(context),
          const SizedBox(height: 24),
          _buildAppSelectionSection(context),
          const SizedBox(height: 24),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<PermissionProvider>(
          builder: (context, permission, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(title: '权限设置'),
                const SizedBox(height: 16),
                PermissionItem(
                  title: '应用使用统计',
                  description: '检测应用启动和使用情况',
                  icon: Icons.analytics,
                  isGranted: permission.isPermissionGranted('usage_stats'),
                  onTap: () => _requestPermission(context, 'usage_stats'),
                ),
                const Divider(),
                PermissionItem(
                  title: '系统覆盖层',
                  description: '显示引导页面覆盖层',
                  icon: Icons.layers,
                  isGranted: permission.isPermissionGranted('system_alert'),
                  onTap: () => _requestPermission(context, 'system_alert'),
                ),
                const Divider(),
                PermissionItem(
                  title: '后台服务',
                  description: '在后台持续监控应用使用',
                  icon: Icons.settings_applications,
                  isGranted: permission.isPermissionGranted('foreground_service'),
                  onTap: () => _requestPermission(context, 'foreground_service'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => permission.requestAllPermissions(),
                    icon: const Icon(Icons.security),
                    label: const Text('一键设置所有权限'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _requestPermission(BuildContext context, String permissionType) {
    // TODO: 实现特定权限请求
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('请求$permissionType权限...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAppSelectionSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: '监控应用选择',
              subtitle: '选择需要温和引导的应用',
            ),
            const SizedBox(height: 16),
            Consumer<MonitoringProvider>(
              builder: (context, monitoring, child) {
                return Column(
                  children: monitoring.apps.map((app) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      secondary: CircleAvatar(
                        backgroundColor: app.isEnabled ? Colors.blue : Colors.grey,
                        child: Icon(
                          _getAppIcon(app.packageName),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(app.displayName),
                      value: app.isEnabled,
                      onChanged: (value) {
                        _switchDebouncer.run(() => monitoring.updateAppStatus(app.packageName, value));
                      },
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

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: '关于应用'),
            const SizedBox(height: 16),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.info_outline),
              title: Text('版本'),
              subtitle: Text('v0.1.0 (MVP)'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.psychology),
              title: Text('核心理念'),
              subtitle: Text('温和引导替代强制阻止'),
            ),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.privacy_tip),
              title: Text('隐私保护'),
              subtitle: Text('所有数据仅本地存储，不上传'),
            ),
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
        return Icons.play_circle;
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