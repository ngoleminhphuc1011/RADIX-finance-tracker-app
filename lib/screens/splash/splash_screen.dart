import 'dart:async';
import 'package:flutter/material.dart';
import '../../nav_wrapper.dart';
import '../../core/theme/app_color_locker.dart';
import 'widgets/money_loop_animation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return Scaffold(
      backgroundColor: locker.scaffoldBackground,
      body: Stack(
        children: [
          // Central content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RADIX',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended',
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: locker.textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                const MoneyLoopAnimation(),
              ],
            ),
          ),
          // Branding footer
          Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              'Fulton Ngo corporation',
              style: TextStyle(
                fontFamily: 'FontUltra',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: locker.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
