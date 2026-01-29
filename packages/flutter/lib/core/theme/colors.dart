import 'package:flutter/material.dart';

/// App color palette - Lovable UI Design System
class AppColors {
  AppColors._();

  // ============================================================================
  // Primary Colors
  // ============================================================================

  /// Primary brand color
  static const Color primary = Color(0xFF1890FF);
  static const Color primaryLight = Color(0xFF40A9FF);
  static const Color primaryDark = Color(0xFF096DD9);
  static const Color primaryBackground = Color(0xFFE6F4FF);

  // ============================================================================
  // Secondary Colors
  // ============================================================================

  static const Color secondary = Color(0xFF722ED1);
  static const Color secondaryLight = Color(0xFF9254DE);
  static const Color secondaryDark = Color(0xFF531DAB);

  // ============================================================================
  // Semantic Colors
  // ============================================================================

  /// Success color
  static const Color success = Color(0xFF52C41A);
  static const Color successLight = Color(0xFF73D13D);
  static const Color successBackground = Color(0xFFF6FFED);

  /// Warning color
  static const Color warning = Color(0xFFFAAD14);
  static const Color warningLight = Color(0xFFFFD666);
  static const Color warningBackground = Color(0xFFFFFBE6);

  /// Error color
  static const Color error = Color(0xFFFF4D4F);
  static const Color errorLight = Color(0xFFFF7875);
  static const Color errorBackground = Color(0xFFFFF2F0);

  /// Info color
  static const Color info = Color(0xFF1890FF);
  static const Color infoBackground = Color(0xFFE6F7FF);

  // ============================================================================
  // Alert Severity Colors
  // ============================================================================

  static const Color severityCritical = Color(0xFFFF4D4F);
  static const Color severityHigh = Color(0xFFFA8C16);
  static const Color severityMedium = Color(0xFFFAAD14);
  static const Color severityLow = Color(0xFF1890FF);

  // ============================================================================
  // Neutral Colors - Light Mode
  // ============================================================================

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFFAFAFA);
  static const Color border = Color(0xFFD9D9D9);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color inputBackground = Color(0xFFFAFAFA);
  static const Color chipBackground = Color(0xFFF5F5F5);

  // ============================================================================
  // Neutral Colors - Dark Mode
  // ============================================================================

  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF141414);
  static const Color surfaceSecondaryDark = Color(0xFF1F1F1F);
  static const Color borderDark = Color(0xFF424242);
  static const Color borderLightDark = Color(0xFF303030);
  static const Color dividerDark = Color(0xFF303030);
  static const Color inputBackgroundDark = Color(0xFF1F1F1F);

  // ============================================================================
  // Text Colors - Light Mode
  // ============================================================================

  static const Color textPrimary = Color(0xDE000000); // 87% opacity
  static const Color textSecondary = Color(0xA6000000); // 65% opacity
  static const Color textTertiary = Color(0x73000000); // 45% opacity
  static const Color textQuaternary = Color(0x40000000); // 25% opacity
  static const Color textDisabled = Color(0x40000000);

  // ============================================================================
  // Text Colors - Dark Mode
  // ============================================================================

  static const Color textPrimaryDark = Color(0xD9FFFFFF); // 85% opacity
  static const Color textSecondaryDark = Color(0xA6FFFFFF); // 65% opacity
  static const Color textTertiaryDark = Color(0x73FFFFFF); // 45% opacity
  static const Color textDisabledDark = Color(0x40FFFFFF);

  // ============================================================================
  // Nigerian MNO Colors
  // ============================================================================

  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color gloGreen = Color(0xFF009933);
  static const Color airtelRed = Color(0xFFED1C24);
  static const Color nineMobileGreen = Color(0xFF006838);

  // ============================================================================
  // Currency Colors
  // ============================================================================

  static const Color nairaGreen = Color(0xFF008751);
  static const Color dollarGreen = Color(0xFF85BB65);
  static const Color poundPurple = Color(0xFF4B0082);
  static const Color euroBlue = Color(0xFF003399);

  // ============================================================================
  // Gradient Colors
  // ============================================================================

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, successLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, errorLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get severity color
  static Color getSeverityColor(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return severityCritical;
      case 'HIGH':
        return severityHigh;
      case 'MEDIUM':
        return severityMedium;
      case 'LOW':
        return severityLow;
      default:
        return textSecondary;
    }
  }

  /// Get MNO color
  static Color getMnoColor(String mno) {
    switch (mno.toUpperCase()) {
      case 'MTN':
        return mtnYellow;
      case 'GLO':
        return gloGreen;
      case 'AIRTEL':
        return airtelRed;
      case '9MOBILE':
        return nineMobileGreen;
      default:
        return textSecondary;
    }
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return warning;
      case 'IN_PROGRESS':
      case 'PROCESSING':
        return info;
      case 'COMPLETED':
      case 'SUCCESS':
      case 'VERIFIED':
        return success;
      case 'FAILED':
      case 'ERROR':
      case 'REJECTED':
        return error;
      case 'CANCELLED':
        return textSecondary;
      default:
        return textTertiary;
    }
  }
}
