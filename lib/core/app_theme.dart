import 'package:flutter/material.dart';

class AppTheme {
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF1B4332);
  static const secondary = Color(0xFF95D5B2);
  static const accent = Color(0xFFE07A5F);
  static const text = Color(0xFF212529);
  static const muted = Color(0xFF6C757D);
  static const border = Color(0xFFE7EBE8);
  static const cardRadius = 24.0;
  static const gap = 16.0;

  static double pageInset(double width) => width < 360 ? 16 : 24;

  static ThemeData get light {
    final colors = ColorScheme.fromSeed(seedColor: primary).copyWith(
      primary: primary,
      onPrimary: surface,
      secondary: secondary,
      onSecondary: primary,
      tertiary: accent,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: muted,
      outlineVariant: border,
      primaryContainer: const Color(0xFFEAF4ED),
      onPrimaryContainer: primary,
    );
    final typography = ThemeData.light().textTheme
        .apply(
          fontFamily: 'PlusJakartaSans',
          bodyColor: text,
          displayColor: text,
        )
        .copyWith(
          displaySmall: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 34,
            height: 1.18,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: text,
          ),
          headlineMedium: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 28,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: text,
          ),
          headlineSmall: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 23,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
            color: text,
          ),
          titleLarge: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 19,
            height: 1.4,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.35,
            color: text,
          ),
          titleMedium: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            height: 1.4,
            fontWeight: FontWeight.w600,
            color: text,
          ),
          bodyLarge: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 16,
            height: 1.6,
            color: text,
          ),
          bodyMedium: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            height: 1.55,
            color: text,
          ),
          bodySmall: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 12,
            height: 1.5,
            color: muted,
          ),
          labelLarge: const TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w700,
            color: text,
          ),
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      fontFamily: 'PlusJakartaSans',
      textTheme: typography,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: typography.titleLarge,
      ),
      iconTheme: const IconThemeData(color: primary, size: 24),
      dividerTheme: const DividerThemeData(color: border, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: typography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F4F1),
        side: BorderSide.none,
        labelStyle: typography.bodySmall?.copyWith(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: const Color(0xFFEAF4ED),
        labelTextStyle: WidgetStatePropertyAll(
          typography.bodySmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
      ),
    );
  }
}
