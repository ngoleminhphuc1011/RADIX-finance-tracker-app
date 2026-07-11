import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MockCategory {
  final String name;
  final double amount;
  final String iconKey;
  final IconData icon;
  final Color color;

  const MockCategory({
    required this.name,
    required this.amount,
    required this.iconKey,
    required this.icon,
    required this.color,
  });
}

class MockDetailTransaction {
  final String title;
  final double amount;
  final String date;

  const MockDetailTransaction({
    required this.title,
    required this.amount,
    required this.date,
  });
}

class GraphScreen extends StatefulWidget {
  final bool isActive;
  const GraphScreen({super.key, this.isActive = false});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  // Pre-defined mock data matching transaction categories
  static const List<MockCategory> _mockCategories = [
    MockCategory(
      name: 'Food',
      amount: 320.50,
      iconKey: 'fastfood',
      icon: Icons.fastfood_outlined,
      color: Color(0xFFFF8B94), // Pastel pink-red
    ),
    MockCategory(
      name: 'Shopping',
      amount: 450.00,
      iconKey: 'shopping_bag',
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFFFD3B6), // Pastel peach
    ),
    MockCategory(
      name: 'Transport',
      amount: 180.20,
      iconKey: 'directions_car',
      icon: Icons.directions_car_filled_outlined,
      color: Color(0xFFD4A5A5), // Pastel dusty rose
    ),
    MockCategory(
      name: 'Utilities',
      amount: 290.00,
      iconKey: 'home',
      icon: Icons.home_outlined,
      color: Color(0xFF9FFFCB), // Pastel mint green
    ),
    MockCategory(
      name: 'Entertainment',
      amount: 150.00,
      iconKey: 'celebration',
      icon: Icons.celebration_outlined,
      color: Color(0xFFC7CEEA), // Pastel lavender-blue
    ),
    MockCategory(
      name: 'Other', // "None" / Unmapped category
      amount: 95.00,
      iconKey: 'widgets',
      icon: Icons.widgets_outlined,
      color: Color(0xFFE2E8F0), // Pastel slate for unmapped/none
    ),
  ];

  static const Map<String, List<MockDetailTransaction>> _mockDetails = {
    'fastfood': [
      MockDetailTransaction(
        title: 'Salted Coffee',
        amount: 4.50,
        date: 'Jul 10',
      ),
      MockDetailTransaction(
        title: 'Coconut Coffee',
        amount: 4.50,
        date: 'Jul 09',
      ),
      MockDetailTransaction(
        title: 'Spicy Beef Burger',
        amount: 8.50,
        date: 'Jul 08',
      ),
      MockDetailTransaction(
        title: 'Special Pho',
        amount: 10.00,
        date: 'Jul 06',
      ),
    ],
    'shopping_bag': [
      MockDetailTransaction(
        title: 'Leather Wallet',
        amount: 85.00,
        date: 'Jul 09',
      ),
      MockDetailTransaction(
        title: 'Cotton T-Shirt',
        amount: 35.00,
        date: 'Jul 07',
      ),
      MockDetailTransaction(
        title: 'Designer Sneakers',
        amount: 220.00,
        date: 'Jul 05',
      ),
    ],
    'directions_car': [
      MockDetailTransaction(
        title: 'Uber Ride (Work)',
        amount: 15.50,
        date: 'Jul 10',
      ),
      MockDetailTransaction(
        title: 'Taxi (Airport)',
        amount: 45.00,
        date: 'Jul 08',
      ),
      MockDetailTransaction(
        title: 'Gas Station',
        amount: 65.00,
        date: 'Jul 04',
      ),
    ],
    'home': [
      MockDetailTransaction(
        title: 'Electricity Bill',
        amount: 120.00,
        date: 'Jul 05',
      ),
      MockDetailTransaction(
        title: 'High-speed Internet',
        amount: 65.00,
        date: 'Jul 01',
      ),
      MockDetailTransaction(
        title: 'Water Supply Bill',
        amount: 35.00,
        date: 'Jul 01',
      ),
    ],
    'celebration': [
      MockDetailTransaction(
        title: 'Movie Tickets',
        amount: 28.00,
        date: 'Jul 09',
      ),
      MockDetailTransaction(
        title: 'Concert Entry',
        amount: 95.00,
        date: 'Jul 04',
      ),
      MockDetailTransaction(
        title: 'Board Game Cafe',
        amount: 15.00,
        date: 'Jul 02',
      ),
    ],
    'widgets': [
      MockDetailTransaction(
        title: 'Monthly Magazine',
        amount: 12.00,
        date: 'Jul 08',
      ),
      MockDetailTransaction(
        title: 'Gym Day Pass',
        amount: 15.00,
        date: 'Jul 06',
      ),
      MockDetailTransaction(title: 'Gift Card', amount: 50.00, date: 'Jul 05'),
    ],
  };

  String? _selectedIconKey;
  ScrollPosition? _scrollPosition;
  double _swipeProgress = 0.0;

  // Derive touched index from selection key
  int get _touchedIndex {
    if (_selectedIconKey == null) return -1;
    return _mockCategories.indexWhere((c) => c.iconKey == _selectedIconKey);
  }

  // Calculate sum of all values
  double get _totalSpent =>
      _mockCategories.fold(0.0, (sum, item) => sum + item.amount);

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

    final pos = _scrollPosition!;
    if (!pos.hasContentDimensions || pos.viewportDimension == 0) return;

    // page index: 1.0 is HomeScreen, 0.0 is GraphScreen
    final double page = pos.pixels / pos.viewportDimension;

    // progress: 0.0 when on HomeScreen, 1.0 when fully on GraphScreen
    final double progress = (1.0 - page).clamp(0.0, 1.0);

    if (progress != _swipeProgress) {
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
    final double total = _totalSpent;
    if (total == 0) {
      return List.filled(_mockCategories.length, 0.0);
    }

    final List<double> animatedValues = [];
    double accumulatedProgress = 0.0;

    for (int i = 0; i < _mockCategories.length; i++) {
      final targetVal = _mockCategories[i].amount;
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
    final progress = _swipeProgress;
    if (progress == 0.0) {
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

    return List.generate(_mockCategories.length, (i) {
      final category = _mockCategories[i];
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
    final touchedIdx = _touchedIndex;

    return GestureDetector(
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0EB),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                startDegreeOffset:
                                    -90, // starts drawing from 12 o'clock
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                        if (event is FlTapUpEvent) {
                                          Future.delayed(Duration.zero, () {
                                            if (!mounted) return;
                                            setState(() {
                                              if (pieTouchResponse == null ||
                                                  pieTouchResponse
                                                          .touchedSection ==
                                                      null) {
                                                _selectedIconKey = null;
                                                return;
                                              }
                                              final index = pieTouchResponse
                                                  .touchedSection!
                                                  .touchedSectionIndex;
                                              if (index >= 0 &&
                                                  index <
                                                      _mockCategories.length) {
                                                final targetKey =
                                                    _mockCategories[index]
                                                        .iconKey;
                                                if (_selectedIconKey ==
                                                    targetKey) {
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
                              // Disable swap transition while swiping to avoid lag, enable for touch selection when settled
                              swapAnimationDuration: _swipeProgress == 1.0
                                  ? const Duration(milliseconds: 200)
                                  : Duration.zero,
                              swapAnimationCurve: Curves.easeOut,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    touchedIdx != -1 &&
                                            touchedIdx < _mockCategories.length
                                        ? _mockCategories[touchedIdx].name
                                              .toUpperCase()
                                        : 'TOTAL SPENT',
                                    style: TextStyle(
                                      fontFamily: 'MonumentExtended-Regular',
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    touchedIdx != -1 &&
                                            touchedIdx < _mockCategories.length
                                        ? '\$${_mockCategories[touchedIdx].amount.toStringAsFixed(2)}'
                                        : '\$${(_totalSpent * _swipeProgress).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'MonumentExtended-Regular',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // --- Drill-Down Bottom Section ---
                _selectedIconKey == null
                    ? _buildCategoryList()
                    : _buildDetailList(_selectedIconKey!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryList() {
    return Column(
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
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _mockCategories.length,
          itemBuilder: (context, index) {
            final category = _mockCategories[index];
            final percent = _totalSpent > 0
                ? (category.amount / _totalSpent * 100).toStringAsFixed(1)
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
          },
        ),
      ],
    );
  }

  Widget _buildDetailList(String iconKey) {
    final category = _mockCategories.firstWhere((c) => c.iconKey == iconKey);
    final details = _mockDetails[iconKey] ?? [];

    return Column(
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
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: details.length,
                itemBuilder: (context, index) {
                  final tx = details[index];

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
                        Column(
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
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tx.date,
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
                },
              ),
      ],
    );
  }
}
