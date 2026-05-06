// lib/theme/app_theme.dart
// Autor: João Vitor Roventini
// RA: 22005168
// Tema central do MesclaInvest - dark theme estilo fintech moderna

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Paleta de Cores ────────────────────────────────────────────────────────
  static const Color background    = Color(0xFF0A0E1A);  // fundo principal
  static const Color surface       = Color(0xFF111827);  // cards e painéis
  static const Color surfaceLight  = Color(0xFF1C2537);  // bordas/divisores
  static const Color primary       = Color(0xFF00D4AA);  // verde-teal principal
  static const Color primaryDark   = Color(0xFF009E7F);  // variante escura
  static const Color accent        = Color(0xFF6C63FF);  // roxo acento
  static const Color gold          = Color(0xFFFFB700);  // dourado para tokens
  static const Color textPrimary   = Color(0xFFF0F4FF);  // texto principal
  static const Color textSecondary = Color(0xFF8B95A8);  // texto secundário
  static const Color textMuted     = Color(0xFF4A5568);  // texto desabilitado
  static const Color success       = Color(0xFF00D4AA);  // positivo
  static const Color warning       = Color(0xFFFFB700);  // alerta
  static const Color error         = Color(0xFFFF4B6E);  // erro

  // ─── Gradientes ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF6C63FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C2537), Color(0xFF111827)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0A0E1A), Color(0xFF0D1526)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── ThemeData ───────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        background: background,
        surface: surface,
        primary: primary,
        secondary: accent,
        error: error,
        onBackground: textPrimary,
        onSurface: textPrimary,
        onPrimary: background,
        onSecondary: textPrimary,
      ),

      // Tipografia - DM Sans + Space Grotesk (fontes modernas fintech)
      textTheme: GoogleFonts.dmSansTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: textPrimary, fontSize: 32,
            fontWeight: FontWeight.w700, letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            color: textPrimary, fontSize: 26,
            fontWeight: FontWeight.w700, letterSpacing: -0.3,
          ),
          headlineLarge: TextStyle(
            color: textPrimary, fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
          headlineMedium: TextStyle(
            color: textPrimary, fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: textPrimary, fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: textSecondary, fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(
            color: textPrimary, fontSize: 15,
          ),
          bodyMedium: TextStyle(
            color: textSecondary, fontSize: 13,
          ),
          labelLarge: TextStyle(
            color: textPrimary, fontSize: 14,
            fontWeight: FontWeight.w600, letterSpacing: 0.5,
          ),
        ),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: surfaceLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        errorStyle: const TextStyle(color: error, fontSize: 12),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: surfaceLight, width: 1),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: surfaceLight,
        thickness: 1,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.dmSans(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}