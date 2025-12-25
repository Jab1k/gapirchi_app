import 'package:flutter/material.dart';

class AppColors {
  static const Color darkBg = Color(0xFF0a2a3e);    // Eng to'q fon
  static const Color cardBg = Color(0xFF1a4d73);    // Elementlar foni
  static const Color primary = Color(0xFF3f8cc2);   // Asosiy ko'k
  static const Color accent = Color(0xFF6ab0e4);    // Och ko'k (aktiv)
  static const Color textLight = Color(0xFFa2c8e8); // Matn rangi
  static const Color white = Colors.white;
}

class AppTheme {
  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.cardBg,
      background: AppColors.darkBg,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
    ),
    // Inputlar dizayni
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardBg,
      hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.5)),
      labelStyle: const TextStyle(color: AppColors.textLight),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent)),
    ),
    // Tugmalar dizayni
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}