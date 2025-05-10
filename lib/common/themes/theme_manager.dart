import 'package:flutter/material.dart';
import 'crystal_theme.dart';
import 'chinese_theme.dart';

class ThemeManager extends ChangeNotifier {
  ThemeData _currentTheme = CrystalTheme.theme;

  ThemeData get currentTheme => _currentTheme;
  String get currentThemeName {
    if (_currentTheme == CrystalTheme.theme) {
      return 'CrystalTheme';
    } else if (_currentTheme == ChineseTheme.theme) {
      return 'ChineseTheme';
    }
    return 'Unknown';
  }

  void setCrystalTheme() {
    _currentTheme = CrystalTheme.theme;
    notifyListeners();
  }

  void setChineseTheme() {
    _currentTheme = ChineseTheme.theme;
    notifyListeners();
  }
}
