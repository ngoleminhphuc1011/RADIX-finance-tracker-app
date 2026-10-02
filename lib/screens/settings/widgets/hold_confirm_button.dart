import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';

/// A button that requires holding for 3 seconds to confirm an irreversible action.
class HoldConfirmButton extends StatefulWidget {
  final VoidCallback onConfirmed;

  const HoldConfirmButton({super.key, required this.onConfirmed});

  @override
  State<HoldConfirmButton> createState() => _HoldConfirmButtonState();
}

class _HoldConfirmButtonState extends State<HoldConfirmButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  late Animation<double> _holdProgress;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _holdProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _holdController, curve: Curves.linear));

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        debugPrint('Hold Confirm Success');
        widget.onConfirmed();
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final accentRed = locker.accentRed;

    return Listener(
      onPointerDown: (_) {
        setState(() => _isHolding = true);
        _holdController.forward();
      },
      onPointerUp: (_) {
        setState(() => _isHolding = false);
        _holdController.reset();
      },
      onPointerCancel: (_) {
        setState(() => _isHolding = false);
        _holdController.reset();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _holdProgress,
          builder: (context, child) {
            return Transform.scale(
              scale: _isHolding ? 0.95 : 1.0,
              child: Container(
                width: 120,
                height: 48,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: accentRed.withValues(alpha: 0.25)),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: _holdProgress.value,
                      alignment: Alignment.centerLeft,
                      child: Container(color: accentRed),
                    ),
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [locker.textOnDark, accentRed],
                          stops: [_holdProgress.value, _holdProgress.value],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'Confirm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'MonumentExtended-Regular',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: locker.textOnLight,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
