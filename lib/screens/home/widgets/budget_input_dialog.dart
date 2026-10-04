import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/currency_provider.dart';

/// Shows the bottom sheet modal to set or edit the monthly budget.
void showBudgetInputDialog(
  BuildContext context, {
  required double currentBudget,
  required ValueChanged<double> onBudgetChanged,
}) {
  final locker = AppColorLocker.of(context);
  final TextEditingController budgetController = TextEditingController(
    text: currentBudget == 0 ? '' : currentBudget.toStringAsFixed(0),
  );

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: locker.barrierColor,
    builder: (BuildContext context) {
      final mediaQuery = MediaQuery.of(context);
      final double maxHeight = mediaQuery.size.height * 0.9;
      final double keyboardInset = mediaQuery.viewInsets.bottom;
      final double bottomOffset = keyboardInset > 0 ? 8 : 20;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: keyboardInset + bottomOffset,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent taps inside dialog from closing
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  maxHeight: maxHeight,
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: locker.dialogBackground,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: locker.dialogShadow30,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ENTER MONTHLY BUDGET',
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: budgetController,
                          keyboardType: TextInputType.number,
                          autofocus: true,
                          style: AppTypography.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: locker.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g. 500',
                            hintStyle: AppTypography.openSans(
                              fontWeight: FontWeight.bold,
                              color: locker.textTertiary,
                            ),
                            prefix: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                CurrencyProvider.read(context).symbol,
                                style: TextStyle(
                                  fontFamily: null,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: locker.textPrimary,
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: locker.focusBorder),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: locker.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              final double? enteredBudget = double.tryParse(
                                budgetController.text,
                              );
                              if (enteredBudget != null) {
                                onBudgetChanged(enteredBudget);
                                Navigator.pop(context);
                              }
                            },
                            child: Text(
                              'SAVE BUDGET',
                              style: TextStyle(
                                color: locker.textOnDark,
                                fontFamily: 'MonumentExtended-Regular',
                                fontWeight: FontWeight.w100,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
