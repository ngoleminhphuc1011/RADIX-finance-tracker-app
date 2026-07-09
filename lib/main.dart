import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // On web, we must set the database factory BEFORE any DB call.
  // This tells sqflite to use IndexedDB + WebAssembly SQLite instead
  // of native C SQLite (which doesn't exist in a browser).
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
    debugPrint('[main] Web detected — databaseFactory set to ffi_web.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RADIX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.black,
      ),
      home: const SplashScreen(),
    );
  }
}
