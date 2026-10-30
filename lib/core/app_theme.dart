import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF28644B);
  static const cream = Color(0xFFF7F5EC);
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: green, surface: cream),
    scaffoldBackgroundColor: cream,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: const Color(0xFF29352F),
      displayColor: const Color(0xFF29352F),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: cream, centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}
