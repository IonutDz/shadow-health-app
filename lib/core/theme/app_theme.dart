import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF6366F1);   // Indigo
  static const Color secondary = Color(0xFF22D3EE); // Cyan
  static const Color success = Color(0xFF22C55E);   // Green
  static const Color warning = Color(0xFFF59E0B);   // Amber
  static const Color error = Color(0xFFEF4444);     // Red
  static const Color surface = Color(0xFF1E1E2E);
  static const Color background = Color(0xFF0F0F1A);
  static const Color onBackground = Color(0xFFF1F5F9);
  static const Color card = Color(0xFF262640);

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
      error: error,
    ),
    scaffoldBackgroundColor: background,
    cardTheme: CardTheme(
      color: card,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: onBackground,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surface,
      selectedItemColor: primary,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: onBackground, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: onBackground, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: onBackground),
      bodyMedium: TextStyle(color: Colors.grey),
    ),
  );
}
