/// LONE LINK — Theme System
///
/// Premium dark-first theme with a modern design language.
/// Inspired by Signal/Telegram aesthetics with custom LONE LINK branding.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// Color Palette
// ─────────────────────────────────────────────

class LoneLinkColors {
  LoneLinkColors._();

  // Primary brand colors — deep teal / cyan gradient feel
  static const Color primary = Color(0xFF00BFA6);
  static const Color primaryLight = Color(0xFF5DF2D6);
  static const Color primaryDark = Color(0xFF008E76);
  static const Color primarySurface = Color(0xFF0D3B34);

  // Accent — electric blue for highlights
  static const Color accent = Color(0xFF448AFF);
  static const Color accentLight = Color(0xFF83B9FF);

  // Semantic colors
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFEF5350);
  static const Color info = Color(0xFF42A5F5);

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0A0E14);
  static const Color darkSurface = Color(0xFF121820);
  static const Color darkSurfaceElevated = Color(0xFF1A2230);
  static const Color darkSurfaceHighest = Color(0xFF232D3F);
  static const Color darkCard = Color(0xFF151D28);
  static const Color darkDivider = Color(0xFF1E2A38);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F2F5);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFE2E8F0);

  // Text colors — dark theme
  static const Color darkTextPrimary = Color(0xFFE8EDF2);
  static const Color darkTextSecondary = Color(0xFF8B9DB5);
  static const Color darkTextTertiary = Color(0xFF5A6E85);

  // Text colors — light theme
  static const Color lightTextPrimary = Color(0xFF1A202C);
  static const Color lightTextSecondary = Color(0xFF5A6685);
  static const Color lightTextTertiary = Color(0xFF8B95A8);

  // Transport colors
  static const Color bleColor = Color(0xFF2196F3);
  static const Color internetColor = Color(0xFF66BB6A);
  static const Color bridgeColor = Color(0xFFFF9800);
  static const Color offlineColor = Color(0xFF78909C);

  // Message bubble colors
  static const Color outgoingBubbleDark = Color(0xFF0D3B34);
  static const Color incomingBubbleDark = Color(0xFF1A2230);
  static const Color outgoingBubbleLight = Color(0xFFD4F5ED);
  static const Color incomingBubbleLight = Color(0xFFF0F2F5);
}

// ─────────────────────────────────────────────
// Theme Data
// ─────────────────────────────────────────────

class LoneLinkTheme {
  LoneLinkTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Inter',

      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: LoneLinkColors.primary,
        onPrimary: Colors.black,
        secondary: LoneLinkColors.accent,
        onSecondary: Colors.white,
        surface: LoneLinkColors.darkSurface,
        onSurface: LoneLinkColors.darkTextPrimary,
        error: LoneLinkColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: LoneLinkColors.darkBg,

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: LoneLinkColors.darkSurface,
        foregroundColor: LoneLinkColors.darkTextPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LoneLinkColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // Navigation bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LoneLinkColors.darkSurface,
        indicatorColor: LoneLinkColors.primarySurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LoneLinkColors.primary,
            );
          }
          return const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: LoneLinkColors.darkTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: LoneLinkColors.primary, size: 24);
          }
          return const IconThemeData(color: LoneLinkColors.darkTextTertiary, size: 24);
        }),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: LoneLinkColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: LoneLinkColors.darkDivider.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Text
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: LoneLinkColors.darkTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: LoneLinkColors.darkTextPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: LoneLinkColors.darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: LoneLinkColors.darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: LoneLinkColors.darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: LoneLinkColors.darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: LoneLinkColors.darkTextTertiary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: LoneLinkColors.primary,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: LoneLinkColors.darkTextSecondary,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: LoneLinkColors.darkTextTertiary,
          letterSpacing: 0.5,
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LoneLinkColors.darkSurfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: LoneLinkColors.darkDivider.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LoneLinkColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          color: LoneLinkColors.darkTextTertiary,
          fontSize: 14,
        ),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LoneLinkColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating action button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LoneLinkColors.primary,
        foregroundColor: Colors.black,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: LoneLinkColors.darkDivider,
        thickness: 0.5,
        space: 0,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: LoneLinkColors.darkSurfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: LoneLinkColors.darkTextPrimary,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LoneLinkColors.darkSurfaceHighest,
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: LoneLinkColors.darkTextPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // List tile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: LoneLinkColors.darkTextPrimary,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: LoneLinkColors.darkTextSecondary,
        ),
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: LoneLinkColors.darkTextSecondary,
        size: 24,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: LoneLinkColors.darkSurfaceElevated,
        side: BorderSide(color: LoneLinkColors.darkDivider.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: 'Inter',

      colorScheme: const ColorScheme.light(
        primary: LoneLinkColors.primaryDark,
        onPrimary: Colors.white,
        secondary: LoneLinkColors.accent,
        onSecondary: Colors.white,
        surface: LoneLinkColors.lightSurface,
        onSurface: LoneLinkColors.lightTextPrimary,
        error: LoneLinkColors.error,
        onError: Colors.white,
      ),

      scaffoldBackgroundColor: LoneLinkColors.lightBg,

      appBarTheme: const AppBarTheme(
        backgroundColor: LoneLinkColors.lightSurface,
        foregroundColor: LoneLinkColors.lightTextPrimary,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: LoneLinkColors.lightTextPrimary,
          letterSpacing: -0.3,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LoneLinkColors.lightSurface,
        indicatorColor: LoneLinkColors.primaryDark.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: LoneLinkColors.primaryDark,
            );
          }
          return const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: LoneLinkColors.lightTextTertiary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: LoneLinkColors.primaryDark, size: 24);
          }
          return const IconThemeData(color: LoneLinkColors.lightTextTertiary, size: 24);
        }),
      ),

      cardTheme: CardThemeData(
        color: LoneLinkColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: LoneLinkColors.lightDivider.withValues(alpha: 0.8)),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w700, color: LoneLinkColors.lightTextPrimary, letterSpacing: -0.5),
        headlineMedium: TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w600, color: LoneLinkColors.lightTextPrimary, letterSpacing: -0.3),
        titleLarge: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w600, color: LoneLinkColors.lightTextPrimary),
        titleMedium: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: LoneLinkColors.lightTextPrimary),
        bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w400, color: LoneLinkColors.lightTextPrimary),
        bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w400, color: LoneLinkColors.lightTextSecondary),
        bodySmall: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w400, color: LoneLinkColors.lightTextTertiary),
        labelLarge: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600, color: LoneLinkColors.primaryDark),
        labelMedium: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: LoneLinkColors.lightTextSecondary),
        labelSmall: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w500, color: LoneLinkColors.lightTextTertiary, letterSpacing: 0.5),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LoneLinkColors.lightSurfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LoneLinkColors.lightDivider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: LoneLinkColors.primaryDark, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(fontFamily: 'Inter', color: LoneLinkColors.lightTextTertiary, fontSize: 14),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LoneLinkColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LoneLinkColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      dividerTheme: const DividerThemeData(color: LoneLinkColors.lightDivider, thickness: 0.5, space: 0),

      dialogTheme: DialogThemeData(
        backgroundColor: LoneLinkColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w500, color: LoneLinkColors.lightTextPrimary),
        subtitleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 13, color: LoneLinkColors.lightTextSecondary),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: LoneLinkColors.lightSurfaceElevated,
        side: const BorderSide(color: LoneLinkColors.lightDivider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
