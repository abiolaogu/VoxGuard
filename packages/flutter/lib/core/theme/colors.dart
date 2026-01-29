import 'package:flutter/material.dart';

/// Extended color palette with Nigerian context and dark mode support
class AppColors {
  AppColors._();

  // ============================================================================
  // Primary Brand Colors
  // ============================================================================
  static const Color primary = Color(0xFF1890FF);
  static const Color primaryLight = Color(0xFF40A9FF);
  static const Color primaryDark = Color(0xFF096DD9);
  static const Color primaryBackground = Color(0xFFE6F7FF);

  static const Gradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1890FF), Color(0xFF722ED1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================================================
  // Secondary Colors
  // ============================================================================
  static const Color secondary = Color(0xFF722ED1);
  static const Color secondaryLight = Color(0xFF9254DE);
  static const Color secondaryDark = Color(0xFF531DAB);
  static const Color secondaryBackground = Color(0xFFF9F0FF);

  // ============================================================================
  // Nigerian Theme Colors 🇳🇬
  // ============================================================================
  static const Color nigeriaGreen = Color(0xFF008751);
  static const Color nigeriaWhite = Color(0xFFFFFFFF);
  static const Color nairaGreen = Color(0xFF008751);

  // Nigerian flag gradient
  static const Gradient nigeriaGradient = LinearGradient(
    colors: [Color(0xFF008751), Color(0xFF008751), Color(0xFFFFFFFF)],
    stops: [0.0, 0.33, 0.67],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Geopolitical zone colors
  static const Color southWest = Color(0xFF8B4513);
  static const Color southEast = Color(0xFF228B22);
  static const Color southSouth = Color(0xFF4169E1);
  static const Color northWest = Color(0xFFDAA520);
  static const Color northEast = Color(0xFFDC143C);
  static const Color northCentral = Color(0xFF9932CC);

  // MNO Colors
  static const Color mtnYellow = Color(0xFFFFCC00);
  static const Color gloGreen = Color(0xFF50B848);
  static const Color airtelRed = Color(0xFFED1C24);
  static const Color nineMobileGreen = Color(0xFF006837);

  /// Get MNO color
  static Color getMnoColor(String mno) {
    switch (mno.toLowerCase()) {
      case 'mtn':
        return mtnYellow;
      case 'glo':
        return gloGreen;
      case 'airtel':
        return airtelRed;
      case '9mobile':
        return nineMobileGreen;
      default:
        return textSecondary;
    }
  }

  // ============================================================================
  // Semantic Colors
  // ============================================================================
  static const Color success = Color(0xFF52C41A);
  static const Color successLight = Color(0xFF73D13D);
  static const Color successBackground = Color(0xFFF6FFED);

  static const Color warning = Color(0xFFFAAD14);
  static const Color warningLight = Color(0xFFFFC53D);
  static const Color warningBackground = Color(0xFFFFFBE6);

  static const Color error = Color(0xFFFF4D4F);
  static const Color errorLight = Color(0xFFFF7875);
  static const Color errorBackground = Color(0xFFFFF2F0);

  static const Color info = Color(0xFF1890FF);
  static const Color infoLight = Color(0xFF40A9FF);
  static const Color infoBackground = Color(0xFFE6F7FF);

  // Call masking alert color (special emphasis)
  static const Color maskingAlert = Color(0xFFE53935);

  // ============================================================================
  // Neutral Colors - Light Mode
  // ============================================================================
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);

  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  static const Color inputBackground = Color(0xFFF9FAFB);
  static const Color chipBackground = Color(0xFFF3F4F6);

  // ============================================================================
  // Neutral Colors - Dark Mode
  // ============================================================================
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textTertiaryDark = Color(0xFF9CA3AF);
  static const Color textDisabledDark = Color(0xFF6B7280);

  static const Color backgroundDark = Color(0xFF111827);
  static const Color surfaceDark = Color(0xFF1F2937);
  static const Color surfaceSecondaryDark = Color(0xFF374151);
  static const Color borderDark = Color(0xFF374151);
  static const Color dividerDark = Color(0xFF374151);

  static const Color inputBackgroundDark = Color(0xFF374151);
  static const Color chipBackgroundDark = Color(0xFF374151);

  // ============================================================================
  // Overlay Colors
  // ============================================================================
  static const Color overlayLight = Color(0x0F000000);
  static const Color overlayMedium = Color(0x29000000);
  static const Color overlayDark = Color(0x52000000);

  static const Color scrimLight = Color(0x80FFFFFF);
  static const Color scrimDark = Color(0x80000000);

  // ============================================================================
  // Gradient Presets
  // ============================================================================
  static const Gradient successGradient = LinearGradient(
    colors: [Color(0xFF52C41A), Color(0xFF73D13D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient warningGradient = LinearGradient(
    colors: [Color(0xFFFAAD14), Color(0xFFFFC53D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient errorGradient = LinearGradient(
    colors: [Color(0xFFFF4D4F), Color(0xFFFF7875)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkGradient = LinearGradient(
    colors: [Color(0xFF1F2937), Color(0xFF374151)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ============================================================================
  // Helper Methods
  // ============================================================================

  /// Get color with opacity for backgrounds
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  /// Get contrasting text color for any background
  static Color getContrastColor(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? textPrimary : Colors.white;
  }

  /// Get severity color
  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return error;
      case 'high':
        return Color(0xFFE53935);
      case 'medium':
        return warning;
      case 'low':
        return info;
      default:
        return textSecondary;
    }
  }

  /// Get status color
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'verified':
      case 'active':
        return success;
      case 'pending':
      case 'processing':
        return warning;
      case 'failed':
      case 'masked':
      case 'cancelled':
        return error;
      default:
        return textSecondary;
    }
  }

  /// Get risk level color
  static Color getRiskColor(double confidence) {
    if (confidence >= 0.9) return error;
    if (confidence >= 0.7) return Color(0xFFE53935);
    if (confidence >= 0.5) return warning;
    return success;
  }
}
