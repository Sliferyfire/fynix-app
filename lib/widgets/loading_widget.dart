import 'package:flutter/material.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xff84B9BF);

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: backgroundColor,
      child: Stack(
        children: [
          // _GreenWaves(),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset(
                'assets/fynix_logo.png',
                height: 200,
                width: 200,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


