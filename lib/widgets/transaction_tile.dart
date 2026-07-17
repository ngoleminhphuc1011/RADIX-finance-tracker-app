import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../theme/app_color_locker.dart';
import '../theme/currency_provider.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel model;
  final VoidCallback? onTap;

  static const TextStyle _titleStyle = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle _amountStyle = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  const TransactionTile({super.key, required this.model, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isExpense = model.isExpense;
    final locker = AppColorLocker.of(context);
    final colors = model.getColors(context);
    final Color fgColor = isExpense ? locker.expenseFg : locker.incomeFg;
    final currencyInfo = CurrencyProvider.watch(context);
    final String amountText =
        '${isExpense ? '-' : '+'} ${currencyInfo.format(model.amount)}';
    final IconData? resolvedIcon = iconOptions[model.category];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Icon square — no redundant white overlay, icon sits directly on tinted bg
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
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
                child: Text(
                  amountText,
                  style: _amountStyle.copyWith(color: fgColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared icon key-to-IconData mapping used by both TransactionTile
/// and the icon picker in HomeScreen.
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
