import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../theme/app_color_locker.dart';
import '../theme/currency_provider.dart';

// ─── Category visual registry ────────────────────────────────────────────────
// Maps each icon key string (stored in DB) to its display properties.
// This is the single source of truth for category visuals across the app.

class _CategoryInfo {
  final String name;
  final IconData icon;

  const _CategoryInfo({
    required this.name,
    required this.icon,
  });
}

const Map<String, _CategoryInfo> _categoryRegistry = {
  'fastfood': _CategoryInfo(
    name: 'Food',
    icon: Icons.fastfood_outlined,
  ),
  'shopping_bag': _CategoryInfo(
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
  ),
  'directions_car': _CategoryInfo(
    name: 'Transport',
    icon: Icons.directions_car_filled_outlined,
  ),
  'home': _CategoryInfo(
    name: 'Utilities',
    icon: Icons.home_outlined,
  ),
  'celebration': _CategoryInfo(
    name: 'Entertainment',
    icon: Icons.celebration_outlined,
  ),
  'payments': _CategoryInfo(
    name: 'Payments',
    icon: Icons.payments_outlined,
  ),
  'work': _CategoryInfo(
    name: 'Work',
    icon: Icons.work_outline,
  ),
  'school': _CategoryInfo(
    name: 'Education',
    icon: Icons.school_outlined,
  ),
  'flight': _CategoryInfo(
    name: 'Travel',
    icon: Icons.flight_outlined,
  ),
  'fitness_center': _CategoryInfo(
    name: 'Fitness',
    icon: Icons.fitness_center_outlined,
  ),
  'health_and_safety': _CategoryInfo(
    name: 'Health',
    icon: Icons.health_and_safety_outlined,
  ),
  'pets': _CategoryInfo(
    name: 'Pets',
    icon: Icons.pets_outlined,
  ),
  'local_gas_station': _CategoryInfo(
    name: 'Gas',
    icon: Icons.local_gas_station_outlined,
  ),
  'train': _CategoryInfo(
    name: 'Transit',
    icon: Icons.train_outlined,
  ),
};

// Fallback for empty or unknown category keys
const _CategoryInfo _otherCategory = _CategoryInfo(
  name: 'Other',
  icon: Icons.widgets_outlined,
);

// ─── Aggregated category for chart display ───────────────────────────────────

class _AggregatedCategory {
  final String iconKey;
  final String name;
  final IconData icon;
  final Color color;
  final double amount;

  const _AggregatedCategory({
    required this.iconKey,
    required this.name,
    required this.icon,
    required this.color,
    required this.amount,
  });
}

// ─── GraphScreen ─────────────────────────────────────────────────────────────

class GraphScreen extends StatefulWidget {
  final bool isActive;
  final List<TransactionModel> transactions;

  const GraphScreen({
    super.key,
    this.isActive = false,
    required this.transactions,
  });

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Color get _textColor => AppColorLocker.of(context).textPrimary;

  Color _getContrastIconColor(Color categoryColor) {
    final hsl = HSLColor.fromColor(categoryColor);
    return hsl.withLightness((hsl.lightness * 0.35).clamp(0.0, 1.0)).toColor();
  }

  String? _selectedIconKey;
  ScrollPosition? _scrollPosition;
  double _swipeProgress = 0.0;

  // ── Memoization caches ────────────────────────────────────────────────────

  /// Cached aggregated categories — invalidated when transaction count changes.
  List<_AggregatedCategory>? _cachedCategories;
  int _cachedTxLength = -1;

  /// Cached detail lists per category key.
  final Map<String, List<TransactionModel>> _detailCache = {};

  /// Throttle guard for scroll events.
  bool _scrollThrottled = false;

  // ── Pure computation helpers ──────────────────────────────────────────────

