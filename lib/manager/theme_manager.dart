import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _useDynamicColorKey = 'use_dynamic_color';

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  SharedPreferences? _prefs;

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;

  ThemeManager() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();

    final themeModeIndex = _prefs?.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[themeModeIndex];

    _useDynamicColor = _prefs?.getBool(_useDynamicColorKey) ?? true;

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs?.setInt(_themeModeKey, mode.index);
    notifyListeners();
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    await _prefs?.setBool(_useDynamicColorKey, value);
    notifyListeners();
  }

  String getThemeModeLabel() {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}