import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_tracker/core/theme/theme_provider.dart';
import 'package:finance_tracker/core/theme/currency_provider.dart';
import 'package:finance_tracker/screens/social/social_screen.dart';
import 'package:finance_tracker/screens/profile/profile_screen.dart';

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
  testWidgets('SocialScreen renders minimalist placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWrapper(const SocialScreen()));
    await tester.pumpAndSettle();

    expect(find.text('SOCIAL'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
  });

  testWidgets('ProfileScreen renders minimalist placeholder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWrapper(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('PROFILE'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
  });
}
