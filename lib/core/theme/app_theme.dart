// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppColors {
  // Primary - Deep Navy
  static const Color primary = Color(0xFF0D1B2A);
  static const Color primaryLight = Color(0xFF1A2F45);
  // Accent - Electric Blue
  static const Color accent = Color(0xFF1565C0);
  static const Color accentLight = Color(0xFF1976D2);
  static const Color accentBright = Color(0xFF2196F3);
  // Background
  static const Color background = Color(0xFFF4F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEEF2F8);
  // Status
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF6F00);
  static const Color info = Color(0xFF0288D1);
  // Text
  static const Color textPrimary = Color(0xFF0D1B2A);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color textHint = Color(0xFF90A4AE);
  static const Color textWhite = Color(0xFFFFFFFF);
  // Border
  static const Color border = Color(0xFFDDE3EC);
  static const Color borderFocus = Color(0xFF1565C0);
}

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: 'DMSans',
        colorScheme: const ColorScheme.light(
          primary: AppColors.accent,
          secondary: AppColors.accentBright,
          surface: AppColors.surface,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          titleTextStyle: TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppColors.borderFocus, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          labelStyle: const TextStyle(color: AppColors.textSecondary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.textWhite,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'Syne',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
              fontFamily: 'Syne',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary),
          displayMedium: TextStyle(
              fontFamily: 'Syne',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          headlineLarge: TextStyle(
              fontFamily: 'Syne',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          headlineMedium: TextStyle(
              fontFamily: 'Syne',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          titleLarge: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
          titleMedium: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary),
          bodyLarge: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary),
          bodyMedium: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary),
          bodySmall: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textHint),
        ),
      );
}
