import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch-inspired elevation: soft tinted shadow for interactive/floating elements.
class AppShadows {
  static List<BoxShadow> ambientLift = [
    BoxShadow(
      color: const Color(0xFF31332F).withValues(alpha: 0.05),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];
}

class AppColors {
  static const background = Color(0xFFFBF9F5);
  static const surface = Color(0xFFFBF9F5);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF5F4EF);
  static const surfaceContainer = Color(0xFFEFEEE9);
  static const surfaceContainerHigh = Color(0xFFE9E8E3);
  static const surfaceContainerHighest = Color(0xFFE3E3DC);
  static const primary = Color(0xFF466747);
  static const primaryContainer = Color(0xFFC6EDC4);
  static const onPrimary = Color(0xFFE9FFE5);
  static const onPrimaryContainer = Color(0xFF38593A);
  static const secondary = Color(0xFF456373);
  static const secondaryContainer = Color(0xFFC8E7FA);
  static const onSecondaryContainer = Color(0xFF385565);
  static const tertiary = Color(0xFF6C5C4D);
  static const tertiaryContainer = Color(0xFFFDE7D3);
  static const onTertiaryContainer = Color(0xFF635445);
  static const onSurface = Color(0xFF31332F);
  static const onSurfaceVariant = Color(0xFF5E605B);
  static const outline = Color(0xFF7A7B76);
  static const outlineVariant = Color(0xFFB2B2AD);
  static const error = Color(0xFFA73B21);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Color(0xFFF3FAFF),
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: Color(0xFFFFF7F3),
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error: AppColors.error,
      onError: Color(0xFFFFF7F6),
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    ),
    scaffoldBackgroundColor: AppColors.background,
    useMaterial3: true,
  );

  return base.copyWith(
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
      labelMedium: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant),
      labelSmall: GoogleFonts.inter(fontSize: 11, color: AppColors.onSurfaceVariant),
    ),
  );
}
