import 'package:flutter/material.dart';
import '../theme/app_color_locker.dart';
import '../theme/currency_provider.dart';

/// A standardized typography component for displaying currency values across RADIX.
///
/// Ensures currency symbols and numerical amounts have equal font size and uniform styling
/// along the alphabetic baseline, while preserving raw numbers and clean system glyph fallback.
class RadixCurrencyText extends StatelessWidget {
  final double amount;
  final String? currencySymbol;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final String? fontFamily;
  final String? prefix;
  final bool? isExpense;
  final double symbolRatio;
  final FontWeight? symbolWeight;
  final String? formattedAmount;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const RadixCurrencyText({
    super.key,
    required this.amount,
    this.currencySymbol,
    this.fontSize = 16.0,
    this.fontWeight = FontWeight.w700,
    this.color,
    this.fontFamily,
    this.prefix,
    this.isExpense,
    this.symbolRatio = 1.0,
    this.symbolWeight,
    this.formattedAmount,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final currencyInfo = CurrencyProvider.watch(context);
    final String symbol = currencySymbol ?? currencyInfo.symbol;
    final Color effectiveColor = color ?? locker.textPrimary;

    String resolvedPrefix = prefix ?? '';
    if (prefix == null && isExpense != null) {
      resolvedPrefix = isExpense! ? '- ' : '+ ';
    }

    final String numberString =
        formattedAmount ?? currencyInfo.formatNumber(amount);

    final TextStyle numberStyle = TextStyle(
      fontFamily: fontFamily ?? 'MonumentExtended',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: effectiveColor,
      textBaseline: TextBaseline.alphabetic,
    );

    final TextStyle symbolStyle = TextStyle(
      fontFamily: null, // System fallback ensures clean glyph rendering
      fontSize: fontSize * symbolRatio,
      fontWeight: symbolWeight ?? fontWeight,
      color: effectiveColor,
      textBaseline: TextBaseline.alphabetic,
    );

    return Text.rich(
      TextSpan(
        style: TextStyle(
          textBaseline: TextBaseline.alphabetic,
          color: effectiveColor,
        ),
        children: [
          if (resolvedPrefix.isNotEmpty)
            TextSpan(text: resolvedPrefix, style: numberStyle),
          TextSpan(text: symbol, style: symbolStyle),
          TextSpan(text: numberString, style: numberStyle),
        ],
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
