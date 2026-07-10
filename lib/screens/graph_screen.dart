import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class MockCategory {
  final String name;
  final double amount;
  final IconData icon;
  final Color color;

  const MockCategory({
    required this.name,
    required this.amount,
    required this.icon,
    required this.color,
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
      icon: Icons.fastfood_outlined,
      color: Color(0xFFFF8B94), // Pastel pink-red
    ),
    MockCategory(
      name: 'Shopping',
      amount: 450.00,
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFFFFD3B6), // Pastel peach
    ),
    MockCategory(
      name: 'Transport',
      amount: 180.20,
      icon: Icons.directions_car_filled_outlined,
      color: Color(0xFFD4A5A5), // Pastel dusty rose
    ),
    MockCategory(
      name: 'Utilities',
      amount: 290.00,
      icon: Icons.home_outlined,
      color: Color(0xFF9FFFCB), // Pastel mint green
    ),
    MockCategory(
      name: 'Entertainment',
      amount: 150.00,
      icon: Icons.celebration_outlined,
      color: Color(0xFFC7CEEA), // Pastel lavender-blue
    ),
    MockCategory(
      name: 'Other', // "None" / Unmapped category
      amount: 95.00,
      icon: Icons.widgets_outlined,
      color: Color(0xFFE2E8F0), // Pastel slate for unmapped/none
    ),
  ];

  int _touchedIndex = -1;
  ScrollPosition? _scrollPosition;
  double _swipeProgress = 0.0;

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
        _swipeProgress = 1.0; // fallback if rendered standalone
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
      setState(() {
        _swipeProgress = progress;
        // Reset selection if swiping away
        if (progress < 1.0) {
          _touchedIndex = -1;
        }
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

    return List.generate(_mockCategories.length, (i) {
      final category = _mockCategories[i];
      final isTouched = i == _touchedIndex;
      final radius = isTouched ? 54.0 : 42.0;

      return PieChartSectionData(
        color: category.color,
        value: animatedValues[i],
        radius: radius,
        showTitle: false, // Keep slices clean without text clutter
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF1C1C1E);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_touchedIndex != -1) {
              setState(() {
                _touchedIndex = -1;
              });
            }
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 40, left: 24, right: 24),
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
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(10, 0, 0, 0),
                        blurRadius: 32,
                        offset: Offset(0, 12),
                      ),
                    ],
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
                                startDegreeOffset: -90, // starts drawing from 12 o'clock
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    // Only update selection on explicit tap up event (color pressed)
                                    if (event is FlTapUpEvent) {
                                      setState(() {
                                        if (pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        final newIndex = pieTouchResponse
                                            .touchedSection!
                                            .touchedSectionIndex;
                                        // Toggle behavior: tap same slice again to deselect
                                        if (newIndex == _touchedIndex) {
                                          _touchedIndex = -1;
                                        } else {
                                          _touchedIndex = newIndex;
                                        }
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
                                    _touchedIndex != -1 &&
                                            _touchedIndex < _mockCategories.length
                                        ? _mockCategories[_touchedIndex].name
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
                                    _touchedIndex != -1 &&
                                            _touchedIndex < _mockCategories.length
                                        ? '\$${_mockCategories[_touchedIndex].amount.toStringAsFixed(2)}'
                                        : '\$${(_totalSpent * _swipeProgress).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontFamily: 'MonumentExtended-Bold',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
