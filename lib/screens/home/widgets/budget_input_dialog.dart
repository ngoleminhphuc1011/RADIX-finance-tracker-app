import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/currency_provider.dart';

/// Shows the bottom sheet modal to set or edit the monthly budget.
void showBudgetInputDialog(
  BuildContext context, {
  required double currentBudget,
  required ValueChanged<double> onBudgetChanged,
}) {
  final locker = AppColorLocker.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: locker.barrierColor,
    builder: (BuildContext ctx) {
      return _BudgetInputSheet(
        currentBudget: currentBudget,
        onBudgetChanged: onBudgetChanged,
      );
    },
  );
}

class _BudgetInputSheet extends StatefulWidget {
  final double currentBudget;
  final ValueChanged<double> onBudgetChanged;

  const _BudgetInputSheet({
    required this.currentBudget,
    required this.onBudgetChanged,
  });

  @override
  State<_BudgetInputSheet> createState() => _BudgetInputSheetState();
}

class _BudgetInputSheetState extends State<_BudgetInputSheet> {
  late final TextEditingController _budgetController;

  @override
  void initState() {
    super.initState();
    _budgetController = TextEditingController(
      text: widget.currentBudget == 0 ? '' : widget.currentBudget.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final text = _budgetController.text.trim();
    final double enteredBudget =
        text.isEmpty ? 0.0 : (double.tryParse(text) ?? 0.0);
    final double sanitizedBudget =
        enteredBudget < 0 ? 0.0 : enteredBudget;
    widget.onBudgetChanged(sanitizedBudget);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final bool isKeyboardOpen = keyboardInset > 0;
    final double maxHeight =
        mediaQuery.size.height * (isLandscape && isKeyboardOpen ? 0.98 : 0.9);
    final double topPadding = (isLandscape && isKeyboardOpen) ? 4.0 : 20.0;
    final double bottomOffset =
        isKeyboardOpen ? (isLandscape ? 4.0 : 8.0) : 20.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding,
          left: isLandscape ? 16 : 20,
          right: isLandscape ? 16 : 20,
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
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(
                          fontFamily: 'MonumentExtended',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: locker.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 500',
                          hintStyle: TextStyle(
                            fontFamily: 'MonumentExtended',
                            fontSize: 16,
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
                          onPressed: _saveBudget,
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
  }
}
