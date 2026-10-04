import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import 'hold_confirm_button.dart';

/// Displays the confirmation dialog with blurred backdrop and hold-to-confirm mechanism.
void showResetConfirmDialog(
  BuildContext context, {
  required VoidCallback onResetAll,
}) {
  final locker = AppColorLocker.of(context);
  final accentRed = locker.accentRed;

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Reset Confirm',
    transitionDuration: const Duration(milliseconds: 350),
    barrierColor: locker.barrierColorLight,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: Stack(
          children: [
            Container(
              color: locker.textPrimary.withValues(alpha: 0.15),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                ),
                child: child,
              ),
            ),
          ],
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      bool isCancelPressed = false;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Prevent taps inside dialog from closing
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 48),
                constraints: const BoxConstraints(maxWidth: 360),
                decoration: BoxDecoration(
                  color: locker.dialogBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: accentRed.withValues(alpha: 0.75),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: locker.dialogShadow30,
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: locker.dialogShadow60,
                      blurRadius: 60,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONFIRM DIALOGUE',
                        style: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: locker.textDialogTitle,
                          letterSpacing: 1.7,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This action cannot be undone. Are you sure you want to clear all spending history?',
                        style: AppTypography.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: locker.textPrimary.withValues(alpha: 0.87),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatefulBuilder(
                              builder: (context, setState) {
                                return GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTapDown: (_) =>
                                      setState(() => isCancelPressed = true),
                                  onTapUp: (_) {
                                    setState(() => isCancelPressed = false);
                                    Future.delayed(
                                      const Duration(milliseconds: 120),
                                      () {
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                    );
                                  },
                                  onTapCancel: () =>
                                      setState(() => isCancelPressed = false),
                                  child: AnimatedScale(
                                    scale: isCancelPressed ? 0.85 : 1.0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: locker.textTertiary.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Cancel',
                                        style: AppTypography.openSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: locker.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            HoldConfirmButton(
                              onConfirmed: () {
                                Navigator.pop(context);
                                onResetAll();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
