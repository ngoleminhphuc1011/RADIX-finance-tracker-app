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

  /// Updates a transaction's icon, description, and amount locally in RAM only.
  /// Performs delta calculus to adjust global money variables accordingly.
  /// Does NOT touch the database.
  void updateTransaction(
    String id,
    String newIcon,
    String newDescription,
    double newAmount,
  ) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final tx = _transactions[index];
    final double oldAmount = tx.amount;
    final double delta = newAmount - oldAmount;

    // Step 3: Global State Adjustment
    if (tx.isExpense) {
      // Expense: Adjust spent
      spent += delta;
    } else {
      // Income: Check allocation tag
      if (tx.incomeAllocation == 'budget') {
        monthlyBudget += delta;
      } else if (tx.incomeAllocation == 'spent') {
        spent -= delta;
      }
    }

    // Step 4: RAM Modification
    setState(() {
      _transactions[index].iconKey = newIcon;
      _transactions[index].title = newDescription;
      _transactions[index].amount = newAmount;
    });
  }

  /// Deletes a transaction from RAM and reverses its financial impact.
  void deleteTransaction(String id) {
    final tx = _transactions.firstWhere((t) => t.id == id);
    // Step 1: Reverse the cash flow
    if (tx.isExpense) {
      spent -= tx.amount;
    } else {
      // Income — check allocation tag
      if (tx.incomeAllocation == 'budget') {
        monthlyBudget -= tx.amount;
      } else if (tx.incomeAllocation == 'spent') {
        spent += tx.amount;
      }
    }
    // Step 2: Remove from list & re-render
    _transactions.removeWhere((t) => t.id == id);
    setState(() {});
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
            onUpdateTransaction: updateTransaction,
            onDeleteTransaction: deleteTransaction,
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 4),
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
