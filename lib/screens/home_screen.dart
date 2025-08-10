import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/monitoring_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/common_widgets.dart';
import '../widgets/animated_widgets.dart';
import '../utils/debouncer.dart';
import '../theme/app_theme.dart';

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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          '专注引导',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<MonitoringProvider>().refreshData();
          await context.read<StatsProvider>().refreshStats();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(context),
              const SizedBox(height: AppTheme.spacingL),
              _buildMonitorStatusCard(context),
              const SizedBox(height: AppTheme.spacingM),
              _buildTodayStatsCard(context),
              const SizedBox(height: AppTheme.spacingM),
              _buildMonitoredAppsSection(context),
              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return AnimatedWidgets.fadeInContainer(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedWidgets.scaleIn(
              delay: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingM),
            Expanded(
              child: AnimatedWidgets.slideInRight(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '专注每一刻',
                      style: AppTheme.headingSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '温和引导，健康使用',
                      style: AppTheme.bodyMedium.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitorStatusCard(BuildContext context) {
    return Consumer<MonitoringProvider>(
      builder: (context, monitoring, child) {
        return AnimatedWidgets.fadeInContainer(
          delay: const Duration(milliseconds: 400),
          child: AnimatedContainer(
            duration: AppTheme.animationMedium,
            curve: AppTheme.animationCurve,
            child: StatusCard(
              icon: monitoring.isEnabled ? Icons.visibility : Icons.visibility_off,
              title: monitoring.isEnabled ? '监控已开启' : '监控已关闭',
              subtitle: monitoring.isEnabled ? '正在温和引导您的应用使用' : '点击开始监控',
              isActive: monitoring.isEnabled,
              trailing: Switch(
                value: monitoring.isEnabled,
                onChanged: (value) => _switchDebouncer.run(() => monitoring.toggleMonitoring()),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayStatsCard(BuildContext context) {
    return AnimatedWidgets.fadeInContainer(
      delay: const Duration(milliseconds: 600),
      child: Card(
        elevation: 4,
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.primaryColor.withOpacity(0.02),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedWidgets.slideInLeft(
                delay: const Duration(milliseconds: 700),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spacingS),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Text(
                      '今日统计',
                      style: AppTheme.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              Consumer<StatsProvider>(
                builder: (context, stats, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: AnimatedWidgets.staggeredListItem(
                          index: 0,
                          baseDelay: const Duration(milliseconds: 800),
                          child: _buildStatCard(
                            icon: Icons.block,
                            label: '引导次数',
                            value: stats.guidanceCount.toString(),
                            color: AppTheme.primaryColor,
                            gradient: AppTheme.primaryGradient,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Expanded(
                        child: AnimatedWidgets.staggeredListItem(
                          index: 1,
                          baseDelay: const Duration(milliseconds: 800),
                          child: _buildStatCard(
                            icon: Icons.self_improvement,
                            label: '完成活动',
                            value: stats.activitiesCompleted.toString(),
                            color: AppTheme.secondaryColor,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required LinearGradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        gradient: gradient.colors.map((c) => c.withOpacity(0.08)).toList().length == 2
            ? LinearGradient(
                colors: gradient.colors.map((c) => c.withOpacity(0.08)).toList(),
              )
            : null,
        color: gradient.colors.map((c) => c.withOpacity(0.08)).toList().length != 2
            ? color.withOpacity(0.08)
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingS),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoredAppsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.apps,
              color: AppTheme.primaryColor,
              size: 24,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              '监控应用',
              style: AppTheme.headingSmall,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Consumer<MonitoringProvider>(
          builder: (context, monitoring, child) {
            return Column(
              children: monitoring.apps.asMap().entries.map((entry) {
                final index = entry.key;
                final app = entry.value;
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + (index * 50)),
                  curve: AppTheme.animationCurve,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
                    child: AppListTile(
                      name: app.displayName,
                      icon: _getAppIcon(app.packageName),
                      isEnabled: app.isEnabled,
                      onTap: () => monitoring.updateAppStatus(app.packageName, !app.isEnabled),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
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