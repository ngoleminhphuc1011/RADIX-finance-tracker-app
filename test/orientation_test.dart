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
    expect(find.text('Sort: Date'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    // Floating action button is omitted in landscape in favor of the left column Add Action
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets(
    'HomeScreen correctly calculates and displays daily group header totals',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final transactions = [
        // Day 1: October 2, 2026 - Multiple expenses: 45 + 25 = 70 -> -$70
        TransactionModel(
          id: 1,
          title: 'Lunch',
          amount: 45.0,
          date: '2026-10-02',
          category: 'fastfood',
          type: 'expense',
        ),
        TransactionModel(
          id: 2,
          title: 'Coffee',
          amount: 25.0,
          date: '2026-10-02',
          category: 'fastfood',
          type: 'expense',
        ),
        // Day 2: October 1, 2026 - Income 100 + Expense 30 = +70 -> +$70
        TransactionModel(
          id: 3,
          title: 'Bonus',
          amount: 100.0,
          date: '2026-10-01',
          category: 'payments',
          type: 'income',
        ),
        TransactionModel(
          id: 4,
          title: 'Transport',
          amount: 30.0,
          date: '2026-10-01',
          category: 'directions_car',
          type: 'expense',
        ),
      ];

      await tester.pumpWidget(
        createTestHomeScreen(
          screenSize: const Size(400, 800),
          transactions: transactions,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Day 1 header: OCTOBER 2, 2026 and total -$70
      expect(find.text('OCTOBER 2, 2026'), findsOneWidget);
      expect(find.text('-\$70'), findsOneWidget);

      // Verify Day 2 header: OCTOBER 1, 2026 and total +$70
      expect(find.text('OCTOBER 1, 2026'), findsOneWidget);
      expect(find.text('+\$70'), findsOneWidget);
    },
  );

  testWidgets(
    'Demonstrates orientation rotation issue when PageView is unmounted vs preserved in Stack',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = PageController(initialPage: 2);
      int currentIndex = 2;

      Widget buildTree({
        required bool isLandscape,
        required bool preserveInStack,
      }) {
        final pageView = PageView(
          controller: controller,
          onPageChanged: (i) => currentIndex = i,
          children: List.generate(5, (i) => Center(child: Text('Screen $i'))),
        );

        return MaterialApp(
          home: Scaffold(
            body: preserveInStack
                ? Stack(
                    children: [
                      pageView,
                      if (isLandscape)
                        const Positioned(top: 0, child: Text('Landscape Nav')),
                    ],
                  )
                : (isLandscape
                      ? Stack(
                          children: [
                            pageView,
                            const Positioned(
                              top: 0,
                              child: Text('Landscape Nav'),
                            ),
                          ],
                        )
                      : pageView),
          ),
        );
      }

      // 1. Initial portrait render:
      await tester.pumpWidget(
        buildTree(isLandscape: false, preserveInStack: false),
      );
      await tester.pumpAndSettle();
      expect(find.text('Screen 2'), findsOneWidget);

      // Navigate to Settings (screen 4)
      controller.jumpToPage(4);
      await tester.pumpAndSettle();
      expect(find.text('Screen 4'), findsOneWidget);
      expect(currentIndex, 4);

      // 2. Rotate to landscape WITH unmounting (preserveInStack: false)
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpWidget(
        buildTree(isLandscape: true, preserveInStack: false),
      );
      await tester.pumpAndSettle();

      // Confirms the root cause: without unified Stack, PageView unmounts and resets to screen 2
      expect(find.text('Screen 2'), findsOneWidget);
      expect(find.text('Screen 4'), findsNothing);

      // 3. Now test WITH preserveInStack: true
      tester.view.physicalSize = const Size(400, 800);
      final preservedController = PageController(initialPage: 2);
      int preservedIndex = 2;

      Widget buildPreservedTree({required bool isLandscape}) {
        return MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                PageView(
                  key: const PageStorageKey('preserved_pv'),
                  controller: preservedController,
                  onPageChanged: (i) => preservedIndex = i,
                  children: List.generate(
                    5,
                    (i) => Center(child: Text('Preserved Screen $i')),
                  ),
                ),
                if (isLandscape)
                  const Positioned(top: 0, child: Text('Landscape Nav')),
              ],
            ),
          ),
        );
      }

      await tester.pumpWidget(buildPreservedTree(isLandscape: false));
      await tester.pumpAndSettle();
      preservedController.jumpToPage(4);
      await tester.pumpAndSettle();
      expect(find.text('Preserved Screen 4'), findsOneWidget);

      // Rotate to landscape
      tester.view.physicalSize = const Size(800, 400);
      await tester.pumpWidget(buildPreservedTree(isLandscape: true));
      await tester.pumpAndSettle();
      expect(find.text('Preserved Screen 4'), findsOneWidget);
      expect(preservedIndex, 4);

      // Rotate back to portrait
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(buildPreservedTree(isLandscape: false));
      await tester.pumpAndSettle();
      expect(find.text('Preserved Screen 4'), findsOneWidget);
      expect(preservedIndex, 4);
    },
  );

  testWidgets('Tapping balance card opens budget dialog and saves', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    double? newBudget;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: ThemeProvider(
          notifier: ValueNotifier<ThemeMode>(ThemeMode.light),
          child: CurrencyProvider(
            notifier: ValueNotifier<CurrencyInfo>(CurrencyInfo.find('USD')),
            child: MaterialApp(
              home: Scaffold(
                body: HomeScreen(
                  transactions: const [],
                  onAddTransaction: (_) {},
                  onDeleteTransaction: (_) {},
                  monthlyBudget: 500,
                  spent: 150,
                  budgetLeft: 350,
                  onBudgetChanged: (b) => newBudget = b,
                  onSpentChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('SPENT'));
    await tester.pumpAndSettle();

    expect(find.text('ENTER MONTHLY BUDGET'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '1200');
    await tester.pumpAndSettle();

    await tester.tap(find.text('SAVE BUDGET'));
    await tester.pumpAndSettle();

    expect(newBudget, 1200.0);
  });
}
