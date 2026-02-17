import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Titanium / 2026 Professional Palette ─────────────────
  static const Color primaryBlack = Color(0xFF000000);   // Void Black
  static const Color darkBackground = Color(0xFF050505); // Almost Black
  static const Color titanium = Color(0xFF1C1C1E);       // Dark Metal
  static const Color silver = Color(0xFF8E8E93);         // Classic Silver
  static const Color platinum = Color(0xFFE5E5EA);       // Bright Metal
  static const Color white = Color(0xFFFFFFFF);
  
  // Accents are subtle, not neon
  static const Color accentCrux = Color(0xFF0A84FF);     // Deep Electric Blue (iOS style)
  static const Color accentLuxe = Color(0xFFFFD60A);     // Gold/Amber (Premium)
  static const Color accentRose = Color(0xFFFF375F);     // Deep Rose

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF2C2C2E), Color(0xFF000000)], // Subtle metal gradient
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white10, Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Typography ───────────────────────────────────────────
  // Using 'Outfit' for modern, tech feel and 'Inter' for readability
  static TextTheme textTheme = TextTheme(
    displayLarge: GoogleFonts.outfit(
      fontSize: 40,
      fontWeight: FontWeight.w600,
      color: white,
      letterSpacing: -1.0,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w500,
      color: white,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: white,
      letterSpacing: -0.3,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: white,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: platinum,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: silver,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: white,
      letterSpacing: 0.5,
    ),
  );

  // ── Theme Data ───────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryBlack,
      primaryColor: primaryBlack,
      
      colorScheme: const ColorScheme.dark(
        primary: white,           // High contrast
        onPrimary: primaryBlack,
        secondary: titanium,
        onSecondary: white,
        surface: titanium,
        onSurface: white,
        error: accentRose,
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineMedium,
        iconTheme: const IconThemeData(color: white),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: white,
          foregroundColor: primaryBlack,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Soft pill shape
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          side: const BorderSide(color: Colors.white24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),

      // Input Decoration (Glassmorphism)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1C1E), // Dark Titanium
        contentPadding: const EdgeInsets.all(20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: white),
        ),
        hintStyle: textTheme.bodyMedium,
      ),
    );
  }
  
  // Shortcuts for common colors (legacy support + new)
  static const Color textPrimary = white;
  static const Color textSecondary = silver;
  static const Color textMuted = Color(0xFF636366);
  static const Color surface = titanium;
  static const Color surfaceLight = Color(0xFF2C2C2E);
  static const Color divider = Color(0xFF38383A);
  
  static const Color deepPurple = accentCrux; // Re-mapping to new palette
  static const Color accentPink = accentRose; // Re-mapping
  static const Color neonCyan = accentLuxe;   // Re-mapping
  static const Color textWhite = white;
  static const Color textGrey = silver;
  
  static const Color cardDark = titanium;
  static const Color background = primaryBlack;
  static const Color error = accentRose;
  static const Color success = Color(0xFF32D74B); // iOS Green
  static const Color warning = accentLuxe;
  static const Color accent = white;           // Primary accent is white/titanium
}
