import 'package:flutter/material.dart';
import 'package:flutter_jr_hackathon/route/router.dart';

void main() {
  runApp(MyApp());
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
