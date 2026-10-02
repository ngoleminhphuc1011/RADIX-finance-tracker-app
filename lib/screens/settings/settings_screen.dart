import 'package:flutter/material.dart';
import '../../core/theme/app_color_locker.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/currency_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/reset_interval_service.dart';
import 'widgets/theme_segmented_bar.dart';
import 'widgets/currency_picker_section.dart';
import 'widgets/reset_interval_selector.dart';
import 'widgets/reset_button.dart';
import 'widgets/reset_confirm_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onResetAll;
  final ValueChanged<int>? onIntervalChanged;

  const SettingsScreen({
    super.key,
    required this.onResetAll,
    this.onIntervalChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeOption _selectedTheme = ThemeOption.light;
  int _selectedInterval = ResetIntervalService.defaultIntervalMonths;

  @override
  void initState() {
    super.initState();
    _loadInterval();
  }

  Future<void> _loadInterval() async {
    final interval = await ResetIntervalService.getResetIntervalMonths();
    if (mounted) {
      setState(() {
        _selectedInterval = interval;
      });
    }
  }

  Future<void> _onIntervalChanged(int months) async {
    setState(() {
      _selectedInterval = months;
    });
    await ResetIntervalService.setResetIntervalMonths(months);
    widget.onIntervalChanged?.call(months);
  }

  String get _selectedCurrencyCode {
    try {
      return CurrencyProvider.read(context).code;
    } catch (_) {
      return 'USD';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mode = ThemeProvider.of(context).value;
    ThemeOption targetOption;
    if (mode == ThemeMode.light) {
      targetOption = ThemeOption.light;
    } else if (mode == ThemeMode.dark) {
      targetOption = ThemeOption.dark;
    } else {
      targetOption = ThemeOption.system;
    }
    if (_selectedTheme != targetOption) {
      _selectedTheme = targetOption;
    }
  }

  Future<void> _selectCurrency(String code) async {
    try {
      final oldCode = _selectedCurrencyCode;
      if (oldCode.toUpperCase() == code.toUpperCase()) return;

      // 1. Convert all transaction amounts and budget in database
      await DatabaseHelper().convertAllTransactionsAndBudget(oldCode, code);

      // 2. Save new currency setting to settings table
      await DatabaseHelper().setSetting('active_currency', code);

      // 3. Update active currency in context
      if (mounted) {
        CurrencyProvider.of(context).value = CurrencyInfo.find(code);
      }
    } catch (e) {
      debugPrint('[Settings] Error saving currency: $e');
    }
  }

  void _onThemeChanged(ThemeOption option) {
    setState(() {
      _selectedTheme = option;
      switch (option) {
        case ThemeOption.light:
          ThemeProvider.of(context).value = ThemeMode.light;
          DatabaseHelper().setSetting('theme_mode', 'light');
          break;
        case ThemeOption.system:
          ThemeProvider.of(context).value = ThemeMode.system;
          DatabaseHelper().setSetting('theme_mode', 'system');
          break;
        case ThemeOption.dark:
          ThemeProvider.of(context).value = ThemeMode.dark;
          DatabaseHelper().setSetting('theme_mode', 'dark');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: locker.settingsBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(
              top: 40,
              left: 24,
              right: 24,
              bottom: 110,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings heading
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColorLocker.of(context).textPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                // Appearance label (aligned with bar)
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Appearance',
                        style: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: locker.settingsSectionLabel,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Capsule toggle bar
                ThemeSegmentedBar(
                  selectedTheme: _selectedTheme,
                  onThemeChanged: _onThemeChanged,
                ),
                const SizedBox(height: 40),
                // Currency section
                CurrencyPickerSection(
                  selectedCurrencyCode: _selectedCurrencyCode,
                  onSelectCurrency: _selectCurrency,
                ),
                const SizedBox(height: 40),
                // Reset interval section
                ResetIntervalSelector(
                  selectedInterval: _selectedInterval,
                  onIntervalChanged: _onIntervalChanged,
                ),
                const SizedBox(height: 40),
                // Reset button with confirmation dialog
                ResetButton(
                  onPressed: () => showResetConfirmDialog(
                    context,
                    onResetAll: widget.onResetAll,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