  /// Filters expense transactions, groups by category icon key, sums the
  /// amounts per group, resolves display info from [_categoryRegistry] (or
  /// [_otherCategory] fallback for null/unknown keys), and sorts descending
  /// by total amount.
  ///
  /// This is the single location for the Map-Reduce aggregation logic,
  /// extracted from the widget tree so the build method stays lightweight.
  List<_AggregatedCategory> _aggregateExpenses(BuildContext context) {
    final expenses = widget.transactions.where((tx) => tx.isExpense).toList();
    if (expenses.isEmpty) return [];

    // Group by category key and sum amounts
    final Map<String, double> sums = {};
    for (final tx in expenses) {
      final key = tx.category.isEmpty ? '' : tx.category;
      sums[key] = (sums[key] ?? 0.0) + tx.amount;
    }

    // Convert to display categories with fallback protection
    final List<_AggregatedCategory> result = [];
    for (final entry in sums.entries) {
      final info = _categoryRegistry[entry.key] ?? _otherCategory;
      final iconKey = _categoryRegistry.containsKey(entry.key)
          ? entry.key
          : '_other';
      result.add(
        _AggregatedCategory(
          iconKey: iconKey,
          name: info.name,
          icon: info.icon,
          color: AppColorLocker.of(context).getCategoryColor(iconKey),
          amount: entry.value,
        ),
      );
    }

    // Sort by amount descending (largest slice first)
    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  int _calculateHash() {
    int hash = 17;
    try {
      hash = hash * 31 + CurrencyProvider.read(context).code.hashCode;
    } catch (_) {}
    for (final tx in widget.transactions) {
      hash = hash * 31 + (tx.id ?? 0);
      hash = hash * 31 + tx.amount.hashCode;
      hash = hash * 31 + tx.title.hashCode;
      hash = hash * 31 + tx.category.hashCode;
    }
    return hash;
  }

  /// Aggregates expense transactions by category, sorted by amount descending.
  /// Results are memoized and invalidated when transaction content or currency changes.
  List<_AggregatedCategory> get _categories {
    final currentHash = _calculateHash();
    if (_cachedCategories != null && _cachedTxLength == currentHash) {
      return _cachedCategories!;
    }

    // Run the pure aggregation, cache it, and invalidate detail cache
    _cachedCategories = _aggregateExpenses(context);
    _cachedTxLength = currentHash;
    _detailCache.clear();
    return _cachedCategories!;
  }

  /// Returns the list of expense transactions matching the given category key.
  /// Results are cached per key for the lifetime of the current category set.
  List<TransactionModel> _detailsForCategory(String iconKey) {
    if (_detailCache.containsKey(iconKey)) {
      return _detailCache[iconKey]!;
    }

    final expenses = widget.transactions.where((tx) => tx.isExpense).toList();
    final matching = iconKey == '_other'
        ? expenses.where(
            (tx) =>
                tx.category.isEmpty ||
                !_categoryRegistry.containsKey(tx.category),
          )
        : expenses.where((tx) => tx.category == iconKey);

    final sorted = matching.toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    _detailCache[iconKey] = sorted;
    return sorted;
  }

  // Derive touched index from selection key
  int get _touchedIndex {
    if (_selectedIconKey == null) return -1;
    final cats = _categories;
    return cats.indexWhere((c) => c.iconKey == _selectedIconKey);
  }

  // Calculate sum of all expense values
  double get _totalSpent =>
      _categories.fold(0.0, (sum, item) => sum + item.amount);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScrollNotification);

