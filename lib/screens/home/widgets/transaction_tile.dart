import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/radix_currency_text.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel model;
  final VoidCallback? onTap;

  static final TextStyle _titleStyle = AppTypography.openSans(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  const TransactionTile({super.key, required this.model, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isExpense = model.isExpense;
    final locker = AppColorLocker.of(context);
    final colors = model.getColors(context);
    final Color fgColor = isExpense ? locker.expenseFg : locker.incomeFg;
    final IconData? resolvedIcon = iconOptions[model.category];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon square — icon sits directly on tinted bg
            SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                resolvedIcon ?? Icons.widgets_outlined,
                color: fgColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Text(
                model.title,
                style: _titleStyle.copyWith(color: locker.textPrimary),
              ),
            ),
            // Amount
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: RadixCurrencyText(
                  isExpense: isExpense,
                  amount: model.amount,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: fgColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared icon key-to-IconData mapping used by TransactionTile,
/// AddTransactionDialog, and EditMorphDialog.
const Map<String, IconData> iconOptions = {
  'fastfood': Icons.fastfood_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'directions_car': Icons.directions_car_filled_outlined,
  'home': Icons.home_outlined,
  'payments': Icons.payments_outlined,
  'work': Icons.work_outline,
  'school': Icons.school_outlined,
  'flight': Icons.flight_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'health_and_safety': Icons.health_and_safety_outlined,
  'pets': Icons.pets_outlined,
  'celebration': Icons.celebration_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'train': Icons.train_outlined,
};
