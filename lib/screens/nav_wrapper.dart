import 'dart:math';
import 'package:flutter/material.dart';
import 'graph_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';

class NavWrapper extends StatefulWidget {
  const NavWrapper({super.key});

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  double _pagePosition = 1.0;

  // The single DatabaseHelper instance (Singleton — same object app-wide).
  final _db = DatabaseHelper();

  // Lifted global state — persists across page switches.
  // All of this is loaded from DB on startup and saved to DB on every change.
  final List<TransactionModel> _transactions = [];
  double _userSetBudget = 0.0; // loaded from DB; 0.0 = "not set yet"
  double monthlyBudget = 0.0;
  double spent = 0.0;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _pageController.addListener(_onScroll);

    // Load ALL persisted state from the DB on startup.
    // This single method loads transactions + budget, then recomputes balances.
    _loadAllFromDB();
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  // ── DB load (single entry point for startup) ───────────────────────────────

  /// Loads every piece of persistent state from SQLite.
  /// Called once in initState. After this, CRUD methods keep DB in sync.
  Future<void> _loadAllFromDB() async {
    try {
      // 1. Load transactions
      final rows = await _db.getTransactions();

      // 2. Load budget (key = 'monthly_budget')
      final budgetStr = await _db.getSetting('monthly_budget');
      final double loadedBudget = (budgetStr != null)
          ? (double.tryParse(budgetStr) ?? 0.0)
          : 0.0;

      // 3. Apply to state in a single setState to avoid extra rebuilds
      setState(() {
        _transactions
          ..clear()
          ..addAll(rows);
        _userSetBudget = loadedBudget;
      });

      // 4. Recompute derived values (monthlyBudget, spent)
      recalculateGlobalBalances();

      debugPrint('[Nav] Startup load complete:');
      debugPrint('[Nav]   ${rows.length} transaction(s)');
      debugPrint('[Nav]   budget = $loadedBudget');
    } catch (e) {
      debugPrint('[Nav] ERROR during startup load: $e');
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _onScroll() {
    final double? page = _pageController.page;
    if (page != null) {
      setState(() {
        _pagePosition = page;
      });
    }
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

  // ── Balance calculation ──────────────────────────────────────────────────────

  /// Full recomputation of all balance variables from transaction ground truth.
  /// This is the SINGLE source of truth — never use incremental delta math.
  void recalculateGlobalBalances() {
    double totalExpenses = 0.0;
    double totalDeductions = 0.0;
    double totalIncomeToBudget = 0.0;

    for (final tx in _transactions) {
      if (tx.isExpense) {
        totalExpenses += tx.amount;
      } else {
        if (tx.incomeStrategy == 'deduct_from_spent') {
          totalDeductions += tx.amount;
        } else if (tx.incomeStrategy == 'add_to_budget') {
          totalIncomeToBudget += tx.amount;
        }
      }
    }

    setState(() {
      monthlyBudget = max(0.0, _userSetBudget + totalIncomeToBudget);
      spent = max(0.0, totalExpenses - totalDeductions);
    });
  }

  // ── CRUD — Add ──────────────────────────────────────────────────────────────

  /// Inserts [tx] into the DB, stamps back the AUTOINCREMENT id, then adds
  /// the model to RAM. DB write is AWAITED before state update.
  Future<void> _addTransaction(TransactionModel tx) async {
    try {
      // 1. Persist to DB first — await ensures the row is written.
      final int newId = await _db.insertTransaction(tx);

      // 2. Stamp the real id onto the model before adding to RAM.
      final TransactionModel txWithId = tx.copyWith(id: newId);

      setState(() {
        _transactions.insert(0, txWithId);
      });
      recalculateGlobalBalances();
    } catch (e) {
      debugPrint('[Nav] ERROR adding transaction: $e');
    }
  }

  // ── CRUD — Update ───────────────────────────────────────────────────────────

  /// Updates [id] in both the DB (AWAITED) and RAM.
  Future<void> updateTransaction(
    int id,
    String newCategory,
    String newTitle,
    double newAmount,
  ) async {
    try {
      // 1. Persist to DB first.
      await _db.updateTransaction(
        id: id,
        title: newTitle,
        amount: newAmount,
        category: newCategory,
      );

      // 2. Mirror the change in RAM.
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) return;

      setState(() {
        _transactions[index] = _transactions[index].copyWith(
          category: newCategory,
          title: newTitle,
          amount: newAmount,
        );
      });

      recalculateGlobalBalances();
    } catch (e) {
      debugPrint('[Nav] ERROR updating transaction: $e');
    }
  }

  // ── CRUD — Delete ───────────────────────────────────────────────────────────

  /// Deletes [id] from the DB (AWAITED) then removes from RAM.
  Future<void> deleteTransaction(int id) async {
    try {
      // 1. Remove from DB first.
      await _db.deleteTransaction(id);

      // 2. Remove from RAM.
      setState(() {
        _transactions.removeWhere((t) => t.id == id);
      });

      recalculateGlobalBalances();
    } catch (e) {
      debugPrint('[Nav] ERROR deleting transaction: $e');
    }
  }

  // ── Budget ──────────────────────────────────────────────────────────────────

  /// Saves the user-entered budget to BOTH the DB and RAM.
  /// DB write is AWAITED so the value is on disk before we continue.
  Future<void> _setBudget(double val) async {
    try {
      // 1. Persist to DB.
      await _db.setSetting('monthly_budget', val.toString());

      // 2. Update RAM.
      setState(() {
        _userSetBudget = val;
      });
      recalculateGlobalBalances();

      debugPrint('[Nav] Budget saved: $val');
    } catch (e) {
      debugPrint('[Nav] ERROR saving budget: $e');
    }
  }

  void _setSpent(double val) {
    // Kept for API compatibility — recalculate handles spent via ground truth.
    recalculateGlobalBalances();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          GraphScreen(isActive: _currentIndex == 0),
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
            height: 68,
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
                final double indicatorWidth = itemWidth * 0.65;
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
                      top: 6,
                      bottom: 6,
                      width: indicatorWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 207, 227, 251),
                          borderRadius: BorderRadius.circular(30),
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
