import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';
import '../../../core/services/haptic_helper.dart';

/// A crimson reset trigger button with 5-second hold progress fill feedback.
class ResetButton extends StatefulWidget {
  final VoidCallback onPressed;
  final VoidCallback? onHoldComplete;
  final String label;

  const ResetButton({
    super.key,
    required this.onPressed,
    this.onHoldComplete,
    this.label = 'Hold to Reset',
  });

  @override
  State<ResetButton> createState() => _ResetButtonState();
}

class _ResetButtonState extends State<ResetButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _holdController;
  late Animation<double> _holdProgress;
  bool _isHolding = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );
    _holdProgress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _holdController, curve: Curves.linear));

    _holdController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _completed = true;
        HapticHelper.heavyImpact();
        if (widget.onHoldComplete != null) {
          widget.onHoldComplete!();
        } else {
          widget.onPressed();
        }
      }
    });
  }

  @override
  void dispose() {
    _holdController.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    _completed = false;
    setState(() => _isHolding = true);
    HapticHelper.lightImpact();
    _holdController.forward();
  }

  void _onPointerUp() {
    setState(() => _isHolding = false);
    if (_completed) {
      _holdController.reset();
      _completed = false;
    } else if (_holdController.value < 0.98) {
      _holdController.reverse();
    }
  }

  void _onPointerCancel() {
    setState(() => _isHolding = false);
    if (_completed) {
      _holdController.reset();
      _completed = false;
    } else {
      _holdController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    final accentRed = locker.accentRed;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 20),
        child: Listener(
          onPointerDown: (_) => _onPointerDown(),
          onPointerUp: (_) => _onPointerUp(),
          onPointerCancel: (_) => _onPointerCancel(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!_completed) {
                widget.onPressed();
              }
            },
            child: AnimatedBuilder(
              animation: _holdProgress,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isHolding ? 0.97 : 1.0,
                  child: Container(
                    width: 250,
                    height: 52,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      color: accentRed.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: accentRed.withValues(
                          alpha: _isHolding ? 0.85 : 0.45,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // 5-second fill progress
                        FractionallySizedBox(
                          widthFactor: _holdProgress.value > 0
                              ? _holdProgress.value
                              : 0.0,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: accentRed,
                              borderRadius: BorderRadius.circular(26),
                            ),
                          ),
                        ),
                        // Label with warning icon
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: locker.textOnDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isHolding
                                    ? '${((1 - _holdProgress.value) * 5).ceil()}s · ${widget.label}'
                                    : widget.label,
                                style: TextStyle(
                                  fontFamily: 'MonumentExtended-Regular',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: locker.textOnDark,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
