import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'instruction_screen.dart';
import '../../models/transaction_model.dart';
import '../../core/theme/app_color_locker.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/currency_provider.dart';
import 'widgets/bounce_card.dart';
import 'widgets/transaction_tile.dart';
import 'widgets/edit_morph_dialog.dart';
import 'widgets/budget_input_dialog.dart';
import 'widgets/add_transaction_dialog.dart';
import '../../core/widgets/radix_currency_text.dart';

class HomeScreen extends StatefulWidget {
  final List<TransactionModel> transactions;
  final void Function(TransactionModel) onAddTransaction;
  final void Function(
    int id,
    String newIcon,
    String newDescription,
    double newAmount,
  )?
  onUpdateTransaction;
  final void Function(int id) onDeleteTransaction;
  final double monthlyBudget;
  final double spent;
  final double budgetLeft;
  final ValueChanged<double> onBudgetChanged;
  final ValueChanged<double> onSpentChanged;

  const HomeScreen({
    super.key,
    required this.transactions,
    required this.onAddTransaction,
    this.onUpdateTransaction,
    required this.onDeleteTransaction,
    required this.monthlyBudget,
    required this.spent,
    required this.budgetLeft,
    required this.onBudgetChanged,
    required this.onSpentChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Color get _premiumPastelRed => AppColorLocker.of(context).accentRed;

  // -- TextStyles --
  TextStyle get _styleLabelBlack18 => TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 18,
    color: AppColorLocker.of(context).textPrimary,
  );
  TextStyle get _styleEmptyState => AppTypography.openSans(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: AppColorLocker.of(context).textTertiary,
  );

  // ── Memoization cache for grouped transactions ──────────────────────────
  Map<String, List<TransactionModel>>? _cachedGrouped;
  int _cachedGroupedHash = -1;
  String _cachedGroupedSort = '';

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions ||
        oldWidget.monthlyBudget != widget.monthlyBudget ||
        oldWidget.spent != widget.spent) {
      _cachedGrouped = null;
      _cachedGroupedHash = -1;
    }
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

  Map<String, List<TransactionModel>> get _grouped {
    final currentHash = _calculateHash();
    if (_cachedGrouped != null &&
        _cachedGroupedHash == currentHash &&
        _cachedGroupedSort == currentSort) {
      return _cachedGrouped!;
    }
    _cachedGrouped = _groupTransactions(widget.transactions);
    _cachedGroupedHash = currentHash;
    _cachedGroupedSort = currentSort;
    return _cachedGrouped!;
  }

