import 'package:flutter/material.dart';
import '../../core/theme/app_color_locker.dart';

class InstructionScreen extends StatelessWidget {
  const InstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return Scaffold(
      backgroundColor: locker.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: locker.scaffoldBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: locker.textPrimary),
        title: Text(
          'INSTRUCTION',
          style: TextStyle(
            color: locker.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontFamily: 'MonumentExtended',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          // Section 1
          _buildSection(
            locker,
            title: '1. RECORD TRANSACTIONS',
            icon: Icons.add_card_outlined,
            body:
                '- Tap the "+" button at the bottom of the Home screen.\n'
                '- Select Expense or Income, pick a category icon, enter amount and save.',
          ),
          const SizedBox(height: 28),

          // Section 2
          _buildSection(
            locker,
            title: '2. MONTHLY BUDGETING',
            icon: Icons.track_changes_outlined,
            body:
                '- Set your monthly spending limit on the Home screen.\n'
                '- Track spent vs. remaining budget instantly as you add records.',
          ),
          const SizedBox(height: 28),

          // Section 3
          _buildSection(
            locker,
            title: '3. CHARTS & ANALYTICS',
            icon: Icons.analytics_outlined,
            body:
                '- View cash flow trends and category shares on the Charts tab.\n'
                '- Tap chart slices to view detailed percentage breakdowns.',
          ),
          const SizedBox(height: 28),

          // Section 4
          _buildSection(
            locker,
            title: '4. CURRENCY SETTINGS',
            icon: Icons.currency_exchange_outlined,
            body:
                '- Change active currency in Settings (USD, EUR, CNY, VND, etc.).\n'
                '- Note: Base values will convert and may update when returning.',
            isWarning: true,
          ),
          const SizedBox(height: 28),

          // Section 5
          _buildSection(
            locker,
            title: '5. RESET ALL DATA',
            icon: Icons.restart_alt_outlined,
            body:
                '- Wipe all transaction records and settings to start fresh.\n'
                '- Go to Settings and hold the reset button for 3 seconds.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    AppColorLocker locker, {
    required String title,
    required IconData icon,
    required String body,
    bool isWarning = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: locker.instructionIconColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: locker.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'MonumentExtended-Regular',
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 30),
          child: Text(
            body,
            style: TextStyle(
              color: isWarning
                  ? locker.instructionWarningColor
                  : locker.instructionBodyColor,
              fontSize: 12.5,
              height: 1.6,
              fontFamily: 'MonumentExtended-Regular',
            ),
          ),
        ),
      ],
    );
  }
}
