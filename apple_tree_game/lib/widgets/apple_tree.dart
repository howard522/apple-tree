import 'dart:math';
import 'package:flutter/material.dart';

class AppleTree extends StatelessWidget {
  final int apples;
  const AppleTree({super.key, required this.apples});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset('assets/tree.png'),                     // tree base
        ..._buildApples(context),
      ],
    );
  }

  List<Widget> _buildApples(BuildContext context) {
    final rnd = Random(apples); // deterministic per frame
    final List<Widget> list = [];
    for (int i = 0; i < apples; i++) {
      final dx = rnd.nextDouble() * 140 - 70;  // spread
      final dy = rnd.nextDouble() * 120 - 60;
      list.add(Positioned(
        top: 120 + dy,
        left: 160 + dx,
        child: Image.asset('assets/apple.png', width: 24, height: 24),
      ));
    }
    return list;
  }
}