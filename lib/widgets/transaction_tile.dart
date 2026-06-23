import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel model;
  static final NumberFormat _amountFormat = NumberFormat('#,##0.00');

  const TransactionTile({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    final bool isExpense = model.isExpense;
    final Color bgColor = isExpense
        ? const Color(0xFFFFEBEE)
        : const Color(0xFFE8F5E9);
    final Color fgColor = isExpense
        ? const Color(0xFF78281F)
        : const Color(0xFF117A65);
    final String amountText =
        '${isExpense ? '-' : '+'} \$${_amountFormat.format(model.amount)}';
    final IconData? resolvedIcon = iconOptions[model.iconKey];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Icon square
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
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
              style: const TextStyle(
                fontFamily: 'MonumentExtended-Regular',
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Amount
          Text(
            amountText,
            style: TextStyle(
              fontFamily: 'MonumentExtended-Regular',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: fgColor,
            ),
          ),
        ],
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
