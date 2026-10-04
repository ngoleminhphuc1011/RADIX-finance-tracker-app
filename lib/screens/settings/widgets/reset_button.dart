import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';

/// A reset trigger button with elastic bounce scale feedback.
class ResetButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ResetButton({super.key, required this.onPressed});

  @override
  State<ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<ResetButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<double> _resetScale;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _resetScale = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final accentRed = locker.accentRed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: SizedBox(
          height: 48,
          child: Listener(
            onPointerDown: (_) => _resetController.forward(),
            onPointerUp: (_) {
              _resetController.reverse();
              widget.onPressed();
            },
            onPointerCancel: (_) => _resetController.reverse(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => debugPrint('Reset button tapped'),
              child: ScaleTransition(
                scale: _resetScale,
                child: Container(
                  width: 200,
                  height: 50,
                  decoration: BoxDecoration(
                    color: accentRed,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      'Reset',
                      style: TextStyle(
                        fontFamily: 'MonumentExtended-Regular',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: locker.textOnDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
