import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'screens/graph/graph_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/social/social_screen.dart';
import 'models/transaction_model.dart';
import 'core/database/database_helper.dart';
import 'core/theme/app_color_locker.dart';
import 'core/theme/app_typography.dart';
import 'core/theme/currency_provider.dart';
import 'core/services/reset_interval_service.dart';

class _NavTabItem {
  final String label;
  final IconData outlinedIcon;
  final IconData filledIcon;

  const _NavTabItem({
    required this.label,
    required this.outlinedIcon,
    required this.filledIcon,
  });
}

const List<_NavTabItem> _navTabs = [
  _NavTabItem(
    label: 'Social',
    outlinedIcon: Icons.public_outlined,
    filledIcon: Icons.public_rounded,
  ),
  _NavTabItem(
    label: 'Analytics',
    outlinedIcon: Icons.bar_chart_rounded,
    filledIcon: Icons.bar_chart_rounded,
  ),
  _NavTabItem(
    label: 'Home',
    outlinedIcon: Icons.home_outlined,
    filledIcon: Icons.home_rounded,
  ),
  _NavTabItem(
    label: 'Profile',
    outlinedIcon: Icons.person_outline_rounded,
    filledIcon: Icons.person_rounded,
  ),
  _NavTabItem(
    label: 'Settings',
    outlinedIcon: Icons.settings_outlined,
    filledIcon: Icons.settings_rounded,
  ),
];

class NavWrapper extends StatefulWidget {
  const NavWrapper({super.key});

  @override
  State<NavWrapper> createState() => _NavWrapperState();
}

class _NavWrapperState extends State<NavWrapper> {
  final PageController _pageController = PageController(initialPage: 2);
  int _currentIndex = 2;
  final ValueNotifier<double> _pagePosition = ValueNotifier<double>(2.0);

  // The single DatabaseHelper instance (Singleton — same object app-wide).
  final _db = DatabaseHelper();

  // Lifted global state — persists across page switches.
  // All of this is loaded from DB on startup and saved to DB on every change.
  List<TransactionModel> _transactions = [];
  double _userSetBudget = 0.0; // loaded from DB; 0.0 = "not set yet"
  double monthlyBudget = 0.0;
  double spent = 0.0;
  double budgetLeft = 0.0;

  // ── Lifecycle ───────────────────────────────────────────────────────────────

