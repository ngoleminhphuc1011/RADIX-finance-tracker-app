import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/currency_provider.dart';
import 'transaction_tile.dart';
import 'icon_picker_sheet.dart';
import 'bounce_card.dart';
import '../../../core/services/haptic_helper.dart';

enum TransactionMode { expense, income }

/// Displays the bottom sheet dialog for adding a new expense or income transaction.
void showAddTransactionDialog(
  BuildContext context, {
  required void Function(TransactionModel) onAddTransaction,
  VoidCallback? onDialogDismissed,
}) {
  final locker = AppColorLocker.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: locker.barrierColor,
    builder: (BuildContext ctx) {
      return _AddTransactionSheet(onAddTransaction: onAddTransaction);
    },
  ).then((_) {
    onDialogDismissed?.call();
  });
}

class _AddTransactionSheet extends StatefulWidget {
  final void Function(TransactionModel) onAddTransaction;

  const _AddTransactionSheet({required this.onAddTransaction});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  static const EdgeInsets _ltrb24_16_24_0 = EdgeInsets.fromLTRB(24, 16, 24, 0);
  static const EdgeInsets _ltrb24_0_24_24 = EdgeInsets.fromLTRB(24, 0, 24, 24);

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

  static final Set<String> _validIconKeys = iconOptions.keys.toSet();

  final PageController _pageController = PageController(initialPage: 0);
  TransactionMode _transactionMode = TransactionMode.expense;
  bool _showAllocationDialog = false;
  double? _pendingIncomeAmount;
  String _pendingIncomeIconKey = '';
  String? _selectedIconKey;

  final TextEditingController _expenseTitleController = TextEditingController();
  final TextEditingController _expenseAmountController =
      TextEditingController();
  final TextEditingController _incomeTitleController = TextEditingController();
  final TextEditingController _incomeAmountController = TextEditingController();

  @override
  void dispose() {
    _pageController.dispose();
    _expenseTitleController.dispose();
    _expenseAmountController.dispose();
    _incomeTitleController.dispose();
    _incomeAmountController.dispose();
    super.dispose();
  }

