import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import 'currency_tile.dart';

class CurrencyPickerSection extends StatefulWidget {
  final String selectedCurrencyCode;
  final ValueChanged<String> onSelectCurrency;

  const CurrencyPickerSection({
    super.key,
    required this.selectedCurrencyCode,
    required this.onSelectCurrency,
  });

  @override
  State<CurrencyPickerSection> createState() => _CurrencyPickerSectionState();
}

class _CurrencyPickerSectionState extends State<CurrencyPickerSection> {
  String _searchQuery = '';

  List<CurrencyItem> get _filteredCurrencies {
    if (_searchQuery.isEmpty) return allCurrencies;
    final query = _searchQuery.toLowerCase();
    return allCurrencies.where((c) {
      return c.code.toLowerCase().contains(query) ||
          c.name.toLowerCase().contains(query) ||
          c.symbol.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final activeCurrency = allCurrencies.firstWhere(
      (c) => c.code == widget.selectedCurrencyCode,
      orElse: () => allCurrencies.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Currency label (aligned with bar)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Currency',
                style: TextStyle(
                  fontFamily: 'MonumentExtended-Regular',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: locker.settingsSectionLabel,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Info text
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'You are using ${widget.selectedCurrencyCode} (${activeCurrency.symbol})',
                style: TextStyle(
                  fontFamily: 'MonumentExtended-Regular',
                  fontSize: 12,
                  color: locker.settingsInfoText,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Search bar
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: locker.searchBarBackground,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  fontFamily: 'MonumentExtended-Regular',
                  fontSize: 13,
                  color: locker.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search currency...',
                  hintStyle: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 13,
                    color: locker.textTertiary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: locker.textTertiary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Currency list (compact scroll window)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: _filteredCurrencies.map((currency) {
                  return CurrencyTile(
                    currency: currency,
                    isSelected: currency.code == widget.selectedCurrencyCode,
                    onTap: () => widget.onSelectCurrency(currency.code),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
