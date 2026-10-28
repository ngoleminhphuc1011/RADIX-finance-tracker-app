import 'package:flutter/material.dart';
import '../../core/theme/app_color_locker.dart';
import '../../core/theme/app_typography.dart';

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
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(scrollbars: false),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: [
            // Section 1: Transactions
            _buildSection(
              locker,
              title: '1. RECORD & MANAGE TRANSACTIONS',
              icon: Icons.add_card_outlined,
              body:
                  '• Tap the "+" button on the Home screen to log an Expense or Income.\n'
                  '• For Income, choose a strategy: "Deduct from Spent" (refunds/cashback) or "Add to Budget" (salary/bonus).\n'
                  '• Tap any transaction tile in your feed to expand inline controls: edit title, amount, category, or delete.',
            ),
            const SizedBox(height: 26),

            // Section 2: Budgeting
            _buildSection(
              locker,
              title: '2. BUDGETING & BALANCE TRACKING',
              icon: Icons.account_balance_wallet_outlined,
              body:
                  '• Tap the balance card at the top of Home to set or adjust your monthly budget limit.\n'
                  '• Track your Monthly Budget, Total Spent, and Remaining Balance in real time with self-healing calculations.',
            ),
            const SizedBox(height: 26),

            // Section 3: Analytics & Charts
            _buildSection(
              locker,
              title: '3. EXPENSE ANALYTICS & DRILL-DOWN',
              icon: Icons.donut_large_outlined,
              body:
                  '• Navigate to the Analytics tab to visualize spending distribution across categories via the Donut Chart.\n'
                  '• Tap any category in the breakdown list below the chart to view a detailed drill-down of all its records.',
            ),
            const SizedBox(height: 26),

            // Section 4: Multi-Currency
            _buildSection(
              locker,
              title: '4. MULTI-CURRENCY CONVERSION',
              icon: Icons.currency_exchange_outlined,
              body:
                  '• Select your preferred currency in Settings (USD, EUR, CNY, VND, GBP, JPY, AUD, CAD).\n'
                  '• All transaction amounts and monthly budgets convert automatically using baseline exchange rates.',
            ),
            const SizedBox(height: 26),

            // Section 5: Reset Intervals
            _buildSection(
              locker,
              title: '5. AUTOMATIC CYCLE RESET',
              icon: Icons.update_outlined,
              body:
                  '• Choose your budget reset interval in Settings: 1M, 2M, 3M, 4M, 5M, or 6M (every 1 to 6 months).\n'
                  '• When a new cycle begins, Radix resets your spent counter for the new cycle while preserving your budget limit.',
            ),
            const SizedBox(height: 26),

            // Section 6: Data Export & Backup
            _buildSection(
              locker,
              title: '6. BACKUP, RESTORE & CSV EXPORT',
              icon: Icons.cloud_sync_outlined,
              body:
                  '• Export your financial records to CSV spreadsheets to view or share in Excel or Google Sheets.\n'
                  '• Save or share complete JSON backups, or restore past data anytime under Settings > Data & Backup.',
            ),
            const SizedBox(height: 26),

            // Section 7: Responsive Layout & Haptics
            _buildSection(
              locker,
              title: '7. LANDSCAPE DASHBOARD & HAPTICS',
              icon: Icons.screen_rotation_outlined,
              body:
                  '• Rotate your device to Landscape mode to access an expanded 2-column split-view financial workspace.\n'
                  '• Toggle tactile haptic feedback in Settings for pleasant physical feedback when interacting with buttons.',
            ),
            const SizedBox(height: 26),

            // Section 8: Danger Zone (Reset)
            _buildSection(
              locker,
              title: '8. RESET ALL DATA',
              icon: Icons.restart_alt_outlined,
              body:
                  '• Wipe all transaction records and reset your budget to start fresh.\n'
                  '• Go to Settings > Danger Zone, then press and hold the reset button for 5 seconds to confirm.\n'
                  '• Your theme and currency preferences will be preserved.',
              isWarning: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
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
            style: AppTypography.openSans(
              color: isWarning
                  ? locker.instructionWarningColor
                  : locker.instructionBodyColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}
