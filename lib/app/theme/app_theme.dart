import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppColors {
  /// Pantone 1375 C — amarelo oficial Faixa Amarela.
  static const yellow = Color(0xFFFF9E1B);
  static const yellowDark = Color(0xFFE5A700);
  static const yellowLight = Color(0xFFFFF8E1);
  static const ink = Color(0xFF1B1C1A);
  static const slate = Color(0xFF6B7280);
  static const surfaceSoft = Color(0xFFFAF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const success = Color(0xFF22C55E);
  static const successSurface = Color(0xFFE3F7E9);
  static const danger = Color(0xFFEF4444);
  static const muted = Color(0xFF6B7280);
  static const info = Color(0xFF1D4ED8);
  static const infoSurface = Color(0xFFEAF2FF);
  static const warning = Color(0xFFD97706);
  static const warningSurface = Color(0xFFFFF7E6);

  /// Âmbar escuro para texto/ícones sobre superfícies claras ou tintadas de
  /// warning (warning/yellowDark sobre branco não atingem contraste AA).
  static const warningInk = Color(0xFF92400E);

  /// Vermelho escuro para texto/ícones sobre superfícies claras ou tintadas
  /// de danger (danger puro sobre branco fica abaixo do contraste AA).
  static const dangerInk = Color(0xFFB91C1C);
  static const statusOnTheWay = Color(0xFF1565C0);
  static const statusBoarded = Color(0xFF0A7E52);
  static const mapBackground = Color(0xFF8BA0B0);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3EFE9);
  static const shadowLight = Color(0x1A0F172A);
  static const shadowSubtle = Color(0x14000000);
  static const shadowMedium = Color(0x33000000);
  static const shadowDark = Color(0x55000000);
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
  static const double xl = 24;
  static const double full = 999;
}

abstract final class AppTheme {
  static ThemeData light() {
    const outline = AppColors.border;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.yellow,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.yellow,
          // Conteúdo sobre o amarelo da marca é sempre ink (nunca branco —
          // branco sobre #FF9E1B fica abaixo de 3:1 de contraste).
          onPrimary: AppColors.ink,
          primaryContainer: Color(0xFF895100),
          onPrimaryContainer: AppColors.surface,
          secondary: AppColors.yellowDark,
          onSecondary: AppColors.surface,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          surfaceContainer: AppColors.surfaceSoft,
          surfaceContainerHighest: AppColors.surfaceSoft,
          outline: outline,
          error: AppColors.danger,
        );

    const poppins = TextStyle(fontFamily: 'Poppins');
    const inter = TextStyle(fontFamily: 'Inter');

    final textTheme = ThemeData.light().textTheme.copyWith(
      displayLarge: poppins.copyWith(fontWeight: FontWeight.w700),
      displayMedium: poppins.copyWith(fontWeight: FontWeight.w700),
      displaySmall: poppins.copyWith(fontWeight: FontWeight.w700),
      headlineLarge: poppins.copyWith(fontWeight: FontWeight.w700),
      headlineMedium: poppins.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 28,
      ),
      headlineSmall: poppins.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
      titleLarge: poppins.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 22,
      ),
      titleMedium: poppins.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      titleSmall: poppins.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      bodyLarge: inter.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: inter.copyWith(fontWeight: FontWeight.w400, fontSize: 14),
      bodySmall: inter.copyWith(fontWeight: FontWeight.w400, fontSize: 12),
      labelLarge: inter.copyWith(fontWeight: FontWeight.w500, fontSize: 14),
      labelMedium: inter.copyWith(fontWeight: FontWeight.w500, fontSize: 12),
      labelSmall: inter.copyWith(fontWeight: FontWeight.w500, fontSize: 11),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceSoft,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        centerTitle: false,
        toolbarHeight: 64,
        // Faixa amarela de 4px na borda inferior de toda AppBar do app.
        shape: const Border(
          bottom: BorderSide(color: AppColors.yellow, width: 4),
        ),
        titleTextStyle: poppins.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: 0,
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
        actionsIconTheme: const IconThemeData(color: AppColors.ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        height: 64,
        indicatorColor: AppColors.yellow.withValues(alpha: 0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.yellow, size: 24);
          }
          return const IconThemeData(color: AppColors.muted, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return inter.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.yellow,
            );
          }
          return inter.copyWith(
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
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadowSubtle,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.yellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        labelStyle: inter.copyWith(color: AppColors.slate, fontSize: 14),
        hintStyle: inter.copyWith(color: AppColors.muted, fontSize: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.yellow,
          // Texto ink sobre amarelo (7.9:1); branco tinha contraste 2.2:1.
          foregroundColor: AppColors.ink,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: inter.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // Texto amarelo sobre fundo branco tinha contraste 2.2:1; a borda
          // segue amarela e o texto passa a ser ink (padrão do TextButton).
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.yellow, width: 1.2),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: inter.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: inter.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.yellow,
        // Ícone/texto ink sobre amarelo (branco tinha contraste 2.2:1).
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
            return AppColors.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.surface;
            return AppColors.ink;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.border),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
          textStyle: WidgetStatePropertyAll(
            inter.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: inter.copyWith(
          color: AppColors.surface,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 4,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        side: const BorderSide(color: AppColors.border),
        labelStyle: inter.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: poppins.copyWith(
          color: AppColors.ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: inter.copyWith(
          color: AppColors.slate,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        modalBarrierColor: AppColors.shadowDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
