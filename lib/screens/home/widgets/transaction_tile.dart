import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/transaction_model.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/currency_provider.dart';
import '../../../core/widgets/radix_currency_text.dart';
import 'delete_confirm_dialog.dart';
import 'icon_picker_sheet.dart';

class TransactionTile extends StatefulWidget {
  final TransactionModel model;
  final bool isExpanded;
  final VoidCallback? onTap;
  final void Function(
    int id,
    String newIcon,
    String newDescription,
    double newAmount,
  )? onUpdateTransaction;
  final void Function(int id)? onDeleteTransaction;
  final VoidCallback? onCollapse;

  const TransactionTile({
    super.key,
    required this.model,
    this.isExpanded = false,
    this.onTap,
    this.onUpdateTransaction,
    this.onDeleteTransaction,
    this.onCollapse,
  });

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile>
    with SingleTickerProviderStateMixin {
  static final TextStyle _titleStyle = AppTypography.openSans(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  late TextEditingController _descController;
  late TextEditingController _amountController;
  late String _selectedCategory;

  late AnimationController _beamController;
  late Animation<double> _beamAnimation;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.model.title);
    _amountController = TextEditingController(
      text: _formatInitialAmount(widget.model.amount),
    );
    _selectedCategory = widget.model.category;

    _beamController = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _beamAnimation = CurvedAnimation(
      parent: _beamController,
      curve: Curves.easeInOutCubic,
    );

    if (widget.isExpanded) {
      _beamController.forward(from: 0.0);
    }
  }

  String _formatInitialAmount(double amount) {
    return amount == amount.toInt()
        ? amount.toInt().toString()
        : amount.toString();
  }

  void _resetFields() {
    _descController.text = widget.model.title;
    _amountController.text = _formatInitialAmount(widget.model.amount);
    _selectedCategory = widget.model.category;
  }

