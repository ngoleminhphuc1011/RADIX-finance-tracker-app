import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';

enum ThemeOption { light, dark, system }

/// A modern segmented capsule bar for switching between Light, System, and Dark themes.
class ThemeSegmentedBar extends StatelessWidget {
  final ThemeOption selectedTheme;
  final ValueChanged<ThemeOption> onThemeChanged;

  const ThemeSegmentedBar({
    super.key,
    required this.selectedTheme,
    required this.onThemeChanged,
  });

  int get _selectedIndex {
    switch (selectedTheme) {
      case ThemeOption.light:
        return 0;
      case ThemeOption.system:
        return 1;
      case ThemeOption.dark:
        return 2;
    }
  }

  Color _getCapsuleColor(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final locker = AppColorLocker.of(context);
    switch (selectedTheme) {
      case ThemeOption.light:
        return locker.settingsActiveCapsuleLight;
      case ThemeOption.system:
        return brightness == Brightness.light
            ? locker.settingsActiveCapsuleSystemLight
            : locker.settingsActiveCapsuleSystemDark;
      case ThemeOption.dark:
        return locker.settingsActiveCapsuleDark;
    }
  }

  Color _getActiveTextColor(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    if (isDarkTheme) {
      return AppColorLocker.of(context).textPrimary;
    } else {
      switch (selectedTheme) {
        case ThemeOption.light:
          return AppColorLocker.of(context).textPrimary;
        case ThemeOption.system:
          return AppColorLocker.of(context).textPrimary;
        case ThemeOption.dark:
          return AppColorLocker.of(context).textOnDark;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: locker.settingsCapsuleBarBackground,
            borderRadius: BorderRadius.circular(30),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double tabWidth = constraints.maxWidth / 3;

              return Stack(
                children: [
                  // Sliding indicator (medicine capsule)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    left: _selectedIndex * tabWidth,
                    top: 0,
                    bottom: 0,
                    width: tabWidth,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      decoration: BoxDecoration(
                        color: _getCapsuleColor(context),
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),

                  // Tab labels
                  Row(
                    children: [
                      _buildTab(
                        context: context,
                        index: 0,
                        option: ThemeOption.light,
                        label: 'LIGHT',
                        icon: Icons.sunny,
                      ),
                      _buildTab(
                        context: context,
                        index: 1,
                        option: ThemeOption.system,
                        label: 'SYSTEM',
                        icon: Icons.phone_android,
                      ),
                      _buildTab(
                        context: context,
                        index: 2,
                        option: ThemeOption.dark,
                        label: 'DARK',
                        icon: Icons.dark_mode,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required BuildContext context,
    required int index,
    required ThemeOption option,
    required String label,
    required IconData icon,
  }) {
    final bool isActive = _selectedIndex == index;
    final activeTextColor = _getActiveTextColor(context);

    return Expanded(
      child: GestureDetector(
        onTap: () => onThemeChanged(option),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeInOutCubic,
              style: TextStyle(
                fontFamily: 'MonumentExtended-Regular',
                fontSize: 12,
                letterSpacing: 3.0,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? activeTextColor
                    : AppColorLocker.of(context).textTertiary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isActive
                        ? activeTextColor
                        : AppColorLocker.of(context).textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
