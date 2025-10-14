// lib/widgets/animated_background.dart
import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({Key? key, required this.child}) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                sin(_animation.value * 2 * pi) * 0.3,
                cos(_animation.value * 2 * pi) * 0.3,
              ),
              radius: 1.2,
              colors: [
                Color(0xFF667eea).withOpacity(0.4),
                Color(0xFF764ba2).withOpacity(0.2),
                Color(0xFF0A0D1A),
                Color(0xFF0A0D1A),
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}