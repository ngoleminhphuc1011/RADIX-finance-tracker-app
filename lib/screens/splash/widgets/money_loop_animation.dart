import 'package:flutter/material.dart';
import '../../../core/theme/app_color_locker.dart';

/// Clockwise sequential loop animation showing 4 shifting dots around a dollar sign.
class MoneyLoopAnimation extends StatefulWidget {
  const MoneyLoopAnimation({super.key});

  @override
  State<MoneyLoopAnimation> createState() => _MoneyLoopAnimationState();
}

class _MoneyLoopAnimationState extends State<MoneyLoopAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _topAnim;
  late Animation<double> _rightAnim;
  late Animation<double> _bottomAnim;
  late Animation<double> _leftAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _topAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 6),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 4),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _bottomAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 0.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 2),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _leftAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 6),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 12.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 12.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locker = AppColorLocker.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Top - moves UP
              Transform.translate(
                offset: Offset(0, -_topAnim.value),
                child: _buildDot(locker.focusBorder),
              ),
              // Right - moves RIGHT
              Transform.translate(
                offset: Offset(_rightAnim.value, 0),
                child: _buildDot(locker.focusBorder),
              ),
              // Bottom - moves DOWN
              Transform.translate(
                offset: Offset(0, _bottomAnim.value),
                child: _buildDot(locker.focusBorder),
              ),
              // Left - moves LEFT
              Transform.translate(
                offset: Offset(-_leftAnim.value, 0),
                child: _buildDot(locker.focusBorder),
              ),
              Text(
                '\$',
                style: TextStyle(
                  fontFamily: 'MonumentExtended',
                  fontSize: 19,
                  fontWeight: FontWeight.w400,
                  color: locker.textOnDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
