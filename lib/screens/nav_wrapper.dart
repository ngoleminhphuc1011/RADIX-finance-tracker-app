import 'package:flutter/material.dart';
import 'graph_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../models/transaction_model.dart';

class NavWrapper extends StatefulWidget {
  const NavWrapper({super.key});

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  double _pagePosition = 1.0;

  // Lifted global state — persists across page switches
  final List<TransactionModel> _transactions = [];
  double monthlyBudget = 500.0;
  double spent = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    final double? page = _pageController.page;
    if (page != null) {
      setState(() {
        _pagePosition = page;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavTap(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 800),
      curve: Curves.fastLinearToSlowEaseIn,
    );
  }

  void _addTransaction(TransactionModel tx) {
    setState(() {
      _transactions.insert(0, tx);
    });
  }

  void _setBudget(double val) {
    setState(() {
      monthlyBudget = val;
    });
  }

  void _setSpent(double val) {
    setState(() {
      spent = val;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          const GraphScreen(),
          HomeScreen(
            transactions: _transactions,
            onAddTransaction: _addTransaction,
            monthlyBudget: monthlyBudget,
            spent: spent,
            onBudgetChanged: _setBudget,
            onSpentChanged: _setSpent,
          ),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double barWidth = constraints.maxWidth;
                final double itemWidth = barWidth / 3;
                final double indicatorWidth = itemWidth * 0.48;
                final double indicatorCenterX =
                    itemWidth * (0.5 + _pagePosition);
                final double indicatorLeft =
                    (indicatorCenterX - indicatorWidth / 2).clamp(
                      0.0,
                      barWidth - indicatorWidth,
                    );

                return Stack(
                  children: [
                    Positioned(
                      left: indicatorLeft,
                      top: 12,
                      bottom: 12,
                      width: indicatorWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 207, 227, 251),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        _buildNavItem(
                          0,
                          Icons.bar_chart_outlined,
                          Icons.bar_chart,
                          itemWidth,
                        ),
                        _buildNavItem(
                          1,
                          Icons.home_outlined,
                          Icons.home,
                          itemWidth,
                        ),
                        _buildNavItem(
                          2,
                          Icons.settings_outlined,
                          Icons.settings,
                          itemWidth,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData outlinedIcon,
    IconData filledIcon,
    double itemWidth,
  ) {
    final bool isActive = _currentIndex == index;
    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: Center(
          child: Icon(
            isActive ? filledIcon : outlinedIcon,
            color: isActive ? Colors.black : Colors.grey,
            size: 24,
          ),
        ),
      ),
    );
  }
}
