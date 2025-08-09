import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/monitoring_provider.dart';
import 'providers/permission_provider.dart';
import 'providers/stats_provider.dart';
import 'services/storage_service.dart';
import 'screens/main_navigator.dart';

class FocusGuideApp extends StatelessWidget {
  final StorageService storageService;
  
  const FocusGuideApp({
    super.key,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MonitoringProvider(storageService)),
        ChangeNotifierProvider(create: (_) => PermissionProvider(storageService)),
        ChangeNotifierProvider(create: (_) => StatsProvider(storageService)),
      ],
      child: MaterialApp(
        title: '专注引导',
        theme: _buildTheme(),
        home: const MainNavigator(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
  // 一个颜色的配置层
  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4), // 专注紫色
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}