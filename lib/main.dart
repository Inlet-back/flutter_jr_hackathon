import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jr_hackathon/route/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 画面を縦向きに固定する
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  // 確認ログ
  // setupLogging(showDebugLogs: true);

  // アラームの初期化
  await Alarm.init();

  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // テーマ変更時に再描画を強制
    AppRouter.themeManager.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      theme: AppRouter.themeManager.currentTheme, // 現在のテーマを適用
      routerConfig: AppRouter.router, // GoRouterを設定
    );
  }
}
