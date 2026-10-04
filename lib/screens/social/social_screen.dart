import 'package:flutter/material.dart';
import '../../core/theme/app_color_locker.dart';
import '../../core/theme/app_typography.dart';

/// Ultra-minimalist placeholder screen for the Social feature.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 40,
            left: 24,
            right: 24,
            bottom: 110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SOCIAL',
                style: TextStyle(
                  fontFamily: 'MonumentExtended',
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: locker.textPrimary,
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'COMING SOON',
                    style: AppTypography.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: locker.textTertiary,
                      letterSpacing: 3.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
