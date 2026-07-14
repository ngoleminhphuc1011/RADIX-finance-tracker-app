import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, we must set the database factory BEFORE any DB call.
  // This tells sqflite to use IndexedDB + WebAssembly SQLite instead
  // of native C SQLite (which doesn't exist in a browser).
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('[main] Web detected — databaseFactory set to ffi_web.');
  }

  ThemeMode initialTheme = ThemeMode.light;
  try {
    final themeString = await DatabaseHelper().getSetting('theme_mode');
    if (themeString == 'dark') {
      initialTheme = ThemeMode.dark;
    } else if (themeString == 'system') {
      initialTheme = ThemeMode.system;
    }
  } catch (e) {
    debugPrint('[main] Error loading initial theme: $e');
  }

  runApp(
    ThemeProvider(
      notifier: ValueNotifier<ThemeMode>(initialTheme),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = ThemeProvider.of(context).value;
    return MaterialApp(
      title: 'RADIX',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
