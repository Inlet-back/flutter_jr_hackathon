import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ChineseTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        // 文字の色
        primary: AppColors.chineseText,
        secondary: AppColors.chineseAccent,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.chineseText),
        bodyMedium: TextStyle(color: AppColors.chineseText),
      ),
    );
  }
}
