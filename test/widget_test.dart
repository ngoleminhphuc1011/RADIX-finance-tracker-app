import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/theme/theme_provider.dart';
import 'package:finance_tracker/core/theme/currency_provider.dart';
import 'package:finance_tracker/models/transaction_model.dart';
import 'package:finance_tracker/screens/splash/widgets/money_loop_animation.dart';
import 'package:finance_tracker/screens/settings/widgets/theme_segmented_bar.dart';
import 'package:finance_tracker/screens/settings/widgets/reset_button.dart';
import 'package:finance_tracker/screens/home/widgets/bounce_card.dart';
import 'package:finance_tracker/screens/home/widgets/transaction_tile.dart';
import 'package:finance_tracker/screens/graph/widgets/graph_models.dart';
import 'package:finance_tracker/screens/graph/widgets/category_breakdown_list.dart';

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
  testWidgets('MoneyLoopAnimation renders dollar symbol', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWrapper(const MoneyLoopAnimation()));
    expect(find.text('\$'), findsOneWidget);
  });

  testWidgets('ThemeSegmentedBar displays all theme options', (
    WidgetTester tester,
  ) async {
    ThemeOption selected = ThemeOption.light;
    await tester.pumpWidget(
      createTestWrapper(
        ThemeSegmentedBar(
          selectedTheme: selected,
          onThemeChanged: (opt) => selected = opt,
        ),
      ),
    );

    expect(find.text('LIGHT'), findsOneWidget);
    expect(find.text('SYSTEM'), findsOneWidget);
    expect(find.text('DARK'), findsOneWidget);

    await tester.tap(find.text('DARK'));
    await tester.pump();
    expect(selected, ThemeOption.dark);
  });

  testWidgets('BounceCard responds to tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      createTestWrapper(
        BounceCard(onTap: () => tapped = true, child: const Text('Tap Me')),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);
    await tester.tap(find.text('Tap Me'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('ResetButton renders and triggers callback', (
    WidgetTester tester,
  ) async {
    bool pressed = false;
    await tester.pumpWidget(
      createTestWrapper(ResetButton(onPressed: () => pressed = true)),
    );

    expect(find.text('Reset'), findsOneWidget);
    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(pressed, isTrue);
  });

  testWidgets('TransactionTile renders transaction data', (
    WidgetTester tester,
  ) async {
    final tx = TransactionModel(
      id: 1,
      title: 'Groceries',
      amount: 45.50,
      date: '2026-10-02',
      category: 'fastfood',
      type: 'expense',
    );

    await tester.pumpWidget(createTestWrapper(TransactionTile(model: tx)));

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('- \$46'), findsOneWidget);
  });

  testWidgets('CategoryBreakdownList renders category items and percentages', (
    WidgetTester tester,
  ) async {
    final categories = [
      const AggregatedCategory(
        iconKey: 'fastfood',
        name: 'Food',
        icon: Icons.fastfood_outlined,
        color: Colors.amber,
        amount: 50.0,
      ),
      const AggregatedCategory(
        iconKey: 'shopping_bag',
        name: 'Shopping',
        icon: Icons.shopping_bag_outlined,
        color: Colors.blue,
        amount: 50.0,
      ),
    ];

    String? selectedKey;
    await tester.pumpWidget(
      createTestWrapper(
        CategoryBreakdownList(
          categories: categories,
          totalSpent: 100.0,
          onCategorySelected: (key) => selectedKey = key,
        ),
      ),
    );

    expect(find.text('BREAKDOWN'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('50.0%'), findsNWidgets(2));

    await tester.tap(find.text('Food'));
    await tester.pump();
    expect(selectedKey, 'fastfood');
  });
}
