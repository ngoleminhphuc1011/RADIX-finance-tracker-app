import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';

class CurrencyItem {
  final String symbol;
  final String code;
  final String name;

  const CurrencyItem(this.symbol, this.code, this.name);
}

const List<CurrencyItem> allCurrencies = [
  CurrencyItem('\$', 'USD', 'US Dollar'),
  CurrencyItem('€', 'EUR', 'Euro'),
  CurrencyItem('¥', 'CNY', 'Chinese Yuan'),
  CurrencyItem('₫', 'VND', 'Vietnam Dong'),
  CurrencyItem('£', 'GBP', 'British Pound'),
  CurrencyItem('¥', 'JPY', 'Japanese Yen'),
  CurrencyItem('\$', 'AUD', 'Australian Dollar'),
  CurrencyItem('\$', 'CAD', 'Canadian Dollar'),
];

class CurrencyTile extends StatefulWidget {
  final CurrencyItem currency;
  final bool isSelected;
  final VoidCallback onTap;

  const CurrencyTile({
    super.key,
    required this.currency,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<CurrencyTile> createState() => _CurrencyTileState();
}

class _CurrencyTileState extends State<CurrencyTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);

    final Gradient gradient = widget.isSelected
        ? LinearGradient(
            colors: [
              locker.settingsCurrencySelectedStart,
              locker.settingsCurrencySelectedEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              locker.settingsCurrencyUnselectedBg,
              locker.settingsCurrencyUnselectedBg,
            ],
          );

    final Border border = widget.isSelected
        ? Border.all(color: locker.settingsCurrencySelectedBorder, width: 1.5)
        : Border.all(
            color: locker.settingsCurrencyUnselectedBorder,
            width: 1.0,
          );

    final Color textColor = widget.isSelected
        ? locker.settingsCurrencySelectedText
        : locker.settingsCurrencyUnselectedText;

    final Color symbolColor = widget.isSelected
        ? locker.settingsCurrencySelectedText
        : locker.settingsCurrencyUnselectedSymbol;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontFamily: null,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: symbolColor,
                  ),
                  child: Text(widget.currency.symbol),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  style: AppTypography.openSans(
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w900
                        : FontWeight.bold,
                    color: textColor,
                  ),
                  child: Text(
                    '${widget.currency.code} - ${widget.currency.name}',
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: widget.isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: locker.settingsCurrencySelectedText,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
