import 'package:flutter/material.dart';
import '../constants/colors.dart';

class CrystalTheme {
  static ThemeData get theme {
    return ThemeData(
      colorScheme: ColorScheme.light(
        // 文字の色
        primary: AppColors.chineseText,
        secondary: AppColors.crystalAccent,
        background: AppColors.background,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: AppColors.crystalText),
        bodyMedium: TextStyle(color: AppColors.crystalText),
      ),
    );
  }
}
