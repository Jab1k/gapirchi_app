// lib/providers/settings_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('ru');

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;

  SettingsProvider() {
    _loadSettings();
  }

  void toggleTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', isDark);
  }

  void changeLanguage(String code) async {
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('language', code);
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDark') ?? false;
    final lang = prefs.getString('language') ?? 'ru';
    
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _locale = Locale(lang);
    notifyListeners();
  }
}