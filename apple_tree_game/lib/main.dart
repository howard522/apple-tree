// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';

void main() => runApp(const AppleTreeGameApp());

class AppleTreeGameApp extends StatelessWidget {
  const AppleTreeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Apple Tree 🍎',
      themeMode: ThemeMode.system, // 可同時支援淺／深色模式
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E7D22), // 主色：深綠
          primary: const Color(0xFF3E7D22),
          secondary: const Color(0xFFF2A12B), // 輔色：金黃色
          background: const Color(0xFFF7F9F3), // 背景：米白
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.quicksandTextTheme(const TextTheme()).copyWith(
          bodyMedium: GoogleFonts.quicksand(fontSize: 16),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3E7D22),
          primary: const Color(0xFF3E7D22),
          secondary: const Color(0xFFF2A12B),
          background: const Color(0xFF1C1C1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.quicksandTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
      ),
      home: const HomePage(),
    );
  }
}
