import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/theme/currency_provider.dart';
import 'core/database/database_helper.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// RADIX: Application Entry Point & Root Configuration
// ═══════════════════════════════════════════════════════════════════════════════

void main() async {
  // Step 1: Ensure Flutter widget tree bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Step 2: Lock supported orientations (both portrait and landscape allowed)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Step 3: Web platform check — swap native C SQLite with IndexedDB WebAssembly
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Step 4: Pre-load persisted theme and currency settings BEFORE rendering UI.
  // This prevents any visual "flash" or jump when the app first launches.
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

  // Step 5: Start the app with global InheritedNotifier providers at the root.
  // Any descendant widget in the app tree can listen to or modify these notifiers.
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

// ── Root Widget ───────────────────────────────────────────────────────────────
/// Configures MaterialApp with dynamic themes and launches SplashScreen.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuilds automatically when ThemeProvider's ValueNotifier emits a change
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