  @override
  void didUpdateWidget(covariant TransactionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If collapsing without saving or if model changed, safely discard unsaved edits
    if ((oldWidget.isExpanded && !widget.isExpanded) ||
        oldWidget.model != widget.model) {
      _resetFields();
    }

    // Trigger Google border-beam trace when expanding
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _beamController.forward(from: 0.0);
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _beamController.stop();
      _beamController.reset();
    }
  }

  @override
  void dispose() {
    _beamController.dispose();
    _descController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSave() {
    final String cleanAmount = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    final double? parsedAmount = double.tryParse(cleanAmount);
    if (_descController.text.trim().isNotEmpty &&
        parsedAmount != null &&
        parsedAmount > 0 &&
        widget.model.id != null) {
      widget.onUpdateTransaction?.call(
        widget.model.id!,
        _selectedCategory,
        _descController.text.trim(),
        parsedAmount,
      );
      widget.onCollapse?.call();
    }
  }

  void _onDelete() {
    if (widget.model.id == null) return;
    showDeleteConfirmDialog(
      context,
      model: widget.model,
      onDeleteTransaction: (id) {
        widget.onDeleteTransaction?.call(id);
        widget.onCollapse?.call();
      },
      onConfirmed: () {
        widget.onCollapse?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpense = widget.model.isExpense;
    final locker = AppColorLocker.of(context);
    final colors = widget.model.getColors(context);
    final Color fgColor = isExpense ? locker.expenseFg : locker.incomeFg;
    final IconData? resolvedHeaderIcon = iconOptions[_selectedCategory.isNotEmpty
        ? _selectedCategory
        : widget.model.category];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: AnimatedBuilder(
        animation: _beamAnimation,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _GoogleBorderBeamPainter(
              progress: _beamAnimation.value,
              beamColor: fgColor,
              borderRadius: 16.0,
              strokeWidth: 1.8,
            ),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 460),
          curve: Curves.easeInOutCubicEmphasized,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isExpense ? locker.expenseBorder : locker.incomeBorder,
              width: 0.9,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row (Always visible; tapping toggles expand/collapse)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: Row(
                  children: [
                    // Icon square — icon sits directly on tinted bg
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        resolvedHeaderIcon ?? Icons.widgets_outlined,
                        color: fgColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title
                    Expanded(
                      child: Text(
                        widget.model.title,
                        style: _titleStyle.copyWith(color: locker.textPrimary),
                      ),
                    ),
                    // Amount
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: RadixCurrencyText(
                          isExpense: isExpense,
                          amount: widget.model.amount,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: fgColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: widget.isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 460),
                      curve: Curves.easeInOutCubicEmphasized,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 20,
                        color: fgColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              // Inline Expandable Accordion Panel
              AnimatedSize(
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeInOutCubicEmphasized,
                alignment: Alignment.topCenter,
                child: widget.isExpanded
                    ? AnimatedOpacity(
                        opacity: widget.isExpanded ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        child: _buildExpandedContent(
                          context,
                          locker,
                          colors,
                          fgColor,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    AppColorLocker locker,
    ({Color bg, Color fg, Color badge}) colors,
    Color fgColor,
  ) {
    final bool isExpense = widget.model.isExpense;
    final Color pickerAccent = locker.getIconPickerAccent(isExpense: isExpense);
    final Color pickerBg = locker.getIconPickerBg(isExpense: isExpense);
    final Color pickerBorder = locker.getIconPickerBorder(isExpense: isExpense);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subtle hairline divider separating header and editing controls
          Container(
            height: 1,
            color: locker.textPrimary.withValues(alpha: 0.07),
            margin: const EdgeInsets.only(bottom: 12),
          ),
          // Top row: Category Badge + Description Input
          Row(
            children: [
              // Icon / Category selector: Compact square badge displaying current icon
              GestureDetector(
                onTap: () {
                  showIconPickerSheet(
                    context,
                    selectedIconKey: _selectedCategory,
                    accentColor: pickerAccent,
                    isExpense: isExpense,
                    onIconSelected: (newKey) {
                      setState(() {
                        _selectedCategory = newKey ?? '';
                      });
                    },
                  );
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: pickerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: pickerBorder,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        iconOptions[_selectedCategory.isNotEmpty
                                ? _selectedCategory
                                : widget.model.category] ??
                            Icons.category_rounded,
                        color: pickerAccent,
                        size: 22,
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: pickerAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 8,
                            color: locker.textOnDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Description input field
              Expanded(
                child: TextField(
                  controller: _descController,
                  style: AppTypography.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: locker.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Description',
                    hintStyle: AppTypography.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: locker.textTertiary,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: locker.scaffoldBackground.withValues(alpha: 0.5),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: locker.textPrimary.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: fgColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Amount input field
          Container(
            decoration: BoxDecoration(
              color: locker.scaffoldBackground.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: locker.textPrimary.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: [
                Text(
                  CurrencyProvider.read(context).symbol,
                  style: TextStyle(
                    fontFamily: null,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: fgColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      fontFamily: 'MonumentExtended',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontFamily: 'MonumentExtended',
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: fgColor.withValues(alpha: 0.3),
                      ),
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Action Bar (Bottom of expanded panel): Delete (left) + SAVE (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: locker.accentRed.withValues(alpha: 0.75),
                  size: 22,
                ),
                tooltip: 'Delete transaction',
                splashRadius: 18,
                onPressed: _onDelete,
              ),
              GestureDetector(
                onTap: _onSave,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.badge,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SAVE',
                    style: TextStyle(
                      fontFamily: 'MonumentExtended-Bold',
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: locker.textOnDark,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Google-inspired border beam painter that traces the outline of the tile
/// with a luminous radiant light streak when the tile expands.
class _GoogleBorderBeamPainter extends CustomPainter {
  final double progress;
  final Color beamColor;
  final double borderRadius;
  final double strokeWidth;

  const _GoogleBorderBeamPainter({
    required this.progress,
    required this.beamColor,
    this.borderRadius = 16.0,
    this.strokeWidth = 1.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0 || size.isEmpty) return;

    // Smooth entrance and exit fades
    double opacity = 1.0;
    if (progress < 0.15) {
      opacity = progress / 0.15;
    } else if (progress > 0.75) {
      opacity = (1.0 - progress) / 0.25;
    }
    opacity = opacity.clamp(0.0, 1.0);
    if (opacity <= 0.0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius),
    );

    // Clockwise beam starting from the top center
    final angle = progress * 2 * math.pi + math.pi / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(angle),
        colors: [
          Colors.transparent,
          beamColor.withValues(alpha: 0.0),
          beamColor.withValues(alpha: 0.35 * opacity),
          beamColor.withValues(alpha: 0.9 * opacity),
          Color.lerp(beamColor, Colors.white, 0.65)!
              .withValues(alpha: 1.0 * opacity),
          beamColor.withValues(alpha: 0.9 * opacity),
          beamColor.withValues(alpha: 0.35 * opacity),
          beamColor.withValues(alpha: 0.0),
          Colors.transparent,
        ],
        stops: const [
          0.0,
          0.36,
          0.42,
          0.48,
          0.50,
          0.52,
          0.58,
          0.64,
          1.0,
        ],
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GoogleBorderBeamPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.beamColor != beamColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Shared icon key-to-IconData mapping used by TransactionTile
/// and AddTransactionDialog.
const Map<String, IconData> iconOptions = {
  'fastfood': Icons.fastfood_outlined,
  'shopping_bag': Icons.shopping_bag_outlined,
  'directions_car': Icons.directions_car_filled_outlined,
  'home': Icons.home_outlined,
  'payments': Icons.payments_outlined,
  'work': Icons.work_outline,
  'school': Icons.school_outlined,
  'flight': Icons.flight_outlined,
  'fitness_center': Icons.fitness_center_outlined,
  'health_and_safety': Icons.health_and_safety_outlined,
  'pets': Icons.pets_outlined,
  'celebration': Icons.celebration_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  'train': Icons.train_outlined,
};
