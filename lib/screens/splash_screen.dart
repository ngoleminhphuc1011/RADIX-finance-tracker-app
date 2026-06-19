import 'package:flutter/material.dart';
import 'nav_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
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

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const NavWrapper()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Central content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'RADIX',
                  style: TextStyle(
                    fontFamily: 'MonumentExtended',
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 40),
                // Clockwise sequential loop animation
                AnimatedBuilder(
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
                            child: _buildDot(),
                          ),
                          // Right - moves RIGHT
                          Transform.translate(
                            offset: Offset(_rightAnim.value, 0),
                            child: _buildDot(),
                          ),
                          // Bottom - moves DOWN
                          Transform.translate(
                            offset: Offset(0, _bottomAnim.value),
                            child: _buildDot(),
                          ),
                          // Left - moves LEFT
                          Transform.translate(
                            offset: Offset(-_leftAnim.value, 0),
                            child: _buildDot(),
                          ),
                          Text(
                            '\$',
                            style: TextStyle(
                              fontFamily: 'MonumentExtended',
                              fontSize: 19,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Branding footer
          const Positioned(
            bottom: 24,
            right: 24,
            child: Text(
              'Fulton Ngo corporation',
              style: TextStyle(
                fontFamily: 'FontUltra',
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF00E676),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
