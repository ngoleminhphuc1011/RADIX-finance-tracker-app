import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(useMaterial3: true, brightness: Brightness.light);
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121214),
      cardColor: const Color(0xFF1E1E24),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE4E4E7)),
        bodyMedium: TextStyle(color: Color(0xFFE4E4E7)),
        bodySmall: TextStyle(color: Color(0xFFA1A1AA)),
        labelLarge: TextStyle(color: Color(0xFFE4E4E7)),
        labelMedium: TextStyle(color: Color(0xFFA1A1AA)),
        titleLarge: TextStyle(color: Color(0xFFE4E4E7)),
        titleMedium: TextStyle(color: Color(0xFFE4E4E7)),
        titleSmall: TextStyle(color: Color(0xFFE4E4E7)),
      ),
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF121214),
        primary: Color(0xFFE4E4E7),
        secondary: Color(0xFFA1A1AA),
      ),
    );
  }
}
