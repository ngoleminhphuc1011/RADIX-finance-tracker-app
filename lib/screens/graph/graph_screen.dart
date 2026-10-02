import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../core/theme/app_color_locker.dart';
import '../../core/theme/currency_provider.dart';
import 'widgets/graph_models.dart';
import 'widgets/donut_chart_card.dart';
import 'widgets/category_breakdown_list.dart';
import 'widgets/category_detail_list.dart';

class GraphScreen extends StatefulWidget {
  final bool isActive;
  final List<TransactionModel> transactions;

  const GraphScreen({
    super.key,
    this.isActive = false,
    required this.transactions,
  });

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  String? _selectedIconKey;
  ScrollPosition? _scrollPosition;
  double _swipeProgress = 0.0;
  bool _scrollThrottled = false;

  // ── Memoization caches ────────────────────────────────────────────────────
  List<AggregatedCategory>? _cachedCategories;
  int _cachedTxLength = -1;
  final Map<String, List<TransactionModel>> _detailCache = {};

  List<AggregatedCategory> _aggregateExpenses(BuildContext context) {
    final expenses = widget.transactions.where((tx) => tx.isExpense).toList();
    if (expenses.isEmpty) return [];

    final Map<String, double> sums = {};
    for (final tx in expenses) {
      final key = tx.category.isEmpty ? '' : tx.category;
      sums[key] = (sums[key] ?? 0.0) + tx.amount;
    }

    final List<AggregatedCategory> result = [];
    for (final entry in sums.entries) {
      final info = categoryRegistry[entry.key] ?? otherCategory;
      final iconKey = categoryRegistry.containsKey(entry.key)
          ? entry.key
          : '_other';
      result.add(
        AggregatedCategory(
          iconKey: iconKey,
          name: info.name,
          icon: info.icon,
          color: AppColorLocker.of(context).getCategoryColor(iconKey),
          amount: entry.value,
        ),
      );
    }

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
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

  List<AggregatedCategory> get _categories {
    final currentHash = _calculateHash();
    if (_cachedCategories != null && _cachedTxLength == currentHash) {
      return _cachedCategories!;
    }

    _cachedCategories = _aggregateExpenses(context);
    _cachedTxLength = currentHash;
    _detailCache.clear();
    return _cachedCategories!;
  }

  List<TransactionModel> _detailsForCategory(String iconKey) {
    if (_detailCache.containsKey(iconKey)) {
      return _detailCache[iconKey]!;
    }

    final expenses = widget.transactions.where((tx) => tx.isExpense).toList();
    final matching = iconKey == '_other'
        ? expenses.where(
            (tx) =>
                tx.category.isEmpty ||
                !categoryRegistry.containsKey(tx.category),
          )
        : expenses.where((tx) => tx.category == iconKey);

    final sorted = matching.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    _detailCache[iconKey] = sorted;
    return sorted;
  }

  double get _totalSpent =>
      _categories.fold(0.0, (sum, item) => sum + item.amount);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollPosition?.removeListener(_onScrollNotification);

    try {
      final scrollable = Scrollable.maybeOf(context);
      _scrollPosition = scrollable?.position;
      _scrollPosition?.addListener(_onScrollNotification);
      _onScrollNotification();
    } catch (e) {
      setState(() {
        _swipeProgress = 1.0;
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

    final double page = pos.pixels / pos.viewportDimension;
    double progress = (1.0 - page).clamp(0.0, 1.0);

    if (progress > 0.99) progress = 1.0;
    if (progress < 0.01) progress = 0.0;

    final bool isTerminal = progress == 0.0 || progress == 1.0;

    if (!isTerminal && _scrollThrottled) return;

    if (progress != _swipeProgress) {
      if (!isTerminal) {
        _scrollThrottled = true;
        Future.delayed(const Duration(milliseconds: 16), () {
          if (!mounted) return;
          _scrollThrottled = false;
        });
      }

      setState(() {
        _swipeProgress = progress;
        if (progress < 1.0) {
          _selectedIconKey = null;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cats = _categories;
    final bool hasData = cats.isNotEmpty;
    final locker = AppColorLocker.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      color: locker.graphBackground,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_selectedIconKey != null) {
                        setState(() {
                          _selectedIconKey = null;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 40,
                        left: 24,
                        right: 24,
                        bottom: 110,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            'ANALYTICS',
                            style: TextStyle(
                              fontFamily: 'MonumentExtended-Regular',
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: locker.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Donut Chart Card
                          DonutChartCard(
                            categories: cats,
                            selectedIconKey: _selectedIconKey,
                            swipeProgress: _swipeProgress,
                            totalSpent: _totalSpent,
                            onCategoryTapped: (key) {
                              setState(() {
                                _selectedIconKey = key;
                              });
                            },
                          ),
                          const SizedBox(height: 32),

                          // Drill-Down Bottom Section
                          if (hasData)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                layoutBuilder:
                                    (
                                      Widget? currentChild,
                                      List<Widget> previousChildren,
                                    ) {
                                      final children = List<Widget>.from(
                                        previousChildren,
                                      );
                                      if (currentChild != null) {
                                        children.add(currentChild);
                                      }
                                      return Stack(
                                        alignment: Alignment.topCenter,
                                        children: children,
                                      );
                                    },
                                transitionBuilder:
                                    (
                                      Widget child,
                                      Animation<double> animation,
                                    ) {
                                      final isDetail =
                                          child.key !=
                                          const ValueKey('CategoryList');
                                      return ClipRect(
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: Offset(
                                              isDetail ? 1.0 : -1.0,
                                              0.0,
                                            ),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                        ),
                                      );
                                    },
                                child: _selectedIconKey == null
                                    ? CategoryBreakdownList(
                                        categories: cats,
                                        totalSpent: _totalSpent,
                                        onCategorySelected: (key) {
                                          setState(() {
                                            _selectedIconKey = key;
                                          });
                                        },
                                      )
                                    : CategoryDetailList(
                                        iconKey: _selectedIconKey!,
                                        categories: cats,
                                        transactions: _detailsForCategory(
                                          _selectedIconKey!,
                                        ),
                                        onBack: () {
                                          setState(() {
                                            _selectedIconKey = null;
                                          });
                                        },
                                      ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
