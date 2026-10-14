import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/theme/currency_provider.dart';
import 'package:finance_tracker/core/theme/theme_provider.dart';
import 'package:finance_tracker/screens/settings/widgets/currency_picker_section.dart';

Widget createTestWrapper(Widget child) {
  return ThemeProvider(
    notifier: ValueNotifier<ThemeMode>(ThemeMode.light),
    child: CurrencyProvider(
      notifier: ValueNotifier<CurrencyInfo>(CurrencyInfo.find('USD')),
      child: MaterialApp(
        theme: ThemeData.light(),
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('CurrencyInfo Conversion Unit Tests', () {
    test('USD to VND conversion matches exchange rate ratio', () {
      // 100 USD at rate 26260.0
      final double vnd = CurrencyInfo.convert(100.0, 'USD', 'VND');
      expect(vnd, 2626000.0);
    });

    test('VND to USD conversion rounds properly to double', () {
      final double usd = CurrencyInfo.convert(2626000.0, 'VND', 'USD');
      expect(usd, 100.0);
    });

    test('Same currency conversion returns exact amount', () {
      final double res = CurrencyInfo.convert(250.0, 'EUR', 'EUR');
      expect(res, 250.0);
    });

    test('Negative amounts clamp to 0.0', () {
      final double res = CurrencyInfo.convert(-50.0, 'USD', 'VND');
      expect(res, 0.0);
    });

    test('Zero amount converts to zero', () {
      final double res = CurrencyInfo.convert(0.0, 'USD', 'JPY');
      expect(res, 0.0);
    });

    test('All exchange rates are positive numbers', () {
      for (final code in CurrencyInfo.exchangeRates.keys) {
        expect(CurrencyInfo.exchangeRates[code]! > 0, isTrue);
      }
    });
  });

  group('CurrencyPickerSection Widget Tests', () {
    testWidgets('renders CurrencyPickerSection with active currency code', (
      WidgetTester tester,
    ) async {
      String selectedCode = 'USD';

      await tester.pumpWidget(
        createTestWrapper(
          CurrencyPickerSection(
            selectedCurrencyCode: selectedCode,
            onSelectCurrency: (code) => selectedCode = code,
          ),
        ),
      );

      expect(find.text('CURRENCY'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('US Dollar (\$)'), findsOneWidget);
    });

    testWidgets('tapping Currency tile opens selection bottom sheet', (
      WidgetTester tester,
    ) async {
      String selectedCode = 'USD';

      await tester.pumpWidget(
        createTestWrapper(
          CurrencyPickerSection(
            selectedCurrencyCode: selectedCode,
            onSelectCurrency: (code) => selectedCode = code,
          ),
        ),
      );

      await tester.tap(find.text('Currency'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT CURRENCY'), findsOneWidget);
      expect(find.text('VND - Vietnam Dong'), findsOneWidget);
      expect(find.text('EUR - Euro'), findsOneWidget);

      await tester.tap(find.text('VND - Vietnam Dong'));
      await tester.pumpAndSettle();

      expect(selectedCode, 'VND');
    });
  });
}