    // Bind scroll position of parent PageView to drive drawing progress
    try {
      final scrollable = Scrollable.maybeOf(context);
      _scrollPosition = scrollable?.position;
      _scrollPosition?.addListener(_onScrollNotification);
      _onScrollNotification();
    } catch (e) {
      setState(() {
        _swipeProgress = 1.0;
      });
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScrollNotification);
    super.dispose();
  }

  // ── Scroll-driven animation ───────────────────────────────────────────────
  // (Preserved as-is — drives the clockwise slice drawing progress)

  void _onScrollNotification() {
    if (!mounted || _scrollPosition == null) return;
    if (_scrollThrottled) return;

    final pos = _scrollPosition!;
    if (!pos.hasContentDimensions || pos.viewportDimension == 0) return;

    // page index: 1.0 is HomeScreen, 0.0 is GraphScreen
    final double page = pos.pixels / pos.viewportDimension;

    // progress: 0.0 when on HomeScreen, 1.0 when fully on GraphScreen
    final double progress = (1.0 - page).clamp(0.0, 1.0);

    if (progress != _swipeProgress) {
      _scrollThrottled = true;
      // Schedule un-throttle after a short frame to coalesce rapid scroll events
      Future.delayed(const Duration(milliseconds: 16), () {
        if (!mounted) return;
        _scrollThrottled = false;
      });
      Future.delayed(Duration.zero, () {
        if (!mounted) return;
        setState(() {
          _swipeProgress = progress;
          // Reset selection if swiping away
          if (progress < 1.0) {
            _selectedIconKey = null;
          }
        });
      });
    }
  }

  // ── Animated slice values ─────────────────────────────────────────────────
  // (Preserved as-is — simulates clockwise drawing progress)

  /// Calculates the animated values of each slice sequentially to simulate
  /// a clockwise drawing progress effect around the circle.
  List<double> _buildAnimatedValues(double progress) {
    final cats = _categories;
    final double total = _totalSpent;
    if (total == 0) {
      return List.filled(cats.length, 0.0);
    }

    final List<double> animatedValues = [];
    double accumulatedProgress = 0.0;

    for (int i = 0; i < cats.length; i++) {
      final targetVal = cats[i].amount;
      final targetPct = targetVal / total;

      final sliceStart = accumulatedProgress;
      final sliceEnd = accumulatedProgress + targetPct;

      if (progress <= sliceStart) {
        animatedValues.add(0.0);
      } else if (progress >= sliceEnd) {
        animatedValues.add(targetVal);
      } else {
        final sliceFraction = (progress - sliceStart) / targetPct;
        animatedValues.add(targetVal * sliceFraction);
      }
      accumulatedProgress = sliceEnd;
    }
    return animatedValues;
  }

  // ── Chart section data ────────────────────────────────────────────────────

  List<PieChartSectionData> _buildSections() {
    final cats = _categories;
    final progress = _swipeProgress;

    if (progress == 0.0 || cats.isEmpty) {
      // Return a single transparent segment to prevent fl_chart from
      // rendering its 360-degree first-slice fallback circle.
      return [
        PieChartSectionData(
          color: Colors.transparent,
          value: 1.0,
          radius: 42.0,
          showTitle: false,
        ),
      ];
    }

    final animatedValues = _buildAnimatedValues(progress);
    final touchedIdx = _touchedIndex;

    return List.generate(cats.length, (i) {
      final category = cats[i];
      final isTouched = i == touchedIdx;
      final radius = isTouched ? 54.0 : 42.0;

      final hsl = HSLColor.fromColor(category.color);
      final darkenedIconColor = hsl
          .withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0))
          .toColor();

      return PieChartSectionData(
        color: category.color,
        value: animatedValues[i],
        radius: radius,
        showTitle: false, // Keep slices clean without text clutter
        badgeWidget: _CategoryBadge(
          icon: category.icon,
          iconColor: darkenedIconColor,
          isTouched: isTouched,
          progress: progress,
        ),
        badgePositionPercentageOffset: isTouched ? 0.65 : 0.55,
      );
    });
  }

  // ── Donut chart widget ────────────────────────────────────────────────────

  Widget _buildDonutChart() {
    final cats = _categories;
    final bool hasData = cats.isNotEmpty;

    return SizedBox(
      height: 280,
      child: hasData
          ? Stack(
              children: [
                RepaintBoundary(
                  child: PieChart(
                    PieChartData(
                      startDegreeOffset: -90, // starts drawing from 12 o'clock
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          if (event is FlTapUpEvent) {
                            Future.delayed(Duration.zero, () {
                              if (!mounted) return;
                              setState(() {
                                if (pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _selectedIconKey = null;
                                  return;
                                }
                                final index = pieTouchResponse
                                    .touchedSection!
                                    .touchedSectionIndex;
                                if (index >= 0 && index < cats.length) {
                                  final targetKey = cats[index].iconKey;
                                  if (_selectedIconKey == targetKey) {
                                    _selectedIconKey = null;
                                  } else {
                                    _selectedIconKey = targetKey;
                                  }
                                }
                              });
                            });
                          }
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 4,
                      centerSpaceRadius: 95,
                      sections: _buildSections(),
                    ),
                    // Disable swap transition while swiping to avoid lag,
                    // enable for touch selection when settled
                    swapAnimationDuration: _swipeProgress == 1.0
                        ? const Duration(milliseconds: 200)
                        : Duration.zero,
                    swapAnimationCurve: Curves.easeOut,
                  ),
                ),
                Center(child: _buildDonutCenterText(cats)),
              ],
            )
          : _buildEmptyChart(),
    );
  }

  Widget _buildDonutCenterText(List<_AggregatedCategory> cats) {
    final touchedIdx = _touchedIndex;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          touchedIdx != -1 && touchedIdx < cats.length
              ? cats[touchedIdx].name.toUpperCase()
              : 'TOTAL SPENT',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 11,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            touchedIdx != -1 && touchedIdx < cats.length
                ? CurrencyProvider.read(context).format(cats[touchedIdx].amount)
                : CurrencyProvider.read(context).format(_totalSpent * _swipeProgress),
            style: TextStyle(
              fontFamily: 'MonumentExtended-Regular',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No expenses yet',
            style: TextStyle(
              fontFamily: 'MonumentExtended-Regular',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add transactions to see your breakdown',
            style: TextStyle(
              fontFamily: 'MonumentExtended-Regular',
              fontSize: 11,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    final bool hasData = cats.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: AppColorLocker.of(context).graphBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_selectedIconKey != null) {
                      Future.delayed(Duration.zero, () {
                        if (mounted) {
                          setState(() {
                            _selectedIconKey = null;
                          });
                        }
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 24,
                      right: 24,
                      bottom: 110,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Header ---
                        Text(
                          'ANALYTICS',
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _textColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- Premium Floating Donut Chart Card ---
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorLocker.of(context).cardBackground,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: AppColorLocker.of(context).textPrimary.withValues(alpha: 0.04),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Hollow Spacious Donut Chart
                              _buildDonutChart(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- Drill-Down Bottom Section ---
                        if (hasData)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                            alignment: Alignment.topCenter,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder:
                                  (
                                    Widget? currentChild,
                                    List<Widget> previousChildren,
                                  ) {
                                    final children = List<Widget>.from(
                                      previousChildren,
                                    );
                                    if (currentChild != null) {
                                      children.add(currentChild);
                                    }
                                    return Stack(
                                      alignment: Alignment.topCenter,
                                      children: children,
                                    );
                                  },
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    final isDetail =
                                        child.key !=
                                        const ValueKey('CategoryList');
                                    return ClipRect(
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: Offset(
                                            isDetail ? 1.0 : -1.0,
                                            0.0,
                                          ),
                                          end: Offset.zero,
                                        ).animate(animation),
                                        child: FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        ),
                                      ),
                                    );
                                  },
                              child: _selectedIconKey == null
                                  ? _buildCategoryList(cats)
                                  : _buildDetailList(_selectedIconKey!, cats),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ),
      ),
    );
  }

  // ── Category list (breakdown rows) ────────────────────────────────────────

  Widget _buildCategoryList(List<_AggregatedCategory> cats) {
    final totalSpent = _totalSpent;
    return Column(
      key: const ValueKey('CategoryList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BREAKDOWN',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColorLocker.of(context).textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(cats.length, (index) {
            final category = cats[index];
            final percent = totalSpent > 0
                ? (category.amount / totalSpent * 100).toStringAsFixed(1)
                : '0.0';

            return GestureDetector(
              onTap: () {
                Future.delayed(Duration.zero, () {
                  if (mounted) {
                    setState(() {
                      _selectedIconKey = category.iconKey;
                    });
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColorLocker.of(context).cardBackground,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColorLocker.of(context).textPrimary.withValues(alpha: 0.04),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Flat Circle Badge matching segment color
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          category.icon,
                          size: 16,
                          color: _getContrastIconColor(category.color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name & Percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColorLocker.of(context).textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 10,
                            color: AppColorLocker.of(context).textTertiary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Amount
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          CurrencyProvider.read(context).format(category.amount),
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColorLocker.of(context).textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Detail list (transactions within a selected category) ─────────────────

  Widget _buildDetailList(String iconKey, List<_AggregatedCategory> cats) {
    final category = cats.firstWhere(
      (c) => c.iconKey == iconKey,
      orElse: () => _AggregatedCategory(
        iconKey: iconKey,
        name: (_categoryRegistry[iconKey] ?? _otherCategory).name,
        icon: (_categoryRegistry[iconKey] ?? _otherCategory).icon,
        color: AppColorLocker.of(context).getCategoryColor(iconKey),
        amount: 0,
      ),
    );
    final details = _detailsForCategory(iconKey);

    // Date formatter for detail rows
    final DateFormat displayFormat = DateFormat('MMM dd');

    return Column(
      key: ValueKey('DetailList_$iconKey'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Future.delayed(Duration.zero, () {
              if (mounted) {
                setState(() {
                  _selectedIconKey = null;
                });
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back,
                  size: 14,
                  color: AppColorLocker.of(context).textPrimary,
                ),
                const SizedBox(width: 6),
                Text(
                  'BACK TO CATEGORIES',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColorLocker.of(context).textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          '${category.name.toUpperCase()} TRANSACTIONS',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColorLocker.of(context).textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        details.isEmpty
            ? Center(
                key: const ValueKey('NoDetailsPlaceholder'),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No transactions recorded',
                    style: TextStyle(
                      fontFamily: 'MonumentExtended-Regular',
                      fontSize: 12,
                      color: AppColorLocker.of(context).textTertiary,
                    ),
                  ),
                ),
              )
            : Column(
                children: List.generate(details.length, (index) {
                  final tx = details[index];

                  // Format date for display
                  String dateStr;
                  try {
                    final parsed = DateTime.parse(tx.date);
                    dateStr = displayFormat.format(parsed);
                  } catch (_) {
                    dateStr = tx.date;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorLocker.of(context).cardBackground,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColorLocker.of(context).textPrimary.withValues(alpha: 0.04),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Flat Circle Icon Badge matching segment color
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: category.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              category.icon,
                              size: 16,
                              color: _getContrastIconColor(category.color),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title & Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: TextStyle(
                                  fontFamily: 'MonumentExtended-Regular',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColorLocker.of(context).textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontFamily: 'MonumentExtended-Regular',
                                  fontSize: 10,
                                  color: AppColorLocker.of(context).textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '-${CurrencyProvider.read(context).format(tx.amount)}',
                              style: TextStyle(
                                fontFamily: 'MonumentExtended-Regular',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColorLocker.of(context).expenseModelFg,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
      ],
    );
  }
}

// ─── Reusable Category Badge Widget ──────────────────────────────────────────
// Extracted from the inline badge builder in _buildSections() for
// const-constructability and rebuild short-circuiting.

class _CategoryBadge extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final bool isTouched;
  final double progress;

  const _CategoryBadge({
    required this.icon,
    required this.iconColor,
    required this.isTouched,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: progress > 0.85 ? 1.0 : 0.0,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 250),
        scale: progress > 0.85 ? (isTouched ? 1.25 : 1.0) : 0.0,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColorLocker.of(context).cardBackground,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColorLocker.of(context).textPrimary.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          child: Center(child: Icon(icon, size: 15, color: iconColor)),
        ),
      ),
    );
  }
}