  String _sanitizeIconKey() {
    if (_selectedIconKey != null && _validIconKeys.contains(_selectedIconKey)) {
      return _selectedIconKey!;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpense = _transactionMode == TransactionMode.expense;
    final locker = AppColorLocker.of(context);
    final Color accentColor = isExpense
        ? locker.expenseDialogAccent
        : locker.incomeDialogAccent;
    final Color accentTextColor = isExpense
        ? locker.expenseDialogText
        : locker.incomeDialogText;

    final mediaQuery = MediaQuery.of(context);
    final bool isLandscape = mediaQuery.orientation == Orientation.landscape;
    final double keyboardInset = mediaQuery.viewInsets.bottom;
    final bool isKeyboardOpen = keyboardInset > 0;
    final double maxHeight = mediaQuery.size.height * (isLandscape && isKeyboardOpen ? 0.98 : 0.9);
    final double topPadding = (isLandscape && isKeyboardOpen) ? 4.0 : 20.0;
    final double bottomOffset = isKeyboardOpen ? (isLandscape ? 4.0 : 8.0) : 20.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding,
          left: isLandscape ? 16 : 20,
          right: isLandscape ? 16 : 20,
          bottom: keyboardInset + bottomOffset,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {}, // Prevent taps inside dialog from closing
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 500, maxHeight: maxHeight),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: locker.dialogBackground,
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
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                                setState(() {
                                  _showAllocationDialog = false;
                                });
                              },
                              onSelected: (String selection) {
                                final double amount =
                                    _pendingIncomeAmount ?? 0.0;
                                final String incomeStrategy =
                                    selection == 'Add to Budget'
                                    ? 'add_to_budget'
                                    : 'deduct_from_spent';
                                HapticHelper.mediumImpact();
                                widget.onAddTransaction(
                                  TransactionModel(
                                    title: _incomeTitleController.text.trim(),
                                    amount: amount,
                                    type: 'income',
                                    incomeStrategy: incomeStrategy,
                                    category: _pendingIncomeIconKey,
                                  ),
                                );
                                _pendingIncomeAmount = null;
                                setState(() {
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
                                      color: locker.gridItemBackground,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (_transactionMode !=
                                                  TransactionMode.expense) {
                                                setState(() {
                                                  _transactionMode =
                                                      TransactionMode.expense;
                                                });
                                                _pageController.animateToPage(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                      : locker.textSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () {
                                              if (_transactionMode !=
                                                  TransactionMode.income) {
                                                setState(() {
                                                  _transactionMode =
                                                      TransactionMode.income;
                                                });
                                                _pageController.animateToPage(
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
                                              padding:
                                                  const EdgeInsets.symmetric(
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
                                                      : locker.textSecondary,
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
                                controller: _pageController,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _transactionMode = index == 0
                                        ? TransactionMode.expense
                                        : TransactionMode.income;
                                  });
                                },
                                children: [
                                  _buildModeInputs(
                                    titleController: _expenseTitleController,
                                    amountController: _expenseAmountController,
                                    hintText: 'e.g. Food / Shopping',
                                    accentColor: accentColor,
                                  ),
                                  _buildModeInputs(
                                    titleController: _incomeTitleController,
                                    amountController: _incomeAmountController,
                                    hintText: 'e.g. Salary / Freelance',
                                    accentColor: accentColor,
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

                                    if (isExpense) {
                                      final String title =
                                          _expenseTitleController.text.trim();
                                      final double? amount = double.tryParse(
                                        _expenseAmountController.text
                                            .replaceAll(',', '')
                                            .trim(),
                                      );
                                      if (title.isNotEmpty &&
                                          amount != null &&
                                          amount > 0) {
                                        HapticHelper.mediumImpact();
                                        widget.onAddTransaction(
                                          TransactionModel(
                                            title: title,
                                            amount: amount,
                                            type: 'expense',
                                            category: iconKey,
                                          ),
                                        );
                                        Navigator.pop(context);
                                      }
                                    } else {
                                      final String title =
                                          _incomeTitleController.text.trim();
                                      final double? amount = double.tryParse(
                                        _incomeAmountController.text
                                            .replaceAll(',', '')
                                            .trim(),
                                      );
                                      if (title.isNotEmpty &&
                                          amount != null &&
                                          amount > 0) {
                                        _pendingIncomeIconKey = iconKey;
                                        setState(() {
                                          _pendingIncomeAmount = amount;
                                          _showAllocationDialog = true;
                                        });
                                      }
                                    }
                                  },
                                  child: Text(
                                    'ADD',
                                    style: TextStyle(
                                      color: locker.textOnDark,
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
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeInputs({
    required TextEditingController titleController,
    required TextEditingController amountController,
    required String hintText,
    required Color accentColor,
  }) {
    final locker = AppColorLocker.of(context);
    final IconData? currentIcon = _selectedIconKey != null
        ? iconOptions[_selectedIconKey]
        : null;

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
                  style: AppTypography.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: locker.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: AppTypography.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: locker.textTertiary,
                    ),
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
                onTap: () => showIconPickerSheet(
                  context,
                  selectedIconKey: _selectedIconKey,
                  accentColor: accentColor,
                  onIconSelected: (newKey) {
                    setState(() {
                      _selectedIconKey = newKey;
                    });
                  },
                ),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: locker.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor, width: 1.5),
                  ),
                  child: Icon(
                    currentIcon ?? Icons.widgets_outlined,
                    color: _selectedIconKey != null
                        ? accentColor
                        : locker.textTertiary,
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
            style: TextStyle(
              fontFamily: 'MonumentExtended',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: locker.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                fontFamily: 'MonumentExtended',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: locker.textTertiary,
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text(
                  CurrencyProvider.read(context).symbol,
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: locker.textPrimary,
                  ),
                ),
              ),
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

  Widget _buildAllocationSubWindow({
    required BuildContext context,
    required VoidCallback onCancel,
    required void Function(String) onSelected,
  }) {
    final locker = AppColorLocker.of(context);

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
            bgColor: locker.incomeBg,
            iconColor: locker.incomeBadge,
            onTap: () => onSelected('Add to Budget'),
          ),
          const SizedBox(height: 14),
          _buildAllocationCard(
            label: 'Deduct from Spent',
            description: 'Offset what you spent',
            icon: Icons.remove_circle_outline,
            bgColor: locker.incomeStrategyDeductBg,
            iconColor: locker.incomeStrategyDeductFg,
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
                  style: AppTypography.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: locker.textTertiary,
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
    final locker = AppColorLocker.of(context);

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
                  color: locker.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: locker.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.openSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: locker.textSecondary,
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
