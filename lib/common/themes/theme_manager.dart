import 'package:flutter/material.dart';
import 'crystal_theme.dart';
import 'chinese_theme.dart';

class ThemeManager extends ChangeNotifier {
  ThemeData _currentTheme = CrystalTheme.theme;

  ThemeData get currentTheme => _currentTheme;

  void setCrystalTheme() {
    _currentTheme = CrystalTheme.theme;
    notifyListeners();
  }

  void setChineseTheme() {
    _currentTheme = ChineseTheme.theme;
    notifyListeners();
  }
}
