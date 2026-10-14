/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/theme/app_color_locker.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/theme/currency_provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/services/reset_interval_service.dart';
import '../../core/services/haptic_helper.dart';
import '../../core/services/data_export_service.dart';
import '../home/widgets/bounce_card.dart';
import 'widgets/theme_segmented_bar.dart';
import 'widgets/currency_picker_section.dart';
import 'widgets/reset_interval_selector.dart';
import 'widgets/reset_button.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_screen.dart';
import 'legal/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onResetAll;
  final ValueChanged<int>? onIntervalChanged;
  final VoidCallback? onDataRestored;

  const SettingsScreen({
    super.key,
    required this.onResetAll,
    this.onIntervalChanged,
    this.onDataRestored,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeOption _selectedTheme = ThemeOption.light;
  int _selectedInterval = ResetIntervalService.defaultIntervalMonths;
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final interval = await ResetIntervalService.getResetIntervalMonths();
    final haptic = await HapticHelper.isEnabled();
    if (mounted) {
      setState(() {
        _selectedInterval = interval;
        _hapticEnabled = haptic;
      });
    }
  }

  Future<void> _onIntervalChanged(int months) async {
    setState(() {
      _selectedInterval = months;
    });
    await ResetIntervalService.setResetIntervalMonths(months);
    widget.onIntervalChanged?.call(months);
    if (mounted) {
      DataExportService.showToast(
        context,
        'Reset interval set to $months month${months > 1 ? "s" : ""}',
      );
    }
  }

  String get _selectedCurrencyCode {
    try {
      return CurrencyProvider.watch(context).code;
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
      final oldCode = CurrencyProvider.read(context).code;
      final info = CurrencyInfo.find(code);
      if (oldCode.toUpperCase() == code.toUpperCase()) {
        if (mounted) {
          DataExportService.showToast(
            context,
            'Currency is already set to ${info.code} (${info.symbol})',
          );
        }
        return;
      }

      // 1. Convert all transaction amounts and budget in database
      await DatabaseHelper().convertAllTransactionsAndBudget(oldCode, code);

      // 2. Save new currency setting to settings table
      await DatabaseHelper().setSetting('active_currency', code);

      // 3. Update active currency in context
      if (mounted) {
        CurrencyProvider.of(context).value = info;
        setState(() {});
        DataExportService.showToast(
          context,
          'Currency set to ${info.code} (${info.symbol})',
        );
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
    final label = switch (option) {
      ThemeOption.light => 'Light mode',
      ThemeOption.system => 'System theme',
      ThemeOption.dark => 'Dark mode',
    };
    DataExportService.showToast(context, 'Theme set to $label');
  }

  Future<void> _onHapticToggled(bool value) async {
    setState(() {
      _hapticEnabled = value;
    });
    await HapticHelper.setEnabled(value);
    if (value) {
      await HapticHelper.lightImpact();
    }
    if (mounted) {
      DataExportService.showToast(
        context,
        value ? 'Haptic feedback enabled' : 'Haptic feedback disabled',
      );
    }
  }

  Widget _buildSectionHeader(AppColorLocker locker, String title) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
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
    );
  }

  Widget _buildTileContainer({
    required AppColorLocker locker,
    required Widget child,
    VoidCallback? onTap,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: BounceCard(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: locker.settingsCardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: locker.settingsCardBorder,
                width: 1.0,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  void _showBackupRestoreModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final locker = AppColorLocker.of(sheetContext);
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        final mediaQuery = MediaQuery.of(sheetContext);
        final isLandscape = mediaQuery.orientation == Orientation.landscape;
        final maxHeight = mediaQuery.size.height * (isLandscape ? 0.92 : 0.85);

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: locker.sheetBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: locker.sheetBorder,
                    width: 1.0,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 36 : 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Grab handle
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: locker.textTertiary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'BACKUP & RESTORE',
                        style: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: locker.textPrimary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Text(
                          'Save your financial records to local storage, share a backup file, or restore existing records.',
                          textAlign: TextAlign.center,
                          style: AppTypography.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: locker.settingsInfoText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Option 1: Save Backup to Device
                      _buildModalOption(
                        locker,
                        isDark: isDark,
                        title: 'Save Backup to Device (JSON)',
                        subtitle: 'Save JSON snapshot directly to Downloads',
                        icon: Icons.file_download_outlined,
                        iconColor: locker.accentGreen,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          DataExportService.createBackupJson(context, share: false);
                        },
                      ),
                      const SizedBox(height: 14),
                      // Option 2: Share Backup File
                      _buildModalOption(
                        locker,
                        isDark: isDark,
                        title: 'Share Backup File (JSON)',
                        subtitle: 'Send via Chat, Email, or Cloud Drive',
                        icon: Icons.ios_share_rounded,
                        iconColor: locker.textPrimary,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          DataExportService.createBackupJson(context, share: true);
                        },
                      ),
                      const SizedBox(height: 14),
                      // Option 3: Restore from Backup
                      _buildModalOption(
                        locker,
                        isDark: isDark,
                        title: 'Restore from Backup',
                        subtitle: 'Select a JSON backup to restore records',
                        icon: Icons.settings_backup_restore_rounded,
                        iconColor: locker.accentGreen,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          DataExportService.restoreBackupJson(
                            context,
                            onRestored: () {
                              widget.onDataRestored?.call();
                              _loadSettings();
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModalOption(
    AppColorLocker locker, {
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: BounceCard(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: locker.settingsModalTileBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: locker.settingsCardBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTypography.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: locker.settingsInfoText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: locker.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              bottom: 130, // 120px+ clearance above floating navigation bar
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Settings Main Title
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: locker.textPrimary,
                  ),
                ),
                const SizedBox(height: 36),

                // ==========================================
                // SECTION 1: PREFERENCES
                // ==========================================
                _buildSectionHeader(locker, 'PREFERENCES'),
                const SizedBox(height: 18),

                // Appearance Label & Theme Switcher
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Appearance',
                        style: AppTypography.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: locker.settingsInfoText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ThemeSegmentedBar(
                  selectedTheme: _selectedTheme,
                  onThemeChanged: _onThemeChanged,
                ),
                const SizedBox(height: 32),

                // Currency Picker Section
                CurrencyPickerSection(
                  selectedCurrencyCode: _selectedCurrencyCode,
                  onSelectCurrency: _selectCurrency,
                ),
                const SizedBox(height: 32),

                // Reset Interval Selector
                ResetIntervalSelector(
                  selectedInterval: _selectedInterval,
                  onIntervalChanged: _onIntervalChanged,
                ),
                const SizedBox(height: 44),

                // ==========================================
                // SECTION 2: DATA & BACKUP
                // ==========================================
                _buildSectionHeader(locker, 'DATA & BACKUP'),
                const SizedBox(height: 16),

                // Export Data (.CSV) Tile
                _buildTileContainer(
                  locker: locker,
                  onTap: () => DataExportService.exportTransactionsCsv(context, share: false),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: locker.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.file_download_outlined,
                          size: 20,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Export Transactions (.CSV)',
                              style: AppTypography.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: locker.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Save financial records to device',
                              style: AppTypography.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: locker.settingsInfoText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => DataExportService.exportTransactionsCsv(
                          context,
                          share: true,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.ios_share_rounded,
                            size: 18,
                            color: locker.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Backup & Restore Tile
                _buildTileContainer(
                  locker: locker,
                  onTap: () => _showBackupRestoreModal(context),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: locker.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.settings_backup_restore_rounded,
                          size: 20,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Backup & Restore',
                              style: AppTypography.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: locker.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Local JSON snapshot & restore',
                              style: AppTypography.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: locker.settingsInfoText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: locker.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),

                // ==========================================
                // SECTION 3: EXPERIENCE
                // ==========================================
                _buildSectionHeader(locker, 'EXPERIENCE'),
                const SizedBox(height: 16),

                // Haptic Feedback Tile
                _buildTileContainer(
                  locker: locker,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: locker.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.vibration_rounded,
                          size: 20,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Haptic Feedback',
                              style: AppTypography.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: locker.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tactile vibrations on key interactions',
                              style: AppTypography.openSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: locker.settingsInfoText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _hapticEnabled,
                        activeTrackColor: locker.accentGreen,
                        activeThumbColor: locker.textOnDark,
                        onChanged: _onHapticToggled,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 44),

                // ==========================================
                // SECTION 4: LEGAL & ABOUT
                // ==========================================
                _buildSectionHeader(locker, 'LEGAL & ABOUT'),
                const SizedBox(height: 16),

                // Privacy Policy Tile
                _buildTileContainer(
                  locker: locker,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: locker.accentGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: locker.accentGreen,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: AppTypography.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: locker.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: locker.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Terms of Service Tile
                _buildTileContainer(
                  locker: locker,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServiceScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: locker.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 18,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Terms of Service',
                          style: AppTypography.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: locker.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: locker.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // About RADIX Tile
                _buildTileContainer(
                  locker: locker,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: locker.textPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: locker.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'About RADIX',
                              style: AppTypography.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: locker.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Fulton Ngo Corporation',
                              style: TextStyle(
                                fontFamily: 'FontUltra',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: locker.settingsInfoText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: locker.settingsBadgeBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: locker.settingsBadgeBorder,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'v1.0.0',
                          style: AppTypography.openSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: locker.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: locker.textTertiary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // ==========================================
                // SECTION 5: DANGER ZONE
                // ==========================================
                _buildSectionHeader(locker, 'DANGER ZONE'),
                const SizedBox(height: 10),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Permanently wipe all transaction records, monthly limits, and balance calculations stored locally.',
                        style: AppTypography.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: locker.settingsInfoText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Crimson "Hold to Reset" button (5-second fill progress)
                ResetButton(
                  label: 'Hold to Reset',
                  onPressed: () {
                    DataExportService.showToast(
                      context,
                      'Press and hold for 5 seconds to reset all data.',
                    );
                  },
                  onHoldComplete: () {
                    widget.onResetAll();
                    DataExportService.showToast(
                      context,
                      'Your data has been reset.',
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
