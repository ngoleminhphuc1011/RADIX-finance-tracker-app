import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_tracker/core/services/reset_interval_service.dart';
import 'package:finance_tracker/core/theme/currency_provider.dart';
import 'package:finance_tracker/core/theme/theme_provider.dart';
import 'package:finance_tracker/screens/settings/settings_screen.dart';
import 'package:finance_tracker/screens/settings/widgets/reset_interval_selector.dart';

Widget createTestWrapper(Widget child) {
  return ThemeProvider(
    notifier: ValueNotifier<ThemeMode>(ThemeMode.light),
    child: CurrencyProvider(
      notifier: ValueNotifier<CurrencyInfo>(CurrencyInfo.find('USD')),
      child: MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(
          body: child,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ResetIntervalService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getResetIntervalMonths defaults to 1 month', () async {
      final interval = await ResetIntervalService.getResetIntervalMonths();
      expect(interval, 1);
    });

    test('setResetIntervalMonths persists and clamps values between 1 and 6', () async {
      await ResetIntervalService.setResetIntervalMonths(3);
      expect(await ResetIntervalService.getResetIntervalMonths(), 3);

      await ResetIntervalService.setResetIntervalMonths(0);
      expect(await ResetIntervalService.getResetIntervalMonths(), 1);

      await ResetIntervalService.setResetIntervalMonths(10);
      expect(await ResetIntervalService.getResetIntervalMonths(), 6);
    });

    test('getLastResetTimestamp defaults to 1st of the current month', () async {
      final timestamp = await ResetIntervalService.getLastResetTimestamp();
      final now = DateTime.now();
      expect(timestamp.year, now.year);
      expect(timestamp.month, now.month);
      expect(timestamp.day, 1);
    });

    test('calculateDeltaMonths correctly computes elapsed months across years', () {
      final lastReset = DateTime(2026, 1, 1);
      final nowSameYear = DateTime(2026, 4, 15);
      expect(ResetIntervalService.calculateDeltaMonths(nowSameYear, lastReset), 3);

      final nowNextYear = DateTime(2027, 2, 10);
      expect(ResetIntervalService.calculateDeltaMonths(nowNextYear, lastReset), 13);
    });

    test('isResetDue triggers only when deltaMonths >= intervalMonths', () {
      final lastReset = DateTime(2026, 6, 1);

      // 1 month interval
      expect(
        ResetIntervalService.isResetDue(
          now: DateTime(2026, 6, 25),
          lastReset: lastReset,
          intervalMonths: 1,
        ),
        isFalse,
      );
      expect(
        ResetIntervalService.isResetDue(
          now: DateTime(2026, 7, 1),
          lastReset: lastReset,
          intervalMonths: 1,
        ),
        isTrue,
      );

      // 3 month interval
      expect(
        ResetIntervalService.isResetDue(
          now: DateTime(2026, 8, 30),
          lastReset: lastReset,
          intervalMonths: 3,
        ),
        isFalse,
      );
      expect(
        ResetIntervalService.isResetDue(
          now: DateTime(2026, 9, 1),
          lastReset: lastReset,
          intervalMonths: 3,
        ),
        isTrue,
      );
    });
  });

  group('ResetIntervalSelector Widget Tests', () {
    testWidgets('renders header, all 6 options, and initial description', (WidgetTester tester) async {
      int selected = 1;

      await tester.pumpWidget(
        createTestWrapper(
          StatefulBuilder(
            builder: (context, setState) {
              return ResetIntervalSelector(
                selectedInterval: selected,
                onIntervalChanged: (val) {
                  setState(() => selected = val);
                },
              );
            },
          ),
        ),
      );

      // Check header
      expect(find.text('RESET INTERVAL'), findsOneWidget);

      // Check initial 1M description
      expect(find.text('Cycle resets automatically every month'), findsOneWidget);

      // Check all 6 option pills [1M, 2M, 3M, 4M, 5M, 6M]
      for (int i = 1; i <= 6; i++) {
        expect(find.text('${i}M'), findsOneWidget);
      }

      // Tap 3M
      await tester.tap(find.text('3M'));
      await tester.pumpAndSettle();

      expect(selected, 3);
      expect(find.text('Cycle resets automatically every 3 months'), findsOneWidget);
    });

    testWidgets('SettingsScreen restores saved interval on reopen and persists new selection', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'reset_interval_months': 5,
      });

      // First open — loads saved 5M
      await tester.pumpWidget(
        createTestWrapper(
          SettingsScreen(onResetAll: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cycle resets automatically every 5 months'), findsOneWidget);

      // User selects 2M in SettingsScreen
      await tester.ensureVisible(find.text('2M'));
      await tester.tap(find.text('2M'));
      await tester.pumpAndSettle();

      expect(find.text('Cycle resets automatically every 2 months'), findsOneWidget);
      expect(await ResetIntervalService.getResetIntervalMonths(), 2);

      // Simulate app kill & reopen by pumping a fresh SettingsScreen instance
      await tester.pumpWidget(
        createTestWrapper(
          SettingsScreen(onResetAll: () {}),
        ),
      );
      await tester.pumpAndSettle();

      // Verify restored selection
      expect(find.text('Cycle resets automatically every 2 months'), findsOneWidget);
    });
  });

  group('Cycle Reset Logic Tests', () {
    test('Reset is executed when delta exceeds interval and updates timestamp', () async {
      SharedPreferences.setMockInitialValues({});

      // Set last reset to 3 months ago (July 2026)
      final pastDate = DateTime(2026, 7, 1);
      await ResetIntervalService.setLastResetTimestamp(pastDate);
      await ResetIntervalService.setResetIntervalMonths(3);

      final now = DateTime(2026, 10, 2);
      final lastReset = await ResetIntervalService.getLastResetTimestamp();
      final interval = await ResetIntervalService.getResetIntervalMonths();

      // Verify reset is due
      final isDue = ResetIntervalService.isResetDue(
        now: now,
        lastReset: lastReset,
        intervalMonths: interval,
      );
      expect(isDue, isTrue);

      // Simulate cycle reset update
      final currentCycleStart = DateTime(now.year, now.month, 1);
      await ResetIntervalService.setLastResetTimestamp(currentCycleStart);

      // Verify new timestamp is updated to current cycle start
      final updatedTimestamp = await ResetIntervalService.getLastResetTimestamp();
      expect(updatedTimestamp.year, 2026);
      expect(updatedTimestamp.month, 10);
      expect(updatedTimestamp.day, 1);

      // Now reset should no longer be due
      expect(
        ResetIntervalService.isResetDue(
          now: now,
          lastReset: updatedTimestamp,
          intervalMonths: interval,
        ),
        isFalse,
      );
    });
  });
}
