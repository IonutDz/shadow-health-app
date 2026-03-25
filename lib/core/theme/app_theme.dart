import 'package:flutter/material.dart';

/// Colors extracted from ShadowHealth main.css dark theme
/// --background: 240 6% 4%  → #090A0F
/// --foreground: 0 0% 95%   → #F2F2F2
/// --primary: 160 84% 39%   → #0BC46D (emerald-ish green)
/// --card: 240 5% 8%        → #121217
/// --muted-foreground: 240 5% 64.9% → #9FA0B0
/// --border: 240 4% 22%     → #333340
/// --destructive: 0 62.8% 30.6% → #7C1D1D
class AppTheme {
  // ── Core palette (from CSS HSL → hex) ────────────────────────────
  static const Color background = Color(0xFF09090B);    // 240 6% 4%
  static const Color surface = Color(0xFF111116);        // 240 5% 8%
  static const Color card = Color(0xFF111116);
  static const Color border = Color(0xFF2E2E38);         // 240 4% 22%

  static const Color foreground = Color(0xFFF2F2F2);     // 0 0% 95%
  static const Color mutedForeground = Color(0xFF9EA3B0); // 240 5% 64.9%

  // Primary = emerald-ish green: hsl(160 84% 39%) = #0BC46D
  static const Color primary = Color(0xFF0BC46D);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  static const Color destructive = Color(0xFFEF4444);   // red-500

  // Accent colors (matching Nuxt page colors)
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color pink400 = Color(0xFFF472B6);
  static const Color violet400 = Color(0xFFA78BFA);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color red400 = Color(0xFFF87171);
  static const Color cyan400 = Color(0xFF22D3EE);

  // ── Theme ─────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primary,
          surface: surface,
          onSurface: foreground,
          error: destructive,
          onPrimary: primaryForeground,
          onSecondary: primaryForeground,
        ),
        scaffoldBackgroundColor: background,
        cardTheme: CardTheme(
          color: card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border, width: 0.5),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: foreground,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: foreground),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: surface,
          selectedItemColor: primary,
          unselectedItemColor: mutedForeground,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: primary.withOpacity(0.15),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          height: 64,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: primary, size: 22);
            }
            return const IconThemeData(color: mutedForeground, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              );
            }
            return const TextStyle(
              color: mutedForeground,
              fontSize: 10,
            );
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          hintStyle: const TextStyle(color: mutedForeground, fontSize: 14),
          labelStyle: const TextStyle(color: mutedForeground, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: destructive),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: primaryForeground,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          headlineLarge: TextStyle(
            color: foreground,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          headlineMedium: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
          titleLarge: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          titleMedium: TextStyle(
            color: foreground,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          bodyLarge: TextStyle(color: foreground, fontSize: 15),
          bodyMedium: TextStyle(color: foreground, fontSize: 14),
          bodySmall: TextStyle(color: mutedForeground, fontSize: 12),
          labelSmall: TextStyle(
            color: mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          space: 1,
          thickness: 0.5,
        ),
        iconTheme: const IconThemeData(color: mutedForeground, size: 20),
      );
}
