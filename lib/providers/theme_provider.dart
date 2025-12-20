import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'ru';

  ThemeMode get themeMode => _themeMode;
  String get locale => _locale;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Загрузка настроек при старте
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? true;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = prefs.getString('language') ?? 'ru';
    notifyListeners();
  }

  // Переключение темы
  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDark', isDark);
  }

  // Смена языка
  void setLanguage(String langCode) async {
    _locale = langCode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
  }
}