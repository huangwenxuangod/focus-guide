import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/permission_provider.dart';
import 'providers/stats_provider.dart';
import 'services/storage_service.dart';
import 'screens/main_navigator.dart';
import 'widgets/guide_overlay.dart';
import 'theme/app_theme.dart';

class FocusGuideApp extends StatefulWidget {
  final StorageService storageService;
  
  const FocusGuideApp({
    super.key,
    required this.storageService,
  });

  @override
  State<FocusGuideApp> createState() => _FocusGuideAppState();
}

class _FocusGuideAppState extends State<FocusGuideApp> {
  late MonitoringProvider _monitoringProvider;
  late PermissionProvider _permissionProvider;
  late StatsProvider _statsProvider;

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  void _initializeProviders() {
    _monitoringProvider = MonitoringProvider(widget.storageService);
    _permissionProvider = PermissionProvider(widget.storageService);
    _statsProvider = StatsProvider(widget.storageService);
    
    // 设置 Provider 之间的依赖关系
    _monitoringProvider.setStatsProvider(_statsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _monitoringProvider),
        ChangeNotifierProvider.value(value: _permissionProvider),
        ChangeNotifierProvider.value(value: _statsProvider),
      ],
      child: MaterialApp(
        title: '专注引导',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const MainNavigator(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }

}