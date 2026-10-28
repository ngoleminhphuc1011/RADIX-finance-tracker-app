import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// CurrencyProvider & CurrencyInfo: Global Currency State & Formatting
// ═══════════════════════════════════════════════════════════════════════════════

/// Immutable model defining a supported currency, its exchange rate relative
/// to USD (base rate 1.0), and number/TextSpan formatting helpers.
class CurrencyInfo {
  final String code;
  final String symbol;
  final String name;

  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.name,
  });

  // ── Supported Currencies & Baseline Rates ────────────────────────────────────
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

  /// Looks up currency by ISO code (case-insensitive), defaulting to USD.
  static CurrencyInfo find(String code) {
    return all.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => all.first,
    );
  }

  // ── Formatting Utilities ───────────────────────────────────────────────────
  static final NumberFormat _formatter = NumberFormat('#,###');

  /// Formats double to a rounded whole integer with currency symbol (e.g. "$1,500").
  /// Sanitizes against negative values or NaN.
  String format(double amount) {
    if (amount < 0 || amount.isNaN || amount.isInfinite) amount = 0;
    return '$symbol${_formatter.format(amount.round())}';
  }

  /// Formats double to a rounded whole integer without currency symbol (e.g. "1,500").
  String formatNumber(double amount) {
    if (amount < 0 || amount.isNaN || amount.isInfinite) amount = 0;
    return _formatter.format(amount.round());
  }

  /// Builds a rich TextSpan pairing the currency symbol and number with custom styling.
  TextSpan buildSpan({
    required double amount,
    required TextStyle numberStyle,
    TextStyle? symbolStyle,
    double symbolRatio = 1.0,
    FontWeight? symbolWeight,
    String prefix = '',
  }) {
    final double baseFontSize = numberStyle.fontSize ?? 16.0;
    final Color? color = numberStyle.color;

    return TextSpan(
      style: TextStyle(textBaseline: TextBaseline.alphabetic, color: color),
      children: [
        if (prefix.isNotEmpty) TextSpan(text: prefix, style: numberStyle),
        TextSpan(
          text: symbol,
          style:
              symbolStyle ??
              TextStyle(
                fontFamily: null,
                fontSize: baseFontSize * symbolRatio,
                fontWeight:
                    symbolWeight ?? numberStyle.fontWeight ?? FontWeight.normal,
                color: color,
              ),
        ),
        TextSpan(text: formatNumber(amount), style: numberStyle),
      ],
    );
  }

  // ── Conversion Helper ───────────────────────────────────────────────────────
  /// Converts an amount between two currencies using baseline exchange rates.
  /// Result is rounded to whole numbers and clamped to >= 0.0.
  static double convert(double amount, String fromCode, String toCode) {
    if (amount <= 0 || amount.isNaN || amount.isInfinite) return 0.0;
    final double fromRate = exchangeRates[fromCode.toUpperCase()] ?? 1.0;
    final double toRate = exchangeRates[toCode.toUpperCase()] ?? 1.0;
    if (fromRate <= 0) return 0.0;
    final double factor = toRate / fromRate;
    final double converted = amount * factor;
    final double rounded = converted.roundToDouble();
    return (rounded < 0 || rounded.isNaN || rounded.isInfinite) ? 0.0 : rounded;
  }
}

// ── Inherited Provider ────────────────────────────────────────────────────────
/// Propagates the active [CurrencyInfo] across the widget tree.
///
/// Flutter Architecture Tip:
/// - Use [CurrencyProvider.watch(context)] when the widget needs to rebuild on change.
/// - Use [CurrencyProvider.read(context)] for one-off reads (e.g. inside a callback).
/// - Use [CurrencyProvider.of(context)] to access the ValueNotifier and mutate it.
class CurrencyProvider extends InheritedNotifier<ValueNotifier<CurrencyInfo>> {
  const CurrencyProvider({
    super.key,
    required ValueNotifier<CurrencyInfo> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Accesses the underlying ValueNotifier (for changing the currency).
  /// Does NOT register the calling widget for rebuilds.
  static ValueNotifier<CurrencyInfo> of(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<CurrencyProvider>();
    assert(element != null, 'No CurrencyProvider found in context');
    return (element!.widget as CurrencyProvider).notifier!;
  }

  /// One-time read of the active currency without subscribing to rebuilds.
  static CurrencyInfo read(BuildContext context) {
    return of(context).value;
  }

  /// Subscribes the calling widget to rebuild whenever active currency changes.
  static CurrencyInfo watch(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<CurrencyProvider>();
    assert(provider != null, 'No CurrencyProvider found in context');
    return provider!.notifier!.value;
  }
}