  CurrencyInfo? _prevCurrency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCurrency = CurrencyProvider.watch(context);
    if (_prevCurrency != null && _prevCurrency!.code != currentCurrency.code) {
      debugPrint(
        '[NavWrapper] Currency change detected from ${_prevCurrency!.code} to ${currentCurrency.code}. Reloading DB...',
      );
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

  // ── DB load & Interval Reset (Startup & Runtime) ─────────────────────────

  /// Lazy-check reset verification:
  /// Evaluates elapsed months between [DateTime.now()] and [last_reset_timestamp]:
  ///   deltaMonths = (now.year - lastReset.year) * 12 + (now.month - lastReset.month)
  /// If deltaMonths >= reset_interval_months:
  ///   - Resets spent to 0.0 for the new cycle (clears previous transactions).
  ///   - Updates last_reset_timestamp to the start of the current cycle.
  ///   - Updates global state and refreshes UI.
  Future<void> checkAndPerformIntervalReset() async {
    try {
      final now = DateTime.now();
      final lastReset = await ResetIntervalService.getLastResetTimestamp();
      final intervalMonths =
          await ResetIntervalService.getResetIntervalMonths();

      if (ResetIntervalService.isResetDue(
        now: now,
        lastReset: lastReset,
        intervalMonths: intervalMonths,
      )) {
        debugPrint(
          '[Nav] Reset interval due (delta: ${ResetIntervalService.calculateDeltaMonths(now, lastReset)}, interval: ${intervalMonths}M). Resetting cycle spent...',
        );

        // 1. Delete all transactions for the new cycle
        final db = await _db.database;
        await db.delete('transactions');

        // 2. Update last_reset_timestamp to the start of the current cycle
        final currentCycleStart = DateTime(now.year, now.month, 1);
        await ResetIntervalService.setLastResetTimestamp(currentCycleStart);

        // 3. Update global state and refresh UI
        if (mounted) {
          setState(() {
            _transactions.clear();
            spent = 0.0;
            budgetLeft = monthlyBudget;
          });
          recalculateGlobalBalances();
        }
      }
    } catch (e) {
      debugPrint('[Nav] ERROR in checkAndPerformIntervalReset: $e');
    }
  }

  /// Loads every piece of persistent state from SQLite.
  /// Called once in initState. After this, CRUD methods keep DB in sync.
  Future<void> _loadAllFromDB() async {
    try {
      // 0. Perform lazy interval reset check before loading transactions
      await checkAndPerformIntervalReset();

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
      final int target = page.round().clamp(0, _navTabs.length - 1);
      if (target != _currentIndex) {
        setState(() {
          _currentIndex = target;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.fastOutSlowIn,
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
        _transactions = List.from(_transactions)..insert(0, txWithId);
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
        final newList = List<TransactionModel>.from(_transactions);
        newList[index] = newList[index].copyWith(
          category: newCategory,
          title: newTitle,
          amount: roundedAmount,
        );
        _transactions = newList;
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
        final newList = List<TransactionModel>.from(_transactions);
        newList.removeWhere((t) => t.id == id);
        _transactions = newList;
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
      // Sync last reset timestamp to current month cycle
      final now = DateTime.now();
      await ResetIntervalService.setLastResetTimestamp(
        DateTime(now.year, now.month, 1),
      );
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
        return locker.scaffoldBackground; // Social
      case 1:
        return locker.graphBackground; // Analytics
      case 2:
        return locker.scaffoldBackground; // Home
      case 3:
        return locker.scaffoldBackground; // Profile
      case 4:
        return locker.settingsBackground; // Settings
      default:
        return locker.scaffoldBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
            const SocialScreen(),
            GraphScreen(
              isActive: _currentIndex == 1,
              transactions: _transactions,
            ),
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
            const ProfileScreen(),
            SettingsScreen(
              onResetAll: _resetAllData,
              onIntervalChanged: (_) => checkAndPerformIntervalReset(),
            ),
          ],
        ),
        bottomNavigationBar: Builder(
          builder: (context) {
            final Size screenSize = MediaQuery.sizeOf(context);
            final Orientation orientation = MediaQuery.orientationOf(context);
            final bool isLandscape = orientation == Orientation.landscape;
            final double shortestSide = screenSize.shortestSide;
            final double screenWidth = screenSize.width;

            // Device / Screen tier detection
            final bool isTablet = shortestSide >= 600 || screenWidth >= 768;
            final bool isLargePhone = screenWidth >= 410;

            // Adaptive bar sizing
            final double navHeight = isTablet
                ? 82.0
                : (isLandscape ? 66.0 : (isLargePhone ? 74.0 : 70.0));

            final double iconSize = isTablet
                ? 28.0
                : (isLandscape ? (isTablet ? 26.0 : 23.0) : (isLargePhone ? 25.0 : 23.0));

            final double labelFontSize = isTablet
                ? 15.0
                : (isLandscape ? (isTablet ? 14.0 : 12.0) : (isLargePhone ? 13.0 : 12.0));

            final double maxBarWidth = isTablet
                ? 680.0
                : (isLandscape ? 560.0 : double.infinity);

            final double barBottomPadding = isLandscape
                ? 12.0
                : (isTablet ? 32.0 : 24.0);

            final double barHorizontalPadding = isTablet
                ? 18.0
                : (isLandscape ? 12.0 : 10.0);

            final double hActive = isTablet
                ? 18.0
                : (isLargePhone ? 16.0 : 15.0);
            final double hInactive = isTablet
                ? 14.0
                : (isLargePhone ? 12.0 : 11.0);
            final double vPadding = isTablet
                ? 11.0
                : (isLandscape ? 8.0 : 9.0);

            final locker = AppColorLocker.of(context);

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: barBottomPadding,
                  left: isLandscape ? 24 : 16,
                  right: isLandscape ? 24 : 16,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxBarWidth),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(35),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.35)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            height: navHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: barHorizontalPadding,
                              vertical: isLandscape ? 6 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: locker.frostedGlassBg,
                              borderRadius: BorderRadius.circular(35),
                              border: Border.all(
                                color: locker.frostedGlassBorder,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (int i = 0; i < _navTabs.length; i++)
                                  _buildNavItem(
                                    i,
                                    _navTabs[i],
                                    locker,
                                    iconSize: iconSize,
                                    labelFontSize: labelFontSize,
                                    hActive: hActive,
                                    hInactive: hInactive,
                                    vPadding: vPadding,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildNavItem(
    int index,
    _NavTabItem tab,
    AppColorLocker locker, {
    required double iconSize,
    required double labelFontSize,
    required double hActive,
    required double hInactive,
    required double vPadding,
  }) {
    final bool isActive = _currentIndex == index;

    final Color activeColor = locker.navActiveFg;
    final Color inactiveColor = locker.navInactiveFg;
    final Color activeCapsuleBg = locker.navActiveCapsuleBg;
    final Color activeCapsuleBorder = locker.navActiveCapsuleBorder;

    // Matching RGB with 0 alpha prevents any grey dip during transitions
    final Color transparentBg = activeCapsuleBg.withValues(alpha: 0.0);
    final Color transparentBorder = activeCapsuleBorder.withValues(alpha: 0.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onNavTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? hActive : hInactive,
          vertical: vPadding,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeCapsuleBg : transparentBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? activeCapsuleBorder : transparentBorder,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: inactiveColor,
                end: isActive ? activeColor : inactiveColor,
              ),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              builder: (context, color, child) {
                return Icon(
                  isActive ? tab.filledIcon : tab.outlinedIcon,
                  color: color,
                  size: iconSize,
                );
              },
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.centerLeft,
                widthFactor: isActive ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: isActive ? 1.0 : 0.0,
                    curve: Curves.easeInOut,
                    child: Text(
                      tab.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.clip,
                      style: AppTypography.openSans(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.bold,
                        color: activeColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
