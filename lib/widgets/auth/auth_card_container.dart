import 'package:flutter/material.dart';

class CardContainer extends StatelessWidget {

  final Widget child;

  const CardContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: Color(0xFFD9D9D9),
        ),
        child: this.child,
      ),
    );
  }
}
