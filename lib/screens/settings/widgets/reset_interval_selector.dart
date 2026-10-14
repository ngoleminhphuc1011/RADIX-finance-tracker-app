import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/services/haptic_helper.dart';

/// A luxury minimalist segmented capsule selector for setting the budget reset interval (1M to 6M).
class ResetIntervalSelector extends StatelessWidget {
  final int selectedInterval;
  final ValueChanged<int> onIntervalChanged;

  const ResetIntervalSelector({
    super.key,
    required this.selectedInterval,
    required this.onIntervalChanged,
  });

  static const List<int> intervals = [1, 2, 3, 4, 5, 6];

  Color _getCapsuleColor(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return locker.settingsActiveCapsuleLight;
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final activeIndex = (selectedInterval - 1).clamp(0, 5);

    final String intervalDescription = selectedInterval == 1
        ? 'Cycle resets automatically every month'
        : 'Cycle resets automatically every $selectedInterval months';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'RESET INTERVAL',
                style: TextStyle(
                  fontFamily: 'MonumentExtended-Regular',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: locker.settingsSectionLabel,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Explanatory info text
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                intervalDescription,
                style: AppTypography.openSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: locker.settingsInfoText,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Segmented capsule selector
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: locker.settingsCapsuleBarBackground,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: locker.textPrimary.withValues(alpha: 0.05),
                  width: 1,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double tabWidth = constraints.maxWidth / 6;

                  return Stack(
                    children: [
                      // Sliding active capsule indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOutCubic,
                        left: activeIndex * tabWidth + 3,
                        top: 3,
                        bottom: 3,
                        width: tabWidth - 6,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          decoration: BoxDecoration(
                            color: _getCapsuleColor(context),
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),

                      // 6 Option segments
                      Row(
                        children: intervals.map((months) {
                          final bool isActive = months == selectedInterval;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticHelper.selectionClick();
                                onIntervalChanged(months);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                alignment: Alignment.center,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOutCubic,
                                  style: TextStyle(
                                    fontFamily: 'MonumentExtended-Regular',
                                    fontSize: 12,
                                    fontWeight: isActive
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isActive
                                        ? locker.textPrimary
                                        : locker.textTertiary,
                                    letterSpacing: 0.5,
                                  ),
                                  child: Text('${months}M'),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
