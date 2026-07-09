import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'instruction_screen.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_tile.dart';

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
    required this.onBudgetChanged,
    required this.onSpentChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _TransactionMode { expense, income }

class _HomeScreenState extends State<HomeScreen> {
  static final NumberFormat _currencyFormat = NumberFormat('#,###');

  // -- Shared constants (DRY) --
  static const Color _barrierColor = Color(0x66000000);
  static const Color _barrierColorLight = Color(0x4D000000);
  static const EdgeInsets _ltrb24_16_24_0 = EdgeInsets.fromLTRB(24, 16, 24, 0);
  static const EdgeInsets _ltrb24_0_24_24 = EdgeInsets.fromLTRB(24, 0, 24, 24);
  static const EdgeInsets _all24 = EdgeInsets.all(24);

  // -- Static const TextStyles (cache re-rendering) --
  static const TextStyle _styleLabelBlack18 = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 18,
    color: Colors.black,
  );
  static const TextStyle _styleBalance55 = TextStyle(
    fontFamily: 'MonumentExtended-Bold',
    fontSize: 55,
    fontWeight: FontWeight.w900,
    color: Colors.black,
  );
  static const TextStyle _styleBudgetLeft18 = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 18,
    color: Colors.black,
  );
  static const TextStyle _styleEmptyState = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 14,
    color: Color(0xFF9E9E9E),
  );
  static const TextStyle _styleDeleteTitle = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle _styleDeleteDesc = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 14,
    color: Colors.black54,
    height: 1.4,
  );
  static const TextStyle _styleDialogBtn = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 13,
    color: Colors.black54,
  );
  static const TextStyle _styleDialogBtnWhite = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 13,
    color: Colors.white,
  );
  static const TextStyle _styleAddTransTitle = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle _styleTabLabel = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 13,
    fontWeight: FontWeight.w100,
  );
  static const TextStyle _styleAllocateTitle = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.3,
  );
  static const TextStyle _styleAllocCardLabel = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );
  static const TextStyle _styleSelectIcon = TextStyle(
    fontFamily: 'MonumentExtended-Regular',
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  // Icon picker state
  String? _selectedIconKey;
  static const Set<String> _validIconKeys = <String>{
    'fastfood',
    'shopping_bag',
    'directions_car',
    'home',
    'payments',
    'work',
    'school',
    'flight',
    'fitness_center',
    'health_and_safety',
    'pets',
    'celebration',
    'local_gas_station',
    'train',
  };

  String currentSort = 'Date';
  double sortTurns = 0.0;
  bool _isPlusRotated = false;

  _TransactionMode _transactionMode = _TransactionMode.expense;
  bool _showAllocationDialog = false;
  double? _pendingIncomeAmount;

  // Independent controllers for Expense mode
  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();

  // Independent controllers for Income mode
  final TextEditingController _incomeTitleController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();

  String _pendingIncomeIconKey = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Re-applies the currently active sort mode to the list (RAM only).
  void _applyCurrentSort() {
    if (currentSort == 'Date') {
      // Sort newest-first by the ISO8601 date string (lexicographic = chronological)
      widget.transactions.sort((a, b) => b.date.compareTo(a.date));
    } else if (currentSort == 'Highest') {
      widget.transactions.sort((a, b) => b.amount.compareTo(a.amount));
    } else if (currentSort == 'Category') {
      widget.transactions.sort((a, b) => a.category.compareTo(b.category));
    } else if (currentSort == 'Flow') {
      widget.transactions.sort(
        (a, b) => (b.isExpense ? 1 : 0) - (a.isExpense ? 1 : 0),
      );
    }
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
      _applyCurrentSort();
    });
    debugPrint('Sort changed to: $currentSort');
  }

  void _showMorphDialog(BuildContext context, TransactionModel model) {
    final colors = model.getColors();
    final Color amountColor = colors.fg;
    final Color badgeColor = colors.badge;

    // -- Local editing state (isolated per dialog instance) --
    // Use category as the icon key for the edit dialog picker
    String localIconKey = model.category;
    final TextEditingController descController = TextEditingController(
      text: model.title,
    );
    final TextEditingController amountController = TextEditingController(
      text: model.amount.toString(),
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Morph Dialog',
      transitionDuration: const Duration(milliseconds: 400),
      barrierColor: _barrierColor,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final Size screenSize = MediaQuery.of(context).size;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final IconData? currentIcon = iconOptions[localIconKey];
            return Center(
              child: Material(
                type: MaterialType.transparency,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width * 0.80,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: colors.bg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Top Row: date + type badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'date (chưa có)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black38,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: amountColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  model.isExpense ? 'EXPENSE' : 'INCOME',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Category icon — clickable to open icon picker
                          GestureDetector(
                            onTap: () => _showIconPickerSheet(
                              context,
                              accentColor: amountColor,
                              onIconSelected: () {
                                // The icon picker already set _selectedIconKey;
                                // read it and update local state.
                                if (_selectedIconKey != null) {
                                  setDialogState(() {
                                    localIconKey = _selectedIconKey!;
                                  });
                                  // Clear global selection so it doesn't
                                  // leak into the "Add" dialog.
                                  setState(() {
                                    _selectedIconKey = null;
                                  });
                                }
                              },
                            ),
                            child: Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                currentIcon ?? Icons.widgets_outlined,
                                color: amountColor,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Description — editable TextField
                          TextField(
                            controller: descController,
                            style: const TextStyle(
                              fontFamily: 'MonumentExtended-Regular',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Enter description',
                              hintStyle: TextStyle(
                                fontFamily: 'MonumentExtended-Regular',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black38,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Amount (heavy visual anchor) — editable
                          TextField(
                            controller: amountController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'MonumentExtended-Regular',
                              fontSize: 50,
                              fontWeight: FontWeight.w800,
                              color: amountColor,
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Bottom Row: delete (left) + SAVE (right)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Delete icon — low-profile, muted pastel red
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: const Color(
                                    0xFFE57373,
                                  ).withValues(alpha: 0.6),
                                  size: 28,
                                ),
                                splashRadius: 20,
                                onPressed: () {
                                  _showDeleteConfirmDialog(context, model);
                                },
                              ),
                              // SAVE button — prominent primary action
                              GestureDetector(
                                onTap: () {
                                  final double? parsedNewAmount =
                                      double.tryParse(amountController.text);
                                  if (parsedNewAmount == null) return;
                                  final int? txId = model.id;
                                  if (txId == null) return;
                                  widget.onUpdateTransaction?.call(
                                    txId,
                                    localIconKey,
                                    descController.text,
                                    parsedNewAmount,
                                  );
                                  // Re-apply current sort so the tile jumps
                                  // to its correct position instantly.
                                  _applyCurrentSort();
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'SAVE',
                                    style: TextStyle(
                                      fontFamily: 'MonumentExtended-Bold',
                                      fontSize: 19,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBudgetInputDialog(BuildContext context) {
    final TextEditingController budgetController = TextEditingController(
      text: widget.monthlyBudget == 0
          ? ''
          : widget.monthlyBudget.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _barrierColor,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Container(
            padding: _all24,
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
                        widget.onBudgetChanged(enteredBudget);
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
    final bool isOverBudget = widget.spent > widget.monthlyBudget;
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
        child: RepaintBoundary(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                // Balance Card
                BounceCard(
                  onAnimationComplete: () {
                    _showBudgetInputDialog(context);
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                    ).add(const EdgeInsets.only(top: 8, bottom: 16)),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isOverBudget
                            ? Colors.redAccent.withValues(alpha: 0.7)
                            : const Color(0xFFA3E4D7),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        Text('SPENT', style: _styleLabelBlack18),
                        const SizedBox(height: 4),
                        Text(
                          '\$${_currencyFormat.format(widget.spent)}',
                          style: _styleBalance55,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'BUDGET LEFT: \$${_currencyFormat.format(widget.monthlyBudget - widget.spent)}',
                          style: _styleBudgetLeft18,
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
                                fontFamily: 'MonumentExtended-Regular',
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
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
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Transaction List or Empty State
                Expanded(
                  child: widget.transactions.isEmpty
                      ? Center(
                          child: Text(
                            "PRESS '+' TO ADD\nTRANSACTION",
                            textAlign: TextAlign.center,
                            style: _styleEmptyState,
                          ),
                        )
                      : AnimatedSwitcher(
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
                          child: ScrollConfiguration(
                            behavior: const ScrollBehavior().copyWith(
                              scrollbars: false,
                            ),
                            child: ListView.builder(
                              controller: _scrollController,
                              key: ValueKey<String>(currentSort),
                              padding: const EdgeInsets.only(bottom: 80),
                              physics: const BouncingScrollPhysics(),
                              itemCount: widget.transactions.length,
                              itemBuilder: (context, index) {
                                return TransactionTile(
                                  model: widget.transactions[index],
                                  onTap: () => _showMorphDialog(
                                    context,
                                    widget.transactions[index],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: BounceCard(
        onAnimationComplete: () {
          setState(() {
            _isPlusRotated = true;
          });
          Future.delayed(
            const Duration(milliseconds: 150),
            _showAddTransactionDialogDelayed,
          );
        },
        child: FloatingActionButton(
          backgroundColor: Colors.black,
          onPressed: null,
          elevation: 0,
          highlightElevation: 0,
          child: AnimatedRotation(
            turns: _isPlusRotated ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  String _sanitizeIconKey() {
    if (_selectedIconKey != null && _validIconKeys.contains(_selectedIconKey)) {
      return _selectedIconKey!;
    }
    return '';
  }

  void _showAddTransactionDialogDelayed() {
    if (mounted) {
      _showAddTransactionDialog(context);
    }
  }

  /// Shows a modern minimalist delete confirmation with fluid bounce animation.
  void _showDeleteConfirmDialog(
    BuildContext dialogContext,
    TransactionModel model,
  ) {
    showGeneralDialog(
      context: dialogContext,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Delete Confirm',
      transitionDuration: const Duration(milliseconds: 350),
      barrierColor: _barrierColor,
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 48),
              constraints: const BoxConstraints(maxWidth: 360),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delete Transaction?', style: _styleDeleteTitle),
                    const SizedBox(height: 12),
                    const Text(
                      'Are you sure you want to delete this?'
                      ' This action cannot be undone.',
                      style: _styleDeleteDesc,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                              child: const Center(
                                child: Text('Cancel', style: _styleDialogBtn),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final int? txId = model.id;
                              if (txId == null) return;
                              widget.onDeleteTransaction(txId);
                              Navigator.pop(context); // confirm dialog
                              Navigator.pop(dialogContext); // morph dialog
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFC62828),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text(
                                  'Delete',
                                  style: _styleDialogBtnWhite,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final PageController pageController = PageController(initialPage: 0);
    _transactionMode = _TransactionMode.expense;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _barrierColor,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isExpense = _transactionMode == _TransactionMode.expense;
            final Color accentColor = isExpense
                ? const Color(0xFFE57373)
                : const Color(0xFF81C784);
            final Color accentTextColor = isExpense
                ? const Color(0xFF78281F)
                : const Color(0xFF117A65);

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: accentColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: _showAllocationDialog
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 4,
                            color: accentColor.withValues(alpha: 0.6),
                          ),
                          _buildAllocationSubWindow(
                            context: context,
                            onCancel: () {
                              setDialogState(() {
                                _showAllocationDialog = false;
                              });
                            },
                            onSelected: (String selection) {
                              debugPrint('Selected: $selection');
                              final double amount = _pendingIncomeAmount ?? 0.0;
                              final String incomeStrategy =
                                  selection == 'Add to Budget'
                                  ? 'add_to_budget'
                                  : 'deduct_from_spent';
                              widget.onAddTransaction(
                                TransactionModel(
                                  // id is null — assigned by SQLite on insert
                                  title: _incomeTitleController.text,
                                  amount: amount,
                                  type: 'income',
                                  incomeStrategy: incomeStrategy,
                                  category: _pendingIncomeIconKey,
                                  date: DateTime.now().toIso8601String(),
                                ),
                              );
                              // Balances are recomputed from scratch by
                              // recalculateGlobalBalances() inside _addTransaction.
                              _pendingIncomeAmount = null;
                              setDialogState(() {
                                _showAllocationDialog = false;
                              });
                              _expenseTitleController.clear();
                              _expenseAmountController.clear();
                              _incomeTitleController.clear();
                              _incomeAmountController.clear();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 4,
                            color: accentColor.withValues(alpha: 0.6),
                          ),
                          Padding(
                            padding: _ltrb24_16_24_0,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ADD TRANSACTION',
                                  style: _styleAddTransTitle,
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_transactionMode !=
                                                _TransactionMode.expense) {
                                              setDialogState(() {
                                                _transactionMode =
                                                    _TransactionMode.expense;
                                              });
                                              pageController.animateToPage(
                                                0,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves
                                                    .fastLinearToSlowEaseIn,
                                              );
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isExpense
                                                  ? accentColor.withValues(
                                                      alpha: 0.25,
                                                    )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Expense',
                                              style: _styleTabLabel.copyWith(
                                                color: isExpense
                                                    ? accentTextColor
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            if (_transactionMode !=
                                                _TransactionMode.income) {
                                              setDialogState(() {
                                                _transactionMode =
                                                    _TransactionMode.income;
                                              });
                                              pageController.animateToPage(
                                                1,
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                curve: Curves
                                                    .fastLinearToSlowEaseIn,
                                              );
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: !isExpense
                                                  ? accentColor.withValues(
                                                      alpha: 0.25,
                                                    )
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Income',
                                              style: _styleTabLabel.copyWith(
                                                color: !isExpense
                                                    ? accentTextColor
                                                    : Colors.grey[600],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 196,
                            child: PageView(
                              controller: pageController,
                              physics: const BouncingScrollPhysics(),
                              onPageChanged: (index) {
                                setDialogState(() {
                                  _transactionMode = index == 0
                                      ? _TransactionMode.expense
                                      : _TransactionMode.income;
                                });
                              },
                              children: [
                                _buildModeInputs(
                                  titleController: _expenseTitleController,
                                  amountController: _expenseAmountController,
                                  hintText: 'e.g. Food / Shopping',
                                  accentColor: accentColor,
                                  onIconSelected: () => setDialogState(() {}),
                                ),
                                _buildModeInputs(
                                  titleController: _incomeTitleController,
                                  amountController: _incomeAmountController,
                                  hintText: 'e.g. Salary / Freelance',
                                  accentColor: accentColor,
                                  onIconSelected: () => setDialogState(() {}),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: _ltrb24_0_24_24,
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  final String iconKey = _sanitizeIconKey();
                                  debugPrint('Selected icon key: $iconKey');

                                  if (isExpense) {
                                    final String title =
                                        _expenseTitleController.text;
                                    final double? amount = double.tryParse(
                                      _expenseAmountController.text,
                                    );
                                    if (title.isNotEmpty && amount != null) {
                                      widget.onAddTransaction(
                                        TransactionModel(
                                          // id is null — assigned by SQLite on insert
                                          title: title,
                                          amount: amount,
                                          type: 'expense',
                                          category: iconKey,
                                          date: DateTime.now().toIso8601String(),
                                        ),
                                      );
                                      Navigator.pop(context);
                                    }
                                  } else {
                                    final String title =
                                        _incomeTitleController.text;
                                    final double? amount = double.tryParse(
                                      _incomeAmountController.text,
                                    );
                                    if (title.isNotEmpty && amount != null) {
                                      _pendingIncomeIconKey = iconKey;
                                      setDialogState(() {
                                        _pendingIncomeAmount = amount;
                                        _showAllocationDialog = true;
                                      });
                                    }
                                  }
                                },
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'MonumentExtended-Regular',
                                    fontWeight: FontWeight.w100,
                                  ),
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
      },
    ).then((_) {
      if (mounted) {
        setState(() {
          _isPlusRotated = false;
        });
        _expenseTitleController.clear();
        _expenseAmountController.clear();
        _incomeTitleController.clear();
        _incomeAmountController.clear();
      }
    });
  }

  Widget _buildModeInputs({
    required TextEditingController titleController,
    required TextEditingController amountController,
    required String hintText,
    required Color accentColor,
    VoidCallback? onIconSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accentColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showIconPickerSheet(
                  context,
                  accentColor: accentColor,
                  onIconSelected: onIconSelected,
                ),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor, width: 1.5),
                  ),
                  child: Icon(
                    _selectedIconKey != null
                        ? iconOptions[_selectedIconKey]!
                        : Icons.widgets_outlined,
                    color: _selectedIconKey != null
                        ? accentColor
                        : Colors.grey[400],
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '\$0.00',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accentColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showIconPickerSheet(
    BuildContext context, {
    VoidCallback? onIconSelected,
    Color accentColor = const Color(0xFFE57373),
  }) {
    final Color selectedBgColor = accentColor.withValues(alpha: 0.15);
    final Color selectedBorderColor = accentColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _barrierColorLight,
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: 20,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.35,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      Text(
                        'SELECT ICON',
                        style: _styleSelectIcon.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIconKey = null;
                          });
                          onIconSelected?.call();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'None',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[400],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: iconOptions.length,
                      itemBuilder: (context, index) {
                        final entry = iconOptions.entries.elementAt(index);
                        final String key = entry.key;
                        final IconData icon = entry.value;
                        final bool isSelected = _selectedIconKey == key;
                        return _IconTile(
                          icon: icon,
                          isSelected: isSelected,
                          selectedBgColor: selectedBgColor,
                          selectedBorderColor: selectedBorderColor,
                          onTap: () {
                            setState(() {
                              _selectedIconKey = key;
                            });
                            onIconSelected?.call();
                            Navigator.pop(ctx);
                          },
                        );
                      },
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

  Widget _buildAllocationSubWindow({
    required BuildContext context,
    required VoidCallback onCancel,
    required void Function(String) onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Allocate Your Income',
              textAlign: TextAlign.center,
              style: _styleAllocateTitle,
            ),
          ),
          const SizedBox(height: 24),
          _buildAllocationCard(
            label: 'Add to Budget',
            description: 'Increase your monthly limit',
            icon: Icons.trending_up,
            bgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            onTap: () => onSelected('Add to Budget'),
          ),
          const SizedBox(height: 14),
          _buildAllocationCard(
            label: 'Deduct from Spent',
            description: 'Offset what you spent',
            icon: Icons.remove_circle_outline,
            bgColor: const Color.fromARGB(255, 216, 224, 247),
            iconColor: const Color.fromARGB(255, 76, 140, 180),
            onTap: () => onSelected('Deduct from Spent'),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onCancel,
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended-Regular',
                    fontSize: 12,
                    color: Colors.grey[500],
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationCard({
    required String label,
    required String description,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: BounceCard(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: _styleAllocCardLabel),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final Color selectedBgColor;
  final Color selectedBorderColor;
  final VoidCallback onTap;

  const _IconTile({
    required this.icon,
    required this.isSelected,
    required this.selectedBgColor,
    required this.selectedBorderColor,
    required this.onTap,
  });

  @override
  State<_IconTile> createState() => _IconTileState();
}

class _IconTileState extends State<_IconTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: widget.isSelected
                ? widget.selectedBgColor
                : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(color: widget.selectedBorderColor, width: 1.5)
                : null,
          ),
          child: Icon(
            widget.icon,
            color: widget.isSelected
                ? widget.selectedBorderColor
                : Colors.grey[600],
            size: 26,
          ),
        ),
      ),
    );
  }
}

class BounceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onAnimationComplete;

  const BounceCard({
    super.key,
    required this.child,
    this.onTap,
    this.onAnimationComplete,
  });

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    _controller.forward();
  }

  void _handlePointerUp(PointerUpEvent event) {
    _controller.reverse().whenComplete(() {
      widget.onAnimationComplete?.call();
    });
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handlePointerDown,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
