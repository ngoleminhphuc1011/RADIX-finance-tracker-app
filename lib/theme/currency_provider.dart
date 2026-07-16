import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });

  static const List<CurrencyInfo> all = [
    CurrencyInfo(code: 'USD', symbol: '\$', name: 'US Dollar'),
    CurrencyInfo(code: 'EUR', symbol: '€', name: 'Euro'),
    CurrencyInfo(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    CurrencyInfo(code: 'VND', symbol: '₫', name: 'Vietnam Dong'),
    CurrencyInfo(code: 'GBP', symbol: '£', name: 'British Pound'),
    CurrencyInfo(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    CurrencyInfo(code: 'AUD', symbol: '\$', name: 'Australian Dollar'),
    CurrencyInfo(code: 'CAD', symbol: '\$', name: 'Canadian Dollar'),
  ];

  static const Map<String, double> exchangeRates = {
    'USD': 1.0000,
    'EUR': 0.8760,
    'CNY': 6.7800,
    'VND': 26260.0,
    'GBP': 0.7470,
    'JPY': 161.7000,
    'AUD': 1.4400,
    'CAD': 1.3500,
  };

  static CurrencyInfo find(String code) {
    return all.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => all.first,
    );
  }

  /// Formats double to a rounded whole integer with the currency symbol.
  /// Prevents any values below 0.
  String format(double amount) {
    if (amount < 0) amount = 0;
    final formatter = NumberFormat('#,###');
    return '$symbol${formatter.format(amount.round())}';
  }

  /// Static helper for currency conversion.
  /// Rounds to whole integer, guarantees no values below 0.
  static double convert(double amount, String fromCode, String toCode) {
    if (amount < 0) amount = 0;
    final double fromRate = exchangeRates[fromCode] ?? 1.0;
    final double toRate = exchangeRates[toCode] ?? 1.0;
    final double factor = toRate / fromRate;
    final double converted = amount * factor;
    final double rounded = converted.roundToDouble();
    return rounded < 0 ? 0.0 : rounded;
  }
}

class CurrencyProvider extends InheritedNotifier<ValueNotifier<CurrencyInfo>> {
  const CurrencyProvider({
    super.key,
    required ValueNotifier<CurrencyInfo> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ValueNotifier<CurrencyInfo> of(BuildContext context) {
    final element = context.getElementForInheritedWidgetOfExactType<CurrencyProvider>();
    assert(element != null, 'No CurrencyProvider found in context');
    return (element!.widget as CurrencyProvider).notifier!;
  }

  static CurrencyInfo read(BuildContext context) {
    return of(context).value;
  }

  static CurrencyInfo watch(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<CurrencyProvider>();
    assert(provider != null, 'No CurrencyProvider found in context');
    return provider!.notifier!.value;
  }
}
