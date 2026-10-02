import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/currency_provider.dart';
import 'graph_models.dart';

/// Displays the vertical category breakdown list with percentages and icons.
class CategoryBreakdownList extends StatelessWidget {
  final List<AggregatedCategory> categories;
  final double totalSpent;
  final ValueChanged<String> onCategorySelected;

  const CategoryBreakdownList({
    super.key,
    required this.categories,
    required this.totalSpent,
    required this.onCategorySelected,
  });

  Color _getContrastIconColor(Color categoryColor) {
    final hsl = HSLColor.fromColor(categoryColor);
    return hsl.withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);

    return Column(
      key: const ValueKey('CategoryList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BREAKDOWN',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: locker.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(categories.length, (index) {
            final category = categories[index];
            final percent = totalSpent > 0
                ? (category.amount / totalSpent * 100).toStringAsFixed(1)
                : '0.0';

            return GestureDetector(
              onTap: () => onCategorySelected(category.iconKey),
              child: Container(
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
                    // Flat Circle Badge matching segment color
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
                    // Name & Percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: locker.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 10,
                            color: locker.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Amount
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyProvider.read(
                            context,
                          ).format(category.amount),
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: locker.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
