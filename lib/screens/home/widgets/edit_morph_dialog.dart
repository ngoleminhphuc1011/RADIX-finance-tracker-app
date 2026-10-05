import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/currency_provider.dart';
import 'transaction_tile.dart';
import 'icon_picker_sheet.dart';
import 'delete_confirm_dialog.dart';

/// Shows the morph editing dialog for inspecting or updating a transaction.
void showEditMorphDialog(
  BuildContext context, {
  required TransactionModel model,
  required void Function(
    int id,
    String newIcon,
    String newDescription,
    double newAmount,
  )?
  onUpdateTransaction,
  required void Function(int id) onDeleteTransaction,
}) {
  final locker = AppColorLocker.of(context);
  final colors = model.getColors(context);
  final Color amountColor = colors.fg;
  final Color badgeColor = colors.badge;

  // Local editing state (isolated per dialog instance)
  String localIconKey = model.category;
  final TextEditingController descController = TextEditingController(
    text: model.title,
  );
  final String initialAmount = model.amount == model.amount.toInt()
      ? model.amount.toInt().toString()
      : model.amount.toString();
  final TextEditingController amountController = TextEditingController(
    text: initialAmount,
  );

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss Morph Dialog',
    transitionDuration: const Duration(milliseconds: 400),
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
      final mediaQuery = MediaQuery.of(context);
      final isLandscape = mediaQuery.orientation == Orientation.landscape;
      final Size screenSize = mediaQuery.size;
      final double maxHeight = screenSize.height * 0.9;
      final double keyboardInset = mediaQuery.viewInsets.bottom;
      final double bottomOffset = keyboardInset > 0 ? 8 : 20;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          final IconData? currentIcon = iconOptions[localIconKey];
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(),
            child: Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 16,
                right: 16,
                bottom: keyboardInset + bottomOffset,
              ),
              child: Align(
                alignment: keyboardInset > 0
                    ? Alignment.bottomCenter
                    : Alignment.center,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {}, // Prevent taps inside dialog from closing
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: isLandscape ? 480 : screenSize.width * 0.85,
                        maxHeight: maxHeight,
                      ),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: colors.bg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: locker.textPrimary.withValues(alpha: 0.06),
                          width: 1.5,
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top Row: date + type badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    model.date,
                                    style: AppTypography.openSans(
                                      fontSize: 12,
                                      color: locker.textPrimary.withValues(
                                        alpha: 0.38,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: amountColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Text(
                                      model.isExpense ? 'EXPENSE' : 'INCOME',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: badgeColor,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Category icon — clickable to open icon picker
                              GestureDetector(
                                onTap: () => showIconPickerSheet(
                                  context,
                                  selectedIconKey: localIconKey,
                                  accentColor: amountColor,
                                  onIconSelected: (newKey) {
                                    setDialogState(() {
                                      localIconKey = newKey ?? '';
                                    });
                                  },
                                ),
                                child: Container(
                                  width: 86,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    color: locker.scaffoldBackground.withValues(
                                      alpha: 0.7,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Icon(
                                    currentIcon ?? Icons.widgets_outlined,
                                    color: amountColor,
                                    size: 48,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Description — editable TextField
                              TextField(
                                controller: descController,
                                style: AppTypography.openSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: locker.textPrimary.withValues(
                                    alpha: 0.87,
                                  ),
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: 'Enter description',
                                  hintStyle: AppTypography.openSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: locker.textPrimary.withValues(
                                      alpha: 0.38,
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: locker.scaffoldBackground
                                      .withValues(alpha: 0.5),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Amount (heavy visual anchor) — editable
                              TextField(
                                controller: amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'MonumentExtended',
                                  fontSize: isLandscape ? 36 : 50,
                                  fontWeight: FontWeight.w800,
                                  color: amountColor,
                                ),
                                decoration: InputDecoration(
                                  prefix: Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Text(
                                      CurrencyProvider.read(context).symbol,
                                      style: TextStyle(
                                        fontFamily: null,
                                        fontSize: isLandscape ? 36.0 : 50.0,
                                        fontWeight: FontWeight.w800,
                                        color: amountColor,
                                      ),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: locker.scaffoldBackground
                                      .withValues(alpha: 0.5),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Bottom Row: delete (left) + SAVE (right)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Delete icon
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: locker.accentRed.withValues(
                                        alpha: 0.6,
                                      ),
                                      size: 28,
                                    ),
                                    splashRadius: 20,
                                    onPressed: () {
                                      showDeleteConfirmDialog(
                                        context,
                                        model: model,
                                        onDeleteTransaction:
                                            onDeleteTransaction,
                                        onConfirmed: () {
                                          Navigator.pop(
                                            context,
                                          ); // pop morph dialog
                                        },
                                      );
                                    },
                                  ),
                                  // SAVE button
                                  GestureDetector(
                                    onTap: () {
                                      final String cleanAmount =
                                          amountController.text.replaceAll(
                                            ',',
                                            '',
                                          );
                                      final double? amount = double.tryParse(
                                        cleanAmount,
                                      );
                                      if (descController.text.isNotEmpty &&
                                          amount != null &&
                                          onUpdateTransaction != null) {
                                        onUpdateTransaction(
                                          model.id!,
                                          localIconKey,
                                          descController.text,
                                          amount,
                                        );
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: badgeColor,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        'SAVE',
                                        style: TextStyle(
                                          fontFamily: 'MonumentExtended-Bold',
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          color: locker.textOnDark,
                                          letterSpacing: 1.5,
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
              ),
            ),
          );
        },
      );
    },
  );
}
