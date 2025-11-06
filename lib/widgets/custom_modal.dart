import 'package:flutter/material.dart';

class CustomModal extends StatelessWidget {
  final Widget child;
  final Color backgroundColor;

  const CustomModal({
    super.key,
    required this.child,
    this.backgroundColor = const Color(0xFFD9D9D9),
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20)
      ),
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20),
      child: Container(
        width: double.infinity * 0.8,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: this.child,
      )
    );
  }
}
