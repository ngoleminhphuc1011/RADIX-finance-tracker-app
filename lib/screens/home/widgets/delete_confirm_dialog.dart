import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';

/// Shows a modern minimalist delete confirmation with fluid bounce animation.
void showDeleteConfirmDialog(
  BuildContext context, {
  required TransactionModel model,
  required void Function(int) onDeleteTransaction,
  VoidCallback? onConfirmed,
}) {
  final locker = AppColorLocker.of(context);

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Delete Confirm',
    transitionDuration: const Duration(milliseconds: 350),
    barrierColor: locker.barrierColor,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
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
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: locker.textPrimary.withValues(alpha: 0.06),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Transaction?',
                        style: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Are you sure you want to delete this?'
                        ' This action cannot be undone.',
                        style: AppTypography.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: locker.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: locker.textPrimary.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Cancel',
                                    style: AppTypography.openSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: locker.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                final int? txId = model.id;
                                if (txId == null) return;
                                onDeleteTransaction(txId);
                                Navigator.pop(context); // pop confirm dialog
                                onConfirmed
                                    ?.call(); // callback to pop parent dialog if needed
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: locker.deleteButtonBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontFamily: 'MonumentExtended-Regular',
                                      fontSize: 13,
                                      color: locker.textOnDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
