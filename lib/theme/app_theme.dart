import 'package:flutter/material.dart';

class AppTheme {
  // ── Light Mode (Crisp Apple Minimalist White) ──
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: Colors.black,
        secondary: Color(0xFFE57373),
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 14,
          color: Colors.black87,
        ),
        bodySmall: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 14,
          color: Color(0xFF9E9E9E),
        ),
        labelLarge: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 18,
          color: Colors.black,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'MonumentExtended-Bold',
          fontSize: 55,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 18,
          color: Colors.black,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontFamily: 'MonumentExtended',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.black,
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }

  // ── Luxury Dark Mode ──
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121214),
      cardColor: const Color(0xFF1E1E24),
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFFE4E4E7),
        secondary: const Color(0xFFE57373),
        surface: const Color(0xFF1E1E24),
        onPrimary: const Color(0xFF121214),
        onSecondary: const Color(0xFFE4E4E7),
        onSurface: const Color(0xFFE4E4E7),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Color(0xFFE4E4E7),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 14,
          color: Color(0xFFE4E4E7),
        ),
        bodySmall: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 14,
          color: Color(0xFFA1A1AA),
        ),
        labelLarge: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 18,
          color: Color(0xFFE4E4E7),
        ),
        headlineLarge: TextStyle(
          fontFamily: 'MonumentExtended-Bold',
          fontSize: 55,
          fontWeight: FontWeight.w900,
          color: Color(0xFFE4E4E7),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'MonumentExtended-Regular',
          fontSize: 18,
          color: Color(0xFFE4E4E7),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121214),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: Color(0xFFE4E4E7),
          fontFamily: 'MonumentExtended',
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE4E4E7),
        elevation: 0,
        highlightElevation: 0,
      ),
    );
  }
}