  String currentSort = 'Date';
  double sortTurns = 0.0;
  bool _isPlusRotated = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        currentSort = 'Date';
        sortTurns = 0.0;
      }
    });
    debugPrint('Sort changed to: $currentSort');
  }

  void _showAddTransactionDialogDelayed() {
    if (!mounted) return;
    showAddTransactionDialog(
      context,
      onAddTransaction: widget.onAddTransaction,
      onDialogDismissed: () {
        if (mounted) {
          setState(() {
            _isPlusRotated = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOverBudget = widget.spent > widget.monthlyBudget;
    final grouped = _grouped;
    final groupedKeys = grouped.keys.toList(growable: false);
    final locker = AppColorLocker.of(context);
    final orientation = MediaQuery.of(context).orientation;
    final bool isLandscape = orientation == Orientation.landscape;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: locker.scaffoldBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: isLandscape
            ? null
            : const _CustomFloatingActionButtonLocation(
                FloatingActionButtonLocation.endFloat,
                offsetY: -92,
              ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'RADIX',
            style: TextStyle(
              color: locker.textPrimary,
              fontFamily: 'MonumentExtended',
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: isLandscape
            ? _buildLandscapeBody(
                context,
                locker,
                isOverBudget,
                groupedKeys,
                grouped,
              )
            : _buildPortraitBody(
                context,
                locker,
                isOverBudget,
                groupedKeys,
                grouped,
              ),
        floatingActionButton: isLandscape
            ? null
            : Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFab(locker),
              ),
      ),
    );
  }

  Widget _buildPortraitBody(
    BuildContext context,
    AppColorLocker locker,
    bool isOverBudget,
    List<String> groupedKeys,
    Map<String, List<TransactionModel>> grouped,
  ) {
    return Center(
      child: RepaintBoundary(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            children: [
              _buildBalanceCard(context, locker, isOverBudget, false),
              _buildSortRow(locker),
              const SizedBox(height: 8),
              Expanded(
                child: _buildTransactionList(
                  locker,
                  groupedKeys,
                  grouped,
                  padding: const EdgeInsets.only(bottom: 110),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeBody(
    BuildContext context,
    AppColorLocker locker,
    bool isOverBudget,
    List<String> groupedKeys,
    Map<String, List<TransactionModel>> grouped,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LEFT COLUMN (Expanded flex: 4): Wrap BalanceCard, quick summary stats, and Add Action in a non-overflowing container
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110, left: 16, right: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBalanceCard(context, locker, isOverBudget, true),
                const SizedBox(height: 8),
                _buildSortRow(locker),
                const SizedBox(height: 12),
                _buildAddActionButton(locker),
              ],
            ),
          ),
        ),
        // Subtle vertical separator
        Container(
          width: 1,
          margin: const EdgeInsets.only(bottom: 110),
          color: locker.textPrimary.withValues(alpha: 0.05),
        ),
        // RIGHT COLUMN (Expanded flex: 6): Dedicated scrollable area for transaction list
        Expanded(
          flex: 6,
          child: _buildTransactionList(
            locker,
            groupedKeys,
            grouped,
            padding: const EdgeInsets.only(bottom: 110, left: 8, right: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    AppColorLocker locker,
    bool isOverBudget,
    bool isLandscape,
  ) {
    return BounceCard(
      onAnimationComplete: () {
        showBudgetInputDialog(
          context,
          currentBudget: widget.monthlyBudget,
          onBudgetChanged: widget.onBudgetChanged,
        );
      },
      child: Container(
        width: double.infinity,
        margin: isLandscape
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 4)
            : const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: EdgeInsets.all(isLandscape ? 16 : 24),
        decoration: BoxDecoration(
          color: locker.cardBackground,
          border: Border.all(
            color: isOverBudget
                ? locker.accentRed.withValues(alpha: 0.7)
                : locker.budgetCardBorderNormal,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Text('SPENT', style: _styleLabelBlack18),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RadixCurrencyText(
                amount: widget.spent,
                fontSize: isLandscape ? 42 : 55,
                fontWeight: FontWeight.w900,
                fontFamily: 'MonumentExtended-Bold',
                color: locker.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: RadixCurrencyText(
                prefix: 'BUDGET LEFT: ',
                amount: widget.budgetLeft,
                fontSize: isLandscape ? 15 : 18,
                fontWeight: FontWeight.w400,
                fontFamily: 'MonumentExtended-Regular',
                color: isOverBudget ? _premiumPastelRed : locker.textPrimary,
              ),
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: RadixCurrencyText(
                  prefix: 'Overspent by ',
                  amount: widget.spent - widget.monthlyBudget,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _premiumPastelRed,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSortRow(AppColorLocker locker) {
    return Padding(
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
                  style: AppTypography.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: locker.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: sortTurns,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    Icons.arrow_upward,
                    size: 16,
                    color: locker.textSecondary,
                  ),
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
            child: Icon(Icons.info_outline, color: locker.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAddActionButton(AppColorLocker locker) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: BounceCard(
        onAnimationComplete: () {
          _showAddTransactionDialogDelayed();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: locker.textPrimary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: locker.textPrimary.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: locker.textOnDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'ADD TRANSACTION',
                style: AppTypography.openSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: locker.textOnDark,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    AppColorLocker locker,
    List<String> groupedKeys,
    Map<String, List<TransactionModel>> grouped, {
    required EdgeInsets padding,
  }) {
    if (widget.transactions.isEmpty) {
      return Center(
        child: Text(
          "PRESS '+' TO ADD\nTRANSACTION",
          textAlign: TextAlign.center,
          style: _styleEmptyState,
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
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
      child: RepaintBoundary(
        child: ScrollConfiguration(
          behavior: const ScrollBehavior().copyWith(scrollbars: false),
          child: ListView.builder(
            controller: _scrollController,
            key: ValueKey<String>(currentSort),
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              padding.bottom < 110 ? 110 : padding.bottom,
            ),
            physics: const BouncingScrollPhysics(),
            itemCount: groupedKeys.length,
            itemBuilder: (context, index) {
              final String dateStr = groupedKeys[index];
              final List<TransactionModel> groupTxs = grouped[dateStr]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDateHeader(dateStr, groupTxs),
                  ...groupTxs.map(
                    (tx) => TransactionTile(
                      model: tx,
                      onTap: () => showEditMorphDialog(
                        context,
                        model: tx,
                        onUpdateTransaction: widget.onUpdateTransaction,
                        onDeleteTransaction: widget.onDeleteTransaction,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFab(AppColorLocker locker) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fabBg = locker.frostedGlassBg;
    final Color fabBorder = locker.frostedGlassBorder;
    final Color fabIconColor = isDark ? Colors.white : locker.textPrimary;

    return BounceCard(
      onAnimationComplete: () {
        setState(() {
          _isPlusRotated = true;
        });
        Future.delayed(
          const Duration(milliseconds: 150),
          _showAddTransactionDialogDelayed,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.30)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: FloatingActionButton(
              backgroundColor: fabBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: fabBorder, width: 1),
              ),
              onPressed: null,
              elevation: 0,
              highlightElevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              child: AnimatedRotation(
                turns: _isPlusRotated ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                child: Icon(Icons.add, color: fabIconColor, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, List<TransactionModel>> _groupTransactions(
    List<TransactionModel> txs,
  ) {
    final Map<String, List<TransactionModel>> groups = {};
    for (final tx in txs) {
      final String key = tx.date.length >= 10
          ? tx.date.substring(0, 10)
          : tx.date;
      groups.putIfAbsent(key, () => []).add(tx);
    }

    // Sort sub-list for each date independently based on currentSort state
    for (final dateKey in groups.keys) {
      final list = groups[dateKey]!;
      if (currentSort == 'Date') {
        list.sort((a, b) {
          final idA = a.id ?? 0;
          final idB = b.id ?? 0;
          return idB.compareTo(idA);
        });
      } else if (currentSort == 'Highest') {
        list.sort((a, b) => b.amount.compareTo(a.amount));
      } else if (currentSort == 'Category') {
        list.sort((a, b) => a.category.compareTo(b.category));
      } else if (currentSort == 'Flow') {
        list.sort((a, b) {
          final flowA = a.isExpense ? 1 : 0;
          final flowB = b.isExpense ? 1 : 0;
          return flowB.compareTo(flowA);
        });
      }
    }

    // Keep the main timeline strictly ordered by date keys (newest first)
    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final Map<String, List<TransactionModel>> sortedGroups = {};
    for (final key in sortedKeys) {
      sortedGroups[key] = groups[key]!;
    }

    return sortedGroups;
  }

  Widget _buildDateHeader(String dateStr, List<TransactionModel> groupTxs) {
    String displayDate;
    try {
      final parsed = DateTime.parse(dateStr);
      displayDate = DateFormat('MMMM d, yyyy').format(parsed).toUpperCase();
    } catch (_) {
      displayDate = dateStr.toUpperCase();
    }

    double netTotal = 0.0;
    for (final tx in groupTxs) {
      if (tx.isExpense) {
        netTotal -= tx.amount;
      } else {
        netTotal += tx.amount;
      }
    }

    final int roundedNet = netTotal.round();
    final String sign = roundedNet < 0 ? '-' : (roundedNet > 0 ? '+' : '');

    final locker = AppColorLocker.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            displayDate,
            style: AppTypography.openSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: locker.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          RadixCurrencyText(
            prefix: sign,
            amount: roundedNet.abs().toDouble(),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: locker.textTertiary.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  final FloatingActionButtonLocation location;
  final double offsetY;

  const _CustomFloatingActionButtonLocation(
    this.location, {
    required this.offsetY,
  });

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset offset = location.getOffset(scaffoldGeometry);
    return Offset(offset.dx, offset.dy + offsetY);
  }
}
