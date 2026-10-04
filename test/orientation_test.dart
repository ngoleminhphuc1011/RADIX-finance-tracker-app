import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/theme/theme_provider.dart';
import 'package:finance_tracker/core/theme/currency_provider.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/screens/home/home_screen.dart';

Widget createTestHomeScreen({
  required Size screenSize,
  required List<TransactionModel> transactions,
}) {
  return MediaQuery(
    data: MediaQueryData(size: screenSize),
    child: ThemeProvider(
      notifier: ValueNotifier<ThemeMode>(ThemeMode.light),
      child: CurrencyProvider(
        notifier: ValueNotifier<CurrencyInfo>(CurrencyInfo.find('USD')),
        child: MaterialApp(
          home: HomeScreen(
            transactions: transactions,
            onAddTransaction: (_) {},
            onDeleteTransaction: (_) {},
            monthlyBudget: 500,
            spent: 150,
            budgetLeft: 350,
            onBudgetChanged: (_) {},
            onSpentChanged: (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'HomeScreen renders in Portrait mode with intact 1-column layout',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestHomeScreen(
          screenSize: const Size(400, 800),
          transactions: [],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('RADIX'), findsOneWidget);
      expect(find.text('SPENT'), findsOneWidget);
      expect(find.text("PRESS '+' TO ADD\nTRANSACTION"), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    },
  );

  testWidgets('HomeScreen renders in Landscape mode with 2-column split-view', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(800, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final transactions = [
      TransactionModel(
        id: 1,
        title: 'Dinner',
        amount: 35.0,
        date: '2026-10-02',
        category: 'fastfood',
        type: 'expense',
      ),
    ];

    await tester.pumpWidget(
      createTestHomeScreen(
        screenSize: const Size(800, 400),
        transactions: transactions,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('RADIX'), findsOneWidget);
    expect(find.text('SPENT'), findsOneWidget);
    expect(find.text('ADD TRANSACTION'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    // Floating action button is omitted in landscape in favor of the left column Add Action
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
