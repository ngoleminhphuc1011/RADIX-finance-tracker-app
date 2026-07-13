import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

// ─── Category visual registry ────────────────────────────────────────────────
// Maps each icon key string (stored in DB) to its display properties.
// This is the single source of truth for category visuals across the app.

class _CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
  });
}

const Map<String, _CategoryInfo> _categoryRegistry = {
  'fastfood': _CategoryInfo(
    name: 'Food',
    icon: Icons.fastfood_outlined,
    color: Color(0xFFFF8B94), // Pastel pink-red
  ),
  'shopping_bag': _CategoryInfo(
    name: 'Shopping',
    icon: Icons.shopping_bag_outlined,
    color: Color(0xFFFFD3B6), // Pastel peach
  ),
  'directions_car': _CategoryInfo(
    name: 'Transport',
    icon: Icons.directions_car_filled_outlined,
    color: Color(0xFFD4A5A5), // Pastel dusty rose
  ),
  'home': _CategoryInfo(
    name: 'Utilities',
    icon: Icons.home_outlined,
    color: Color(0xFF9FFFCB), // Pastel mint green
  ),
  'celebration': _CategoryInfo(
    name: 'Entertainment',
    icon: Icons.celebration_outlined,
    color: Color(0xFFC7CEEA), // Pastel lavender-blue
  ),
  'payments': _CategoryInfo(
    name: 'Payments',
    icon: Icons.payments_outlined,
    color: Color(0xFFFFF3B0), // Pastel yellow
  ),
  'work': _CategoryInfo(
    name: 'Work',
    icon: Icons.work_outline,
    color: Color(0xFFB3D9FF), // Pastel sky blue
  ),
  'school': _CategoryInfo(
    name: 'Education',
    icon: Icons.school_outlined,
    color: Color(0xFFB8B3E6), // Pastel indigo
  ),
  'flight': _CategoryInfo(
    name: 'Travel',
    icon: Icons.flight_outlined,
    color: Color(0xFFFFB3A7), // Pastel coral
  ),
  'fitness_center': _CategoryInfo(
    name: 'Fitness',
    icon: Icons.fitness_center_outlined,
    color: Color(0xFFB2DFDB), // Pastel teal
  ),
  'health_and_safety': _CategoryInfo(
    name: 'Health',
    icon: Icons.health_and_safety_outlined,
    color: Color(0xFFD5E8D4), // Pastel sage
  ),
  'pets': _CategoryInfo(
    name: 'Pets',
    icon: Icons.pets_outlined,
    color: Color(0xFFFFCCAA), // Pastel orange
  ),
  'local_gas_station': _CategoryInfo(
    name: 'Gas',
    icon: Icons.local_gas_station_outlined,
    color: Color(0xFFD6D6D6), // Pastel warm gray
  ),
  'train': _CategoryInfo(
    name: 'Transit',
    icon: Icons.train_outlined,
    color: Color(0xFFAEC6CF), // Pastel steel blue
  ),
};

