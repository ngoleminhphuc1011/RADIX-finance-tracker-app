import 'package:flutter/material.dart';
import 'instruction_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentSort = 'Date';
  double sortTurns = 0.0;
  double monthlyBudget = 500.0;

  void _cycleSort() {
    setState(() {
      if (currentSort == 'Date') {
        currentSort = 'Highest';
        sortTurns = 0.25;
      } else if (currentSort == 'Highest') {
        currentSort = 'Category';
        sortTurns = 0.5;
      } else if (currentSort == 'Category') {
        currentSort = 'Flow';
        sortTurns = 0.75;
      } else {
        // Flow -> back to Date
        currentSort = 'Date';
        sortTurns = 0.0;
      }
    });
    debugPrint('Sort changed to: $currentSort');
  }

  // Mock transaction data
  final List<_TransactionGroup> _transactions = [
    _TransactionGroup(
      date: 'Thursdays, 25 November',
      items: [
        _TransactionItem(
          icon: Icons.work_outline,
          category: 'Salary',
          amount: 50.00,
          isIncome: true,
        ),
        _TransactionItem(
          icon: Icons.restaurant_outlined,
          category: 'Food',
          amount: 20.00,
          isIncome: false,
        ),
      ],
    ),
    _TransactionGroup(
      date: 'Wednesday, 24 November',
      items: [
        _TransactionItem(
          icon: Icons.shopping_bag_outlined,
          category: 'Shopping',
          amount: 35.00,
          isIncome: false,
        ),
        _TransactionItem(
          icon: Icons.directions_car_outlined,
          category: 'Transport',
          amount: 12.00,
          isIncome: false,
        ),
      ],
    ),
  ];

  void _showBudgetInputDialog(BuildContext context) {
    final TextEditingController budgetController = TextEditingController(
      text: monthlyBudget == 0 ? '' : monthlyBudget.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),

          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ENTER MONTHLY BUDGET',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. 500',
                    prefixText: '\$',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF00E676)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      double? enteredBudget = double.tryParse(
                        budgetController.text,
                      );
                      if (enteredBudget != null) {
                        setState(() {
                          monthlyBudget = enteredBudget;
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'SAVE BUDGET',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'MonumentExtended-Regular',
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'RADIX',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'MonumentExtended',
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              // Balance Card
              BounceCard(
                onTap: () {
                  _showBudgetInputDialog(context);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFA3E4D7),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SPENT',
                        style: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '\$40',
                        style: TextStyle(
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'BUDGET LEFT: \$${monthlyBudget.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'MonumentExtended-Regular',
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Sort Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _cycleSort,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sort: $currentSort',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 4),
                          AnimatedRotation(
                            turns: sortTurns,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutBack,
                            child: const Icon(Icons.arrow_upward, size: 16),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InstructionScreen(),
                        ),
                      ),
                      child: Icon(Icons.info_outline, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Transaction List
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                  child: ListView.builder(
                    key: ValueKey<String>(currentSort),
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: _transactions.length,
                    itemBuilder: (context, groupIndex) {
                      final group = _transactions[groupIndex];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date title
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              group.date,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          // Transaction cards
                          ...group.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildTransactionCard(item),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () => _showInputSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionCard(_TransactionItem item) {
    final bool isIncome = item.isIncome;
    final Color bgColor = isIncome
        ? const Color(0xFFE8F8F5)
        : const Color(0xFFFADBD8);
    final Color fgColor = isIncome
        ? const Color(0xFF117A65)
        : const Color(0xFF78281F);
    final String amountText = isIncome
        ? '+ \$${item.amount.toStringAsFixed(2)}'
        : '- \$${item.amount.toStringAsFixed(2)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(item.icon, color: fgColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.category,
              style: TextStyle(
                fontFamily: 'MonumentExtended-Regular',
                fontSize: 16,
                color: fgColor,
              ),
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ADD EXPENSE',
                style: TextStyle(
                  fontFamily: 'MonumentExtended',
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. 500',
                  prefixText: '\$',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Data models
class _TransactionGroup {
  final String date;
  final List<_TransactionItem> items;

  _TransactionGroup({required this.date, required this.items});
}

class _TransactionItem {
  final IconData icon;
  final String category;
  final double amount;
  final bool isIncome;

  _TransactionItem({
    required this.icon,
    required this.category,
    required this.amount,
    required this.isIncome,
  });
}

class BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BounceCard({super.key, required this.child, required this.onTap});

  @override
  State<BounceCard> createState() => _BounceCardState();
}

class _BounceCardState extends State<BounceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // tạo chuyển động nảy trong 100ms
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // khi nhấn vào, card sẽ thu nhỏ lại còn 95% (0.95)
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(), // nhấn xuống thì thu nhỏ
      onTapUp: (_) {
        _controller.reverse(); // thả ra thì nảy lại cũ
        widget.onTap(); // kích hoạt hàm mở cửa sổ nhập
      },
      onTapCancel: () => _controller.reverse(), // Hủy nhấn thì hồi lại
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
