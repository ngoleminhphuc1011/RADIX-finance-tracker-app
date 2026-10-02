import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/currency_provider.dart';
import 'core/database/database_helper.dart';

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
  String initialCurrencyCode = 'USD';
  try {
    final themeString = await DatabaseHelper().getSetting('theme_mode');
    if (themeString == 'dark') {
      initialTheme = ThemeMode.dark;
    } else if (themeString == 'system') {
      initialTheme = ThemeMode.system;
    }

    final currencyString = await DatabaseHelper().getSetting('active_currency');
    if (currencyString != null) {
      initialCurrencyCode = currencyString;
    }
  } catch (e) {
    debugPrint('[main] Error loading initial settings: $e');
  }

  runApp(
    ThemeProvider(
      notifier: ValueNotifier<ThemeMode>(initialTheme),
      child: CurrencyProvider(
        notifier: ValueNotifier<CurrencyInfo>(
          CurrencyInfo.find(initialCurrencyCode),
        ),
        child: const MyApp(),
      ),
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
