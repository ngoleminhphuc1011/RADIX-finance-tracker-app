/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import 'privacy_policy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: locker.settingsBackground,
      appBar: AppBar(
        backgroundColor: locker.settingsBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: locker.textPrimary),
        title: Text(
          'ABOUT RADIX',
          style: TextStyle(
            color: locker.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'MonumentExtended',
          ),
        ),
      ),
      body: SafeArea(
        bottom: true,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            // App Brand Hero Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: locker.settingsCardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: locker.settingsCardBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: locker.navBarShadow,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo/LOGORADIXNEW.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'RADIX',
                    style: TextStyle(
                      fontFamily: 'MonumentExtended',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: locker.textPrimary,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Version badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: locker.settingsBadgeBackground,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: locker.settingsBadgeBorder,
                      ),
                    ),
                    child: Text(
                      'v1.0.0 (Build 2)',
                      style: AppTypography.openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: locker.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Developer Credit Card
            _buildSectionHeader(locker, 'DEVELOPER'),
            const SizedBox(height: 12),
            _buildInfoCard(
              locker,
              isDark: isDark,
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: locker.textPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.business_outlined,
                      color: locker.textPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fulton Ngo Corporation',
                          style: TextStyle(
                            fontFamily: 'FontUltra',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: locker.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Crafted with focus on offline autonomy, privacy, and minimalist financial tracking.',
                          style: AppTypography.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: locker.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Open Source Acknowledgments
            _buildSectionHeader(locker, 'OPEN-SOURCE ACKNOWLEDGMENTS'),
            const SizedBox(height: 12),
            _buildInfoCard(
              locker,
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RADIX is built using high-performance open-source libraries and frameworks:',
                    style: AppTypography.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: locker.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPackageRow(
                    locker,
                    name: 'Flutter SDK',
                    author: 'Google LLC',
                    license: 'BSD 3-Clause',
                  ),
                  _buildPackageDivider(locker),
                  _buildPackageRow(
                    locker,
                    name: 'Sqflite',
                    author: 'Alexandre Roux (tekartik)',
                    license: 'BSD 2-Clause',
                  ),
                  _buildPackageDivider(locker),
                  _buildPackageRow(
                    locker,
                    name: 'FL Chart',
                    author: 'Iman Khoshabi',
                    license: 'MIT License',
                  ),
                  _buildPackageDivider(locker),
                  _buildPackageRow(
                    locker,
                    name: 'Google Fonts',
                    author: 'Google LLC',
                    license: 'OFL / Apache 2.0',
                  ),
                  _buildPackageDivider(locker),
                  _buildPackageRow(
                    locker,
                    name: 'Shared Preferences',
                    author: 'Flutter Community',
                    license: 'BSD 3-Clause',
                  ),
                  _buildPackageDivider(locker),
                  _buildPackageRow(
                    locker,
                    name: 'Intl',
                    author: 'Dart Team',
                    license: 'BSD 3-Clause',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Legal & Privacy Link
            _buildSectionHeader(locker, 'LEGAL & COMPLIANCE'),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(18),
              child: _buildInfoCard(
                locker,
                isDark: isDark,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: locker.textPrimary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: locker.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Privacy Policy',
                            style: AppTypography.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: locker.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Read our offline data protection terms',
                            style: AppTypography.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: locker.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: locker.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Bottom Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 Fulton Ngo Corporation',
                    style: TextStyle(
                      fontFamily: 'FontUltra',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: locker.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All Rights Reserved · Designed with Offline Integrity',
                    style: AppTypography.openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: locker.textTertiary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(AppColorLocker locker, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'MonumentExtended-Regular',
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: locker.settingsSectionLabel,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildInfoCard(
    AppColorLocker locker, {
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: locker.settingsCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: locker.settingsCardBorder,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }

  Widget _buildPackageRow(
    AppColorLocker locker, {
    required String name,
    required String author,
    required String license,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: locker.textPrimary,
                  ),
                ),
                Text(
                  author,
                  style: AppTypography.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: locker.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: locker.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              license,
              style: AppTypography.openSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: locker.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDivider(AppColorLocker locker) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: locker.dividerColor,
      ),
    );
  }
}
