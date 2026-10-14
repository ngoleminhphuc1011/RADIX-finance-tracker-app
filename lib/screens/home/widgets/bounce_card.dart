import 'package:flutter/material.dart';

/// A card wrapper that provides a fluid press-and-bounce spring feedback.
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
      if (mounted) {
        widget.onAnimationComplete?.call();
      }
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
