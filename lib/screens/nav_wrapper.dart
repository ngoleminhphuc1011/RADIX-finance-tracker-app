import 'dart:math';
import 'package:flutter/material.dart';
import 'graph_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';
import '../theme/app_color_locker.dart';
import '../theme/currency_provider.dart';

class NavWrapper extends StatefulWidget {
  const NavWrapper({super.key});

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentIndex = 1;
  final ValueNotifier<double> _pagePosition = ValueNotifier<double>(1.0);

  // The single DatabaseHelper instance (Singleton — same object app-wide).
  final _db = DatabaseHelper();

  // Lifted global state — persists across page switches.
  // All of this is loaded from DB on startup and saved to DB on every change.
  final List<TransactionModel> _transactions = [];
  double _userSetBudget = 0.0; // loaded from DB; 0.0 = "not set yet"
  double monthlyBudget = 0.0;
  double spent = 0.0;
  double budgetLeft = 0.0;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  CurrencyInfo? _prevCurrency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCurrency = CurrencyProvider.read(context);
    if (_prevCurrency != null && _prevCurrency!.code != currentCurrency.code) {
      debugPrint('[NavWrapper] Currency change detected from ${_prevCurrency!.code} to ${currentCurrency.code}. Reloading DB...');
      _loadAllFromDB();
    }
    _prevCurrency = currentCurrency;
  }

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
    _pagePosition.dispose();
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
      _pagePosition.value = page;
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
      budgetLeft = max(0.0, monthlyBudget - spent);
    });
  }

  // ── CRUD — Add ──────────────────────────────────────────────────────────────

  /// Inserts [tx] into the DB, stamps back the AUTOINCREMENT id, then adds
  /// the model to RAM. DB write is AWAITED before state update.
  Future<void> _addTransaction(TransactionModel tx) async {
    try {
      double roundedAmount = tx.amount.roundToDouble();
      if (roundedAmount < 0) roundedAmount = 0.0;
      final sanitizedTx = tx.copyWith(amount: roundedAmount);

      // 1. Persist to DB first — await ensures the row is written.
      final int newId = await _db.insertTransaction(sanitizedTx);

      // 2. Stamp the real id onto the model before adding to RAM.
      final TransactionModel txWithId = sanitizedTx.copyWith(id: newId);

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
      double roundedAmount = newAmount.roundToDouble();
      if (roundedAmount < 0) roundedAmount = 0.0;

      // 1. Persist to DB first.
      await _db.updateTransaction(
        id: id,
        title: newTitle,
        amount: roundedAmount,
        category: newCategory,
      );

      // 2. Mirror the change in RAM.
      final index = _transactions.indexWhere((t) => t.id == id);
      if (index == -1) return;

      setState(() {
        _transactions[index] = _transactions[index].copyWith(
          category: newCategory,
          title: newTitle,
          amount: roundedAmount,
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
      double roundedBudget = val.roundToDouble();
      if (roundedBudget < 0) roundedBudget = 0.0;

      // 1. Persist to DB.
      await _db.setSetting('monthly_budget', roundedBudget.toString());

      // 2. Update RAM.
      setState(() {
        _userSetBudget = roundedBudget;
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

  // ── Reset ───────────────────────────────────────────────────────────────────

  /// Called from SettingsScreen when the user confirms a full data reset.
  Future<void> _resetAllData() async {
    try {
      await _db.resetDataKeepSettings();
      if (!mounted) return;
      setState(() {
        _transactions.clear();
        _userSetBudget = 0.0;
      });
      recalculateGlobalBalances();
    } catch (e) {
      debugPrint('[Nav] ERROR resetting data: $e');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  Color get _currentTabBackgroundColor {
    final locker = AppColorLocker.of(context);
    switch (_currentIndex) {
      case 0:
        return locker.graphBackground;
      case 1:
        return locker.scaffoldBackground;
      case 2:
        return locker.settingsBackground;
      default:
        return locker.scaffoldBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: _currentTabBackgroundColor,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          GraphScreen(isActive: _currentIndex == 0, transactions: _transactions),
          HomeScreen(
            transactions: _transactions,
            onAddTransaction: _addTransaction,
            onUpdateTransaction: updateTransaction,
            onDeleteTransaction: deleteTransaction,
            monthlyBudget: monthlyBudget,
            spent: spent,
            budgetLeft: budgetLeft,
            onBudgetChanged: _setBudget,
            onSpentChanged: _setSpent,
          ),
          SettingsScreen(onResetAll: _resetAllData),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            height: 68,
            decoration: BoxDecoration(
              color: AppColorLocker.of(context).navBarBackground,
              boxShadow: [
                BoxShadow(
                  color: AppColorLocker.of(context).shadowLight,
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double barWidth = constraints.maxWidth;
                final double itemWidth = barWidth / 3;
                final double indicatorWidth = itemWidth * 0.65;

                return Stack(
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: _pagePosition,
                      builder: (context, pagePos, _) {
                        final double indicatorCenterX =
                            itemWidth * (0.5 + pagePos);
                        final double indicatorLeft =
                            (indicatorCenterX - indicatorWidth / 2).clamp(
                              0.0,
                              barWidth - indicatorWidth,
                            );
                        return Positioned(
                          left: indicatorLeft,
                          top: 6,
                          bottom: 6,
                          width: indicatorWidth,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: AppColorLocker.of(context).navIndicatorBackground,
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        );
                      },
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
    final locker = AppColorLocker.of(context);
    final Color targetColor = isActive
        ? (locker.navIndicatorBackground.computeLuminance() > 0.5
            ? const Color(0xFF090A0C)
            : locker.textPrimary)
        : locker.textTertiary;

    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onNavTap(index),
        child: Center(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: targetColor),
            duration: const Duration(milliseconds: 400),
            builder: (context, color, child) {
              return Icon(
                isActive ? filledIcon : outlinedIcon,
                color: color,
                size: 24,
              );
            },
          ),
        ),
      ),
    );
  }
}
