/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);

    return Scaffold(
      backgroundColor: locker.settingsBackground,
      appBar: AppBar(
        backgroundColor: locker.settingsBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: locker.textPrimary),
        title: Text(
          'PRIVACY POLICY',
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
            const SizedBox(height: 12),

            // Section 1: Overview
            _buildPolicySection(
              locker,
              title: '1. OVERVIEW',
              icon: Icons.lock_outline_rounded,
              body:
                  'RADIX is engineered with a strict offline-first, privacy-by-design philosophy. '
                  'We firmly believe that personal financial records belong solely to you and must never reside '
                  'on remote corporate servers or unverified cloud environments.',
            ),
            _buildDivider(context),

            // Section 2: Local Storage
            _buildPolicySection(
              locker,
              title: '2. LOCAL STORAGE',
              icon: Icons.storage_rounded,
              body:
                  'All transactions, monthly spending limits, category assignments, and balance calculations '
                  'reside strictly on your local device within an isolated SQLite database (radix_database.db). '
                  'No financial telemetry, logs, or backups are ever automatically sent to remote servers.',
            ),
            _buildDivider(context),

            // Section 3: Third-party Services
            _buildPolicySection(
              locker,
              title: '3. THIRD-PARTY SERVICES',
              icon: Icons.cloud_off_rounded,
              body:
                  'RADIX contains zero advertising trackers, zero user behavior telemetry SDKs, '
                  'and zero profiling frameworks. We do not sell, monetize, transmit, or share your financial '
                  'data with financial institutions, advertisers, or analytics brokers.',
            ),
            _buildDivider(context),

            // Section 4: User Rights & Data Deletion
            _buildPolicySection(
              locker,
              title: '4. USER RIGHTS & DATA DELETION',
              icon: Icons.delete_sweep_outlined,
              body:
                  'You retain complete 100% control over your data. You can instantly purge all transactions '
                  'and budget entries at any time using the "Hold to Reset" button in Settings, or clear app data '
                  'directly through your operating system settings without leaving residual data behind.',
            ),
            const SizedBox(height: 36),

            // Bottom Policy Timestamp Footer
            Center(
              child: Text(
                'Effective as of October 2026 · Fulton Ngo Corporation',
                style: AppTypography.openSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: locker.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPolicySection(
    AppColorLocker locker, {
    required String title,
    required IconData icon,
    required String body,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: locker.textPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: locker.textPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: locker.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MonumentExtended-Regular',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            body,
            style: AppTypography.openSans(
              color: locker.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: locker.dividerColor,
      ),
    );
  }
}
