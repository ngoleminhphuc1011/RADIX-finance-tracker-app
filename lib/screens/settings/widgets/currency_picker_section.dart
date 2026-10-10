import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../home/widgets/bounce_card.dart';
import 'currency_tile.dart';

class CurrencyPickerSection extends StatelessWidget {
  final String selectedCurrencyCode;
  final ValueChanged<String> onSelectCurrency;

  const CurrencyPickerSection({
    super.key,
    required this.selectedCurrencyCode,
    required this.onSelectCurrency,
  });

  void _showCurrencyBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black.withValues(alpha: 0.65)
          : Colors.black.withValues(alpha: 0.40),
      builder: (sheetContext) {
        return _CurrencyPickerModalSheet(
          selectedCurrencyCode: selectedCurrencyCode,
          onSelectCurrency: onSelectCurrency,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final activeCurrency = allCurrencies.firstWhere(
      (c) => c.code == selectedCurrencyCode,
      orElse: () => allCurrencies.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Currency section label (matching Appearance and Reset Interval)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'CURRENCY',
                style: TextStyle(
                  fontFamily: 'MonumentExtended-Regular',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: locker.settingsSectionLabel,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Compact Luxury Trigger Tile
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: BounceCard(
              onTap: () => _showCurrencyBottomSheet(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? locker.settingsCapsuleBarBackground
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE5E5EA),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Left: Currency Title & Subtitle indicator
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Currency',
                            style: AppTypography.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: locker.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeCurrency.name} (${activeCurrency.symbol})',
                            style: AppTypography.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: locker.settingsInfoText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Right: Capsule badge with currency code & subtle chevron
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF2F2F7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeCurrency.code,
                            style: AppTypography.openSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: locker.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: locker.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyPickerModalSheet extends StatefulWidget {
  final String selectedCurrencyCode;
  final ValueChanged<String> onSelectCurrency;

  const _CurrencyPickerModalSheet({
    required this.selectedCurrencyCode,
    required this.onSelectCurrency,
  });

  @override
  State<_CurrencyPickerModalSheet> createState() =>
      _CurrencyPickerModalSheetState();
}

class _CurrencyPickerModalSheetState extends State<_CurrencyPickerModalSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(maxHeight: mediaQuery.size.height * 0.75),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF131518).withValues(alpha: 0.94)
                : Colors.white.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Grab handle pill
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: locker.textTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header Row: Title & Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SELECT CURRENCY',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: locker.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.black.withValues(alpha: 0.04),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: locker.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: locker.searchBarBackground,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: AppTypography.openSans(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: locker.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search currency...',
                      hintStyle: AppTypography.openSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: locker.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: locker.textTertiary,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: locker.textTertiary,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Currency List
              Flexible(
                child: _filteredCurrencies.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No currency matches "$_searchQuery"',
                            style: AppTypography.openSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: locker.textTertiary,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredCurrencies.length,
                        itemBuilder: (context, index) {
                          final currency = _filteredCurrencies[index];
                          final isSelected =
                              currency.code == widget.selectedCurrencyCode;

                          return CurrencyTile(
                            currency: currency,
                            isSelected: isSelected,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onSelectCurrency(currency.code);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
