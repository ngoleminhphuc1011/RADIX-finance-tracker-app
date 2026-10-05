import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/radix_currency_text.dart';
import 'graph_models.dart';
import 'category_badge.dart';

/// Floating card containing the animated Donut Chart and center spending summary.
class DonutChartCard extends StatelessWidget {
  final List<AggregatedCategory> categories;
  final String? selectedIconKey;
  final double swipeProgress;
  final double totalSpent;
  final ValueChanged<String?> onCategoryTapped;

  const DonutChartCard({
    super.key,
    required this.categories,
    required this.selectedIconKey,
    required this.swipeProgress,
    required this.totalSpent,
    required this.onCategoryTapped,
  });

  int get _touchedIndex {
    if (selectedIconKey == null) return -1;
    return categories.indexWhere((c) => c.iconKey == selectedIconKey);
  }

  List<double> _buildAnimatedValues(double progress) {
    if (totalSpent == 0) {
      return List.filled(categories.length, 0.0);
    }

    final List<double> animatedValues = [];
    double accumulatedProgress = 0.0;

    for (int i = 0; i < categories.length; i++) {
      final targetVal = categories[i].amount;
      final targetPct = targetVal / totalSpent;

      final sliceStart = accumulatedProgress;
      final sliceEnd = accumulatedProgress + targetPct;

      if (progress <= sliceStart) {
        animatedValues.add(0.0);
      } else if (progress >= sliceEnd) {
        animatedValues.add(targetVal);
      } else {
        final sliceFraction = (progress - sliceStart) / targetPct;
        animatedValues.add(targetVal * sliceFraction);
      }
      accumulatedProgress = sliceEnd;
    }
    return animatedValues;
  }

  List<PieChartSectionData> _buildSections() {
    final effectiveProgress = (swipeProgress <= 0.0 && categories.isNotEmpty)
        ? 1.0
        : swipeProgress;
    if (effectiveProgress == 0.0 || categories.isEmpty) {
      return [
        PieChartSectionData(
          color: Colors.transparent,
          value: 1.0,
          radius: 42.0,
          showTitle: false,
        ),
      ];
    }

    final animatedValues = _buildAnimatedValues(effectiveProgress);
    final touchedIdx = _touchedIndex;

    return List.generate(categories.length, (i) {
      final category = categories[i];
      final isTouched = i == touchedIdx;
      final radius = isTouched ? 54.0 : 42.0;

      final hsl = HSLColor.fromColor(category.color);
      final darkenedIconColor = hsl
          .withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0))
          .toColor();

      return PieChartSectionData(
        color: category.color,
        value: animatedValues[i],
        radius: radius,
        showTitle: false,
        badgeWidget: CategoryBadge(
          icon: category.icon,
          iconColor: darkenedIconColor,
          isTouched: isTouched,
          progress: effectiveProgress,
        ),
        badgePositionPercentageOffset: isTouched ? 0.65 : 0.55,
      );
    });
  }

  Widget _buildDonutCenterText(BuildContext context) {
    final touchedIdx = _touchedIndex;
    final locker = AppColorLocker.of(context);
    final effectiveProgress = (swipeProgress <= 0.0 && totalSpent > 0)
        ? 1.0
        : swipeProgress;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          touchedIdx != -1 && touchedIdx < categories.length
              ? categories[touchedIdx].name.toUpperCase()
              : 'TOTAL SPENT',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 11,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RadixCurrencyText(
            amount: touchedIdx != -1 && touchedIdx < categories.length
                ? categories[touchedIdx].amount
                : totalSpent * effectiveProgress,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'MonumentExtended',
            color: locker.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'No expenses yet',
                maxLines: 1,
                softWrap: false,
                style: AppTypography.openSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Add transactions to see your breakdown',
                maxLines: 1,
                softWrap: false,
                style: AppTypography.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final bool hasData = categories.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: locker.cardBackground,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: locker.textPrimary.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: SizedBox(
        height: 280,
        child: hasData
            ? Stack(
                children: [
                  RepaintBoundary(
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
                                if (event is FlTapUpEvent) {
                                  if (pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    onCategoryTapped(null);
                                    return;
                                  }
                                  final index = pieTouchResponse
                                      .touchedSection!
                                      .touchedSectionIndex;
                                  if (index >= 0 && index < categories.length) {
                                    final targetKey = categories[index].iconKey;
                                    if (selectedIconKey == targetKey) {
                                      onCategoryTapped(null);
                                    } else {
                                      onCategoryTapped(targetKey);
                                    }
                                  }
                                }
                              },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 4,
                        centerSpaceRadius: 95,
                        sections: _buildSections(),
                      ),
                      swapAnimationDuration: swipeProgress == 1.0
                          ? const Duration(milliseconds: 200)
                          : Duration.zero,
                      swapAnimationCurve: Curves.easeOut,
                    ),
                  ),
                  Center(child: _buildDonutCenterText(context)),
                ],
              )
            : _buildEmptyChart(),
      ),
    );
  }
}
