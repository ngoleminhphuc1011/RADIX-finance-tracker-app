/* Hallmark · pre-emit critique: P5 H5 E5 S5 R5 V5 */
import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'TERMS OF SERVICE',
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

            // Section 1: Agreement & Purpose
            _buildTermsSection(
              locker,
              title: '1. AGREEMENT & PURPOSE',
              icon: Icons.handshake_outlined,
              body:
                  'RADIX is an autonomous, offline-first personal financial tracking utility designed '
                  'solely for individual accounting and personal budgeting convenience. By launching, '
                  'installing, or utilizing RADIX, you agree to be bound by these Terms of Service.',
            ),
            _buildDivider(context),

            // Section 2: License & Ownership
            _buildTermsSection(
              locker,
              title: '2. LICENSE & OWNERSHIP',
              icon: Icons.verified_user_outlined,
              body:
                  'RADIX is developed and distributed by Fulton Ngo Corporation. You are granted a personal, '
                  'non-exclusive, non-transferable, and revocable license to utilize the application for private, '
                  'non-commercial expense tracking. All proprietary branding, logos, and typography rights remain '
                  'reserved by Fulton Ngo Corporation and their respective authors.',
            ),
            _buildDivider(context),

            // Section 3: Local Data Responsibility
            _buildTermsSection(
              locker,
              title: '3. LOCAL DATA RESPONSIBILITY',
              icon: Icons.storage_rounded,
              body:
                  'RADIX adheres to a strict zero-cloud architecture. All financial records, budget configurations, '
                  'and balance computations reside exclusively on your physical device. You assume sole '
                  'responsibility for managing data exports (.CSV), maintaining JSON backups, and securing your '
                  'device against unauthorized physical access or unexpected OS data clearance.',
            ),
            _buildDivider(context),

            // Section 4: Disclaimer of Financial Advice
            _buildTermsSection(
              locker,
              title: '4. DISCLAIMER OF FINANCIAL ADVICE',
              icon: Icons.gavel_outlined,
              body:
                  'RADIX is strictly an arithmetic calculation and historical record-keeping tool. RADIX, '
                  'Fulton Ngo Corporation, and its authors are not registered investment advisers, broker-dealers, '
                  'or licensed fiduciaries. Nothing provided within the application, its category breakdowns, or its '
                  'trend graphs constitutes investment, legal, or professional financial advice.',
            ),
            const SizedBox(height: 36),

            // Bottom Policy Timestamp Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Effective as of October 2026',
                    style: AppTypography.openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: locker.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fulton Ngo Corporation',
                    style: TextStyle(
                      fontFamily: 'FontUltra',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: locker.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(
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
      child: Divider(height: 1, thickness: 1, color: locker.dividerColor),
    );
  }
}
