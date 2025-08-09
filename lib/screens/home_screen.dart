import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/common_widgets.dart';
import '../utils/debouncer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
        title: const Text('专注引导'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonitorStatusCard(context),
            const SizedBox(height: 16),
            _buildTodayStatsCard(context),
            const SizedBox(height: 16),
            _buildMonitoredAppsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorStatusCard(BuildContext context) {
    return Consumer<MonitoringProvider>(
      builder: (context, monitoring, child) {
        return StatusCard(
          icon: monitoring.isEnabled ? Icons.visibility : Icons.visibility_off,
          title: monitoring.isEnabled ? '监控已开启' : '监控已关闭',
          subtitle: monitoring.isEnabled ? '正在温和引导您的应用使用' : '点击开始监控',
          isActive: monitoring.isEnabled,
          trailing: Switch(
            value: monitoring.isEnabled,
            onChanged: (value) => _switchDebouncer.run(() => monitoring.toggleMonitoring()),
          ),
        );
      },
    );
  }

  Widget _buildTodayStatsCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(title: '今日统计'),
            const SizedBox(height: 12),
            Consumer<StatsProvider>(
              builder: (context, stats, child) {
                return Row(
                  children: [
                    Expanded(
                      child: StatItem(
                        icon: Icons.block,
                        label: '引导次数',
                        value: stats.guidanceCount.toString(),
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatItem(
                        icon: Icons.self_improvement,
                        label: '完成活动',
                        value: stats.activitiesCompleted.toString(),
                        color: Colors.green,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoredAppsSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: '监控应用'),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<MonitoringProvider>(
              builder: (context, monitoring, child) {
                return ListView.builder(
                  itemCount: monitoring.apps.length,
                  itemBuilder: (context, index) {
                    final app = monitoring.apps[index];
                    return AppListTile(
                      name: app.displayName,
                      icon: _getAppIcon(app.packageName),
                      isEnabled: app.isEnabled,
                    );
                  },
                );
              },
            ),
          ),
        ],
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