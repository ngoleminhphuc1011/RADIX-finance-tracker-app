import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_tracker/core/theme/theme_provider.dart';
import 'package:finance_tracker/core/theme/currency_provider.dart';
import 'package:finance_tracker/core/services/haptic_helper.dart';
import 'package:finance_tracker/screens/settings/legal/privacy_policy_screen.dart';
import 'package:finance_tracker/screens/settings/legal/terms_screen.dart';
import 'package:finance_tracker/screens/settings/legal/about_screen.dart';
import 'package:finance_tracker/screens/settings/settings_screen.dart';

Widget createTestWrapper(Widget child) {
  return ThemeProvider(
    notifier: ValueNotifier<ThemeMode>(ThemeMode.light),
    child: CurrencyProvider(
      notifier: ValueNotifier<CurrencyInfo>(CurrencyInfo.find('USD')),
      child: MaterialApp(theme: ThemeData.light(), home: child),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'PrivacyPolicyScreen renders AppBar and all 4 policy sections without capsule badge',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWrapper(const PrivacyPolicyScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('PRIVACY POLICY'), findsOneWidget);
      expect(find.text('OFFLINE FIRST · ZERO TELEMETRY'), findsNothing);
      expect(find.text('1. OVERVIEW'), findsOneWidget);
      expect(find.text('2. LOCAL STORAGE'), findsOneWidget);
      expect(find.text('3. THIRD-PARTY SERVICES'), findsOneWidget);
      expect(find.text('4. USER RIGHTS & DATA DELETION'), findsOneWidget);
    },
  );

  testWidgets(
    'TermsOfServiceScreen renders AppBar and all 4 terms sections',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWrapper(const TermsOfServiceScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('TERMS OF SERVICE'), findsOneWidget);
      expect(find.text('1. AGREEMENT & PURPOSE'), findsOneWidget);
      expect(find.text('2. LICENSE & OWNERSHIP'), findsOneWidget);
      expect(find.text('3. LOCAL DATA RESPONSIBILITY'), findsOneWidget);
      expect(find.text('4. DISCLAIMER OF FINANCIAL ADVICE'), findsOneWidget);
      expect(find.text('Fulton Ngo Corporation'), findsOneWidget);
    },
  );

  testWidgets(
    'AboutScreen renders brand info, version badge, developer credit, and packages',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(createTestWrapper(const AboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('ABOUT RADIX'), findsOneWidget);
      expect(find.text('RADIX'), findsOneWidget);
      expect(find.text('v1.0.0 (Build 2)'), findsOneWidget);
      expect(find.text('Fulton Ngo Corporation'), findsWidgets);
      expect(find.text('OPEN-SOURCE ACKNOWLEDGMENTS'), findsOneWidget);
      expect(find.text('Flutter SDK'), findsOneWidget);
      expect(find.text('Sqflite'), findsOneWidget);
      expect(find.text('FL Chart'), findsOneWidget);
    },
  );

  testWidgets(
    'SettingsScreen renders all 5 organized sections and navigates correctly',
    (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWrapper(SettingsScreen(onResetAll: () {})),
      );
      await tester.pumpAndSettle();

      // Check all 5 section headers
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('DATA & BACKUP'), findsOneWidget);
      expect(find.text('EXPERIENCE'), findsOneWidget);
      expect(find.text('LEGAL & ABOUT'), findsOneWidget);
      expect(find.text('DANGER ZONE'), findsOneWidget);

      // Section 2: Data & Backup tiles
      expect(find.text('Export Transactions (.CSV)'), findsOneWidget);
      expect(find.text('Backup & Restore'), findsOneWidget);

      // Section 3: Experience (Haptic feedback toggle)
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Section 4: Legal & About tiles
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('About RADIX'), findsOneWidget);

      // Section 5: Danger Zone
      expect(find.text('Hold to Reset'), findsOneWidget);

      // Verify Terms of Service navigation
      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();
      expect(find.text('TERMS OF SERVICE'), findsOneWidget);

      // Pop back to settings
      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      // Verify Privacy Policy navigation
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('PRIVACY POLICY'), findsOneWidget);
    },
  );

  test('HapticHelper persists enabled state in SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({'haptic_feedback_enabled': true});
    expect(await HapticHelper.isEnabled(), isTrue);

    await HapticHelper.setEnabled(false);
    expect(await HapticHelper.isEnabled(), isFalse);

    await HapticHelper.setEnabled(true);
    expect(await HapticHelper.isEnabled(), isTrue);
  });
}
