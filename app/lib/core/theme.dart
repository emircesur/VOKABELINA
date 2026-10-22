import 'package:flutter/material.dart';

class Brand {
  static const gold = Color(0xFFE8832A);
  static const goldDark = Color(0xFFB8621A);
  static const teal = Color(0xFF1F8A8A);
  static const tealDark = Color(0xFF166868);
  static const red = Color(0xFFD64545);
  static const green = Color(0xFF3FA96B);
  static const cream = Color(0xFFFFF8EF);
  static const ink = Color(0xFF2D2A26);
}

ThemeData buildTheme(Brightness b) {
  final dark = b == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: Brand.gold,
    brightness: b,
    primary: dark ? const Color(0xFFFFA24D) : Brand.gold,
    secondary: Brand.teal,
    surface: dark ? const Color(0xFF1B1815) : Brand.cream,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: scheme.onSurface, fontSize: 20, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: dark ? const Color(0xFF26221E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: dark ? const Color(0xFF3A342D) : const Color(0xFFEADFCE), width: 1.5)),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xFF211D19) : Colors.white,
      indicatorColor: scheme.primary.withValues(alpha: 0.18),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0xFF26221E) : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dark ? const Color(0xFF3A342D) : const Color(0xFFEADFCE), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dark ? const Color(0xFF3A342D) : const Color(0xFFEADFCE), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
  );
}
