// dark_theme.dart
import 'package:flutter/material.dart';
import 'text_styles.dart';

class AppDarkTheme {
  AppDarkTheme._();

  static ThemeData theme = ThemeData(
    useMaterial3: true,

    brightness: Brightness.dark,

    fontFamily: AppTextStyles.fontFamily,

    scaffoldBackgroundColor: const Color(0xff0F172A),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xff16A34A),
      brightness: Brightness.dark,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Color(0xff0F172A),
      foregroundColor: Colors.white,
    ),

    cardTheme: CardThemeData(
      color: const Color(0xff1E293B),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff16A34A),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xff1E293B),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xff22C55E),
          width: 2,
        ),
      ),
    ),

    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.headlineLarge,
      headlineMedium: AppTextStyles.headlineMedium,
      headlineSmall: AppTextStyles.headlineSmall,
      titleLarge: AppTextStyles.titleLarge,
      titleMedium: AppTextStyles.titleMedium,
      titleSmall: AppTextStyles.titleSmall,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.labelLarge,
    ),
  );
}
