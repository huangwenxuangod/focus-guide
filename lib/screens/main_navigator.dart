import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/monitoring_provider.dart';
import '../widgets/guide_overlay.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'guide_screen.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
    const GuideScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // 引导覆盖层监听器
          Consumer<MonitoringProvider>(
            builder: (context, monitoring, child) {
              // 当需要显示引导覆盖层时，显示它
              if (monitoring.shouldShowGuideOverlay) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (monitoring.shouldShowGuideOverlay && 
                      !GuideOverlayManager.instance.isShowing) {
                    // 使用监控提供者中的当前应用信息
                    GuideOverlayManager.instance.showGuideOverlay(
                      context,
                      monitoring.currentAppName,
                      monitoring.currentPackageName,
                    );
                  }
                });
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: '引导',
          ),
        ],
      ),
    );
  }
}