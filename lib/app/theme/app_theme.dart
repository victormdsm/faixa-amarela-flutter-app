import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const yellow = Color(0xFFE8B000);
  static const yellowDark = Color(0xFFD4A000);
  static const yellowLight = Color(0xFFFFF4CC);
  static const ink = Color(0xFF1A1614);
  static const slate = Color(0xFF5C5248);
  static const surfaceSoft = Color(0xFFF8F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const success = Color(0xFF2DB388);
  static const successSurface = Color(0xFFE3F7F2);
  static const danger = Color(0xFFE05252);
  static const muted = Color(0xFF9A8E84);
  static const info = Color(0xFF1D4ED8);
  static const border = Color(0xFFE8E2DA);
  static const borderLight = Color(0xFFF3EFE9);
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999;
}

abstract final class AppTheme {
  static ThemeData light() {
    const outline = Color(0xFFDDE1EA);
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.yellow,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.yellow,
          onPrimary: AppColors.ink,
          secondary: const Color(0xFFFFD76A),
          onSecondary: AppColors.ink,
          surface: Colors.white,
          onSurface: AppColors.ink,
          outline: outline,
          error: AppColors.danger,
        );

    final textTheme = GoogleFonts.outfitTextTheme().copyWith(
      displayLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.syne(fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.syne(fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.syne(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.syne(fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.syne(fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 20),
      titleMedium: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 16),
      titleSmall: GoogleFonts.syne(fontWeight: FontWeight.w600, fontSize: 14),
      bodyLarge: GoogleFonts.outfit(fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.outfit(fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.outfit(fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
      labelMedium: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 12),
      labelSmall: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 11),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceSoft,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        actionsIconTheme: const IconThemeData(color: AppColors.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        height: 68,
        indicatorColor: AppColors.yellow.withAlpha(120),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.ink, size: 22);
          }
          return IconThemeData(
            color: AppColors.muted.withValues(alpha: 0.8),
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            );
          }
          return GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 0.5,
        space: 0,
      ),
    );

    return base.copyWith(
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
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
          borderSide: const BorderSide(color: AppColors.yellow, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        labelStyle: GoogleFonts.outfit(color: AppColors.slate, fontSize: 14),
        hintStyle: GoogleFonts.outfit(color: AppColors.muted, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1.2),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.ink;
            return Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return Colors.white;
            return AppColors.ink;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        side: const BorderSide(color: AppColors.border),
        labelStyle: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        contentTextStyle: GoogleFonts.outfit(
          color: AppColors.slate,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: Color(0x660F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
