import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';

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
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
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

    final List<BoxShadow> boxShadow = widget.isSelected
        ? [
            BoxShadow(
              color: locker.settingsCurrencySelectedBorder.withValues(
                alpha: 0.18,
              ),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
        : [];

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
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: gradient,
            border: border,
            borderRadius: BorderRadius.circular(14),
            boxShadow: boxShadow,
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
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
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: textColor,
                  ),
                  child: Text(
                    '${widget.currency.code} - ${widget.currency.name}',
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: locker.settingsCurrencySelectedText,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
