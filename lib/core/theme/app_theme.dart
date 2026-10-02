import 'package:flutter/material.dart';
import 'app_color_locker.dart';
import 'app_typography.dart';

class AppTheme {
  // ── Light Mode (Crisp Apple Minimalist White) ──
  static ThemeData get lightTheme {
    const locker = LightColorLocker();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: locker.scaffoldBackground,
      cardColor: locker.cardBackground,
      colorScheme: ColorScheme.light(
        primary: locker.textPrimary,
        secondary: locker.accentRed,
        surface: locker.cardBackground,
        onPrimary: locker.textOnDark,
        onSecondary: locker.textOnDark,
        onSurface: locker.textPrimary,
      ),
      textTheme: TextTheme(
        bodyLarge: AppTypography.openSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: locker.textPrimary,
        ),
        bodyMedium: AppTypography.openSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: locker.textSecondary,
        ),
        bodySmall: AppTypography.openSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: locker.textTertiary,
        ),
        labelLarge: AppTypography.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: locker.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'MonumentExtended-Bold',
          fontSize: 55,
          fontWeight: FontWeight.w900,
          color: locker.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 18,
          color: locker.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: locker.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: locker.textPrimary,
          fontFamily: 'MonumentExtended',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: locker.textPrimary,
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }

  // ── Luxury Dark Mode ──
  static ThemeData get darkTheme {
    const locker = DarkColorLocker();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: locker.scaffoldBackground,
      cardColor: locker.cardBackground,
      colorScheme: ColorScheme.dark(
        primary: locker.textPrimary,
        secondary: locker.accentRed,
        surface: locker.cardBackground,
        onPrimary: locker.textOnDark,
        onSecondary: locker.textOnLight,
        onSurface: locker.textPrimary,
      ),
      textTheme: TextTheme(
        bodyLarge: AppTypography.openSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: locker.textPrimary,
        ),
        bodyMedium: AppTypography.openSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: locker.textSecondary,
        ),
        bodySmall: AppTypography.openSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: locker.textTertiary,
        ),
        labelLarge: AppTypography.openSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: locker.textPrimary,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'MonumentExtended-Bold',
          fontSize: 55,
          fontWeight: FontWeight.w900,
          color: locker.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 18,
          color: locker.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: locker.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: locker.textPrimary,
          fontFamily: 'MonumentExtended',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: locker.textPrimary,
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }
}
