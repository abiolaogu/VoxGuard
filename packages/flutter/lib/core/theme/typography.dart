import 'package:flutter/material.dart';
import 'colors.dart';

/// App typography - Inter font family
class AppTypography {
  AppTypography._();

  /// Base font family
  static const String fontFamily = 'Inter';

  // ============================================================================
  // Display Styles
  // ============================================================================

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // ============================================================================
  // Headline Styles
  // ============================================================================

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // ============================================================================
  // Title Styles
  // ============================================================================

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // ============================================================================
  // Body Styles
  // ============================================================================

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // ============================================================================
  // Label Styles
  // ============================================================================

  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // ============================================================================
  // Special Styles
  // ============================================================================

  /// Currency display - large
  static const TextStyle currencyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Currency display - medium
  static const TextStyle currencyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.25,
  );

  /// Phone number display
  static const TextStyle phoneNumber = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    height: 1.5,
  );

  /// Code/monospace style
  static const TextStyle code = TextStyle(
    fontFamily: 'monospace',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  // ============================================================================
  // Text Theme
  // ============================================================================

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium: displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall: displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge: headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium: headlineMedium.copyWith(color: AppColors.textPrimary),
        headlineSmall: headlineSmall.copyWith(color: AppColors.textPrimary),
        titleLarge: titleLarge.copyWith(color: AppColors.textPrimary),
        titleMedium: titleMedium.copyWith(color: AppColors.textPrimary),
        titleSmall: titleSmall.copyWith(color: AppColors.textPrimary),
        bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimary),
        bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimary),
        bodySmall: bodySmall.copyWith(color: AppColors.textSecondary),
        labelLarge: labelLarge.copyWith(color: AppColors.textPrimary),
        labelMedium: labelMedium.copyWith(color: AppColors.textSecondary),
        labelSmall: labelSmall.copyWith(color: AppColors.textSecondary),
      );

  static TextTheme get darkTextTheme => TextTheme(
        displayLarge: displayLarge.copyWith(color: AppColors.textPrimaryDark),
        displayMedium: displayMedium.copyWith(color: AppColors.textPrimaryDark),
        displaySmall: displaySmall.copyWith(color: AppColors.textPrimaryDark),
        headlineLarge: headlineLarge.copyWith(color: AppColors.textPrimaryDark),
        headlineMedium: headlineMedium.copyWith(color: AppColors.textPrimaryDark),
        headlineSmall: headlineSmall.copyWith(color: AppColors.textPrimaryDark),
        titleLarge: titleLarge.copyWith(color: AppColors.textPrimaryDark),
        titleMedium: titleMedium.copyWith(color: AppColors.textPrimaryDark),
        titleSmall: titleSmall.copyWith(color: AppColors.textPrimaryDark),
        bodyLarge: bodyLarge.copyWith(color: AppColors.textPrimaryDark),
        bodyMedium: bodyMedium.copyWith(color: AppColors.textPrimaryDark),
        bodySmall: bodySmall.copyWith(color: AppColors.textSecondaryDark),
        labelLarge: labelLarge.copyWith(color: AppColors.textPrimaryDark),
        labelMedium: labelMedium.copyWith(color: AppColors.textSecondaryDark),
        labelSmall: labelSmall.copyWith(color: AppColors.textSecondaryDark),
      );
}
