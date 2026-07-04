import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _currentTheme = ThemeMode.light;

  ThemeMode get currentTheme => _currentTheme;

  void toggle() {
    _currentTheme = _currentTheme == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}
