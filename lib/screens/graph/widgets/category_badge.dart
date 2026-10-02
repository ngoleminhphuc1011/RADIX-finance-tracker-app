import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';

/// Reusable category icon badge displayed on chart segments.
class CategoryBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final bool isTouched;
  final double progress;

  const CategoryBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.isTouched,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: progress > 0.85 ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        scale: progress > 0.85 ? (isTouched ? 1.25 : 1.0) : 0.0,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: locker.cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: locker.textPrimary.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Center(child: Icon(icon, size: 15, color: iconColor)),
        ),
      ),
    );
  }
}
