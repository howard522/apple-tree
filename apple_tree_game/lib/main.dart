import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const AppleTreeGameApp());
}

class AppleTreeGameApp extends StatelessWidget {
  const AppleTreeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apple Tree 🍎',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HomePage(),
    );
  }
}