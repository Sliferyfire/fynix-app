import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FondoLogin extends StatelessWidget {

  final Widget child;

  const FondoLogin({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        children: [
          _GreenWaves(),
          SafeArea(
            child: Container(
              margin: EdgeInsets.only(top: 30),
              width: double.infinity,
              child: Column(
                children: [
                  Image.asset('assets/fynix_logo.png', width: 100, height: 100),
                  Text(
                    'Fynix',
                    style: GoogleFonts.marcellusSc(
                      color: Color(0xFF06373E),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      wordSpacing: 0.01,
                    ),
                  ),
                ],
              ),
            ),
          ),
          this.child,
        ],
      ),
    );
  }
}

class _GreenWaves extends StatelessWidget {
  //const _GreenWaves({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Image.asset(
            'assets/waves/Wave_G1.png',
            width: double.infinity,
            height: size.height * 0.2,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Image.asset(
            'assets/waves/Wave_G2.png',
            width: double.infinity,
            height: size.height * 0.2,
            fit: BoxFit.fill,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          left: 0,
          child: Image.asset(
            'assets/waves/Wave_G3.png',
            width: double.infinity,
            height: size.height * 0.2,
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}
