import 'package:flutter/material.dart';
import 'app.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化存储服务
  final storageService = await StorageService.init();
  
  runApp(FocusGuideApp(storageService: storageService));
}