// Fallback for empty or unknown category keys
const _CategoryInfo _otherCategory = _CategoryInfo(
  name: 'Other',
  icon: Icons.widgets_outlined,
  color: Color(0xFFE2E8F0), // Pastel slate
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

  // ── Computed data from real transactions ──────────────────────────────────

  /// Aggregates expense transactions by category, sorted by amount descending.
  /// Results are memoized and invalidated when transaction count changes.
  List<_AggregatedCategory> get _categories {
    final txLen = widget.transactions.length;
    if (_cachedCategories != null && _cachedTxLength == txLen) {
      return _cachedCategories!;
    }

    // Filter to expenses only
    final expenses = widget.transactions.where((tx) => tx.isExpense).toList();
    if (expenses.isEmpty) {
      _cachedCategories = [];
      _cachedTxLength = txLen;
      return _cachedCategories!;
    }

    // Group by category key and sum amounts
    final Map<String, double> sums = {};
    for (final tx in expenses) {
      final key = tx.category.isEmpty ? '' : tx.category;
      sums[key] = (sums[key] ?? 0.0) + tx.amount;
    }

    // Convert to display categories
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
          color: info.color,
          amount: entry.value,
        ),
      );
    }

    // Sort by amount descending (largest slice first)
    result.sort((a, b) => b.amount.compareTo(a.amount));

    // Cache and invalidate detail cache since categories may have changed
    _cachedCategories = result;
    _cachedTxLength = txLen;
    _detailCache.clear();
    return result;
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

      final Widget badge = AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: progress > 0.85 ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 250),
          scale: progress > 0.85 ? (isTouched ? 1.25 : 1.0) : 0.0,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(25, 0, 0, 0),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(category.icon, size: 15, color: darkenedIconColor),
            ),
          ),
        ),
      );

      return PieChartSectionData(
        color: category.color,
        value: animatedValues[i],
        radius: radius,
        showTitle: false, // Keep slices clean without text clutter
        badgeWidget: badge,
        badgePositionPercentageOffset: isTouched ? 0.65 : 0.55,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1C1C1E);
    final cats = _categories;
    final touchedIdx = _touchedIndex;
    final bool hasData = cats.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
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
                      bottom: 40,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Header ---
                        const Text(
                          'ANALYTICS',
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // --- Premium Floating Donut Chart Card ---
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: const Color.fromARGB(10, 0, 0, 0),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Hollow Spacious Donut Chart
                              SizedBox(
                                height: 280,
                                child: hasData
                                    ? Stack(
                                        children: [
                                          PieChart(
                                            PieChartData(
                                              startDegreeOffset:
                                                  -90, // starts drawing from 12 o'clock
                                              pieTouchData: PieTouchData(
                                                touchCallback:
                                                    (
                                                      FlTouchEvent event,
                                                      pieTouchResponse,
                                                    ) {
                                                      if (event
                                                          is FlTapUpEvent) {
                                                        Future.delayed(Duration.zero, () {
                                                          if (!mounted) return;
                                                          setState(() {
                                                            if (pieTouchResponse ==
                                                                    null ||
                                                                pieTouchResponse
                                                                        .touchedSection ==
                                                                    null) {
                                                              _selectedIconKey =
                                                                  null;
                                                              return;
                                                            }
                                                            final index =
                                                                pieTouchResponse
                                                                    .touchedSection!
                                                                    .touchedSectionIndex;
                                                            if (index >= 0 &&
                                                                index <
                                                                    cats.length) {
                                                              final targetKey =
                                                                  cats[index]
                                                                      .iconKey;
                                                              if (_selectedIconKey ==
                                                                  targetKey) {
                                                                _selectedIconKey =
                                                                    null;
                                                              } else {
                                                                _selectedIconKey =
                                                                    targetKey;
                                                              }
                                                            }
                                                          });
                                                        });
                                                      }
                                                    },
                                              ),
                                              borderData: FlBorderData(
                                                show: false,
                                              ),
                                              sectionsSpace: 4,
                                              centerSpaceRadius: 95,
                                              sections: _buildSections(),
                                            ),
                                            // Disable swap transition while swiping to avoid lag, enable for touch selection when settled
                                            swapAnimationDuration:
                                                _swipeProgress == 1.0
                                                ? const Duration(
                                                    milliseconds: 200,
                                                  )
                                                : Duration.zero,
                                            swapAnimationCurve: Curves.easeOut,
                                          ),
                                          Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  touchedIdx != -1 &&
                                                          touchedIdx <
                                                              cats.length
                                                      ? cats[touchedIdx].name
                                                            .toUpperCase()
                                                      : 'TOTAL SPENT',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'MonumentExtended-Regular',
                                                    fontSize: 11,
                                                    color: Colors.grey[500],
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  touchedIdx != -1 &&
                                                          touchedIdx <
                                                              cats.length
                                                      ? '\$${cats[touchedIdx].amount.toStringAsFixed(2)}'
                                                      : '\$${(_totalSpent * _swipeProgress).toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        'MonumentExtended-Regular',
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.pie_chart_outline,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No expenses yet',
                                              style: TextStyle(
                                                fontFamily:
                                                    'MonumentExtended-Regular',
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Add transactions to see your breakdown',
                                              style: TextStyle(
                                                fontFamily:
                                                    'MonumentExtended-Regular',
                                                fontSize: 11,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
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
    );
  }

  Widget _buildCategoryList(List<_AggregatedCategory> cats) {
    final totalSpent = _totalSpent;
    return Column(
      key: const ValueKey('CategoryList'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BREAKDOWN',
          style: TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF636366),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color.fromARGB(10, 0, 0, 0),
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
                          color: const Color(0xFF1C1C1E),
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
                          style: const TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C1C1E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$percent%',
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Amount
                    Text(
                      '\$${category.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E),
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

  Widget _buildDetailList(String iconKey, List<_AggregatedCategory> cats) {
    final category = cats.firstWhere(
      (c) => c.iconKey == iconKey,
      orElse: () => _AggregatedCategory(
        iconKey: iconKey,
        name: (_categoryRegistry[iconKey] ?? _otherCategory).name,
        icon: (_categoryRegistry[iconKey] ?? _otherCategory).icon,
        color: (_categoryRegistry[iconKey] ?? _otherCategory).color,
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
                const Icon(
                  Icons.arrow_back,
                  size: 14,
                  color: Color(0xFF1C1C1E),
                ),
                const SizedBox(width: 6),
                Text(
                  'BACK TO CATEGORIES',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C1C1E),
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
          style: const TextStyle(
            fontFamily: 'MonumentExtended-Regular',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF636366),
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
                      color: Colors.grey[500],
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color.fromARGB(10, 0, 0, 0),
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
                              color: const Color(0xFF1C1C1E),
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
                                style: const TextStyle(
                                  fontFamily: 'MonumentExtended-Regular',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1C1C1E),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontFamily: 'MonumentExtended-Regular',
                                  fontSize: 10,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Amount
                        Text(
                          '-\$${tx.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB71C1C), // Red for expense details
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
