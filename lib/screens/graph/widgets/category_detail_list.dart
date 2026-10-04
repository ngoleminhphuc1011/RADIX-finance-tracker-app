import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/currency_provider.dart';
import 'graph_models.dart';

/// Displays the drill-down list of transactions belonging to a selected category.
class CategoryDetailList extends StatelessWidget {
  final String iconKey;
  final List<AggregatedCategory> categories;
  final List<TransactionModel> transactions;
  final VoidCallback onBack;

  static final DateFormat _displayFormat = DateFormat('MMM dd');

  const CategoryDetailList({
    super.key,
    required this.iconKey,
    required this.categories,
    required this.transactions,
    required this.onBack,
  });

  Color _getContrastIconColor(Color categoryColor) {
    final hsl = HSLColor.fromColor(categoryColor);
    return hsl.withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final category = categories.firstWhere(
      (c) => c.iconKey == iconKey,
      orElse: () => AggregatedCategory(
        iconKey: iconKey,
        name: (categoryRegistry[iconKey] ?? otherCategory).name,
        icon: (categoryRegistry[iconKey] ?? otherCategory).icon,
        color: locker.getCategoryColor(iconKey),
        amount: 0,
      ),
    );

    return Column(
      key: ValueKey('DetailList_$iconKey'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 14, color: locker.textPrimary),
                const SizedBox(width: 6),
                Text(
                  'BACK TO CATEGORIES',
                  style: AppTypography.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: locker.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${category.name.toUpperCase()} TRANSACTIONS',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: locker.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        transactions.isEmpty
            ? Center(
                key: const ValueKey('NoDetailsPlaceholder'),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No transactions recorded',
                    style: AppTypography.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: locker.textTertiary,
                    ),
                  ),
                ),
              )
            : Column(
                children: List.generate(transactions.length, (index) {
                  final tx = transactions[index];

                  // Format date for display
                  String dateStr;
                  try {
                    final parsed = DateTime.parse(tx.date);
                    dateStr = _displayFormat.format(parsed);
                  } catch (_) {
                    dateStr = tx.date;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: locker.cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: locker.textPrimary.withValues(alpha: 0.04),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Flat Circle Icon Badge matching segment color
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              category.icon,
                              size: 16,
                              color: _getContrastIconColor(category.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: AppTypography.openSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: locker.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: AppTypography.openSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: locker.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '-${CurrencyProvider.read(context).format(tx.amount)}',
                              style: AppTypography.openSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: locker.expenseModelFg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
      ],
    );
  }
}
