import 'package:flutter/material.dart';
import 'text_styles.dart';

class AppLightTheme {
  AppLightTheme._();

  static const Color primary = Color(0xff22C55E);
  static const Color secondary = Color(0xff38BDF8);

  // لون خلفية التطبيق مثل الصورة.
  static const Color background = Color(0xffF4F4F4);

  // خلفية الكروت.
  static const Color surface = Color(0xffFFFFFF);

  static const Color border = Color(0xffE2E8F0);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppTextStyles.fontFamily,

    scaffoldBackgroundColor: background,

    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: secondary,

      // الخلفية العامة للعناصر الأساسية.
      surface: surface,

      // لضمان أن كل الكروت المستخدمة في الشاشات تصبح بيضاء.
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: surface,
      surfaceContainerHighest: surface,

      error: Color(0xffEF4444),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Color(0xff0F172A),
    ),

    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    floatingActionButtonTheme:
    const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(
          double.infinity,
          55,
        ),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: primary,
          width: 2,
        ),
      ),
    ),

    dividerColor: border,

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