import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import 'transaction_tile.dart';

class IconTile extends StatefulWidget {
  final IconData icon;
  final bool isSelected;
  final Color selectedBgColor;
  final Color selectedBorderColor;
  final VoidCallback onTap;

  const IconTile({
    super.key,
    required this.icon,
    required this.isSelected,
    required this.selectedBgColor,
    required this.selectedBorderColor,
    required this.onTap,
  });

  @override
  State<IconTile> createState() => _IconTileState();
}

class _IconTileState extends State<IconTile>
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
                : AppColorLocker.of(context).gridItemBackground,
            borderRadius: BorderRadius.circular(12),
            border: widget.isSelected
                ? Border.all(color: widget.selectedBorderColor, width: 1.5)
                : null,
          ),
          child: Icon(
            widget.icon,
            color: widget.isSelected
                ? widget.selectedBorderColor
                : AppColorLocker.of(context).textSecondary,
            size: 26,
          ),
        ),
      ),
    );
  }
}

/// Opens the icon picker bottom sheet for choosing or clearing category icons.
void showIconPickerSheet(
  BuildContext context, {
  String? selectedIconKey,
  ValueChanged<String?>? onIconSelected,
  Color accentColor = const Color(0xFFE57373),
}) {
  final Color selectedBgColor = accentColor.withValues(alpha: 0.15);
  final Color selectedBorderColor = accentColor;
  final locker = AppColorLocker.of(context);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: locker.barrierColorLight,
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
            color: locker.dialogBackground,
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
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: locker.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        onIconSelected?.call(null);
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        'None',
                        style: TextStyle(
                          fontSize: 13,
                          color: locker.textTertiary,
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
                      final bool isSelected = selectedIconKey == key;
                      return IconTile(
                        icon: icon,
                        isSelected: isSelected,
                        selectedBgColor: selectedBgColor,
                        selectedBorderColor: selectedBorderColor,
                        onTap: () {
                          onIconSelected?.call(key);
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
