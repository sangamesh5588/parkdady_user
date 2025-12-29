import 'package:flutter/material.dart';

/// Airbnb-Inspired Color Palette
/// Clean, Modern Black & White Theme with Minimal Shadows
class AppColors {
  // ============================================================
  // AIRBNB-STYLE COLOR SYSTEM
  // Pure white backgrounds, black text, subtle grays
  // ============================================================

  // Primary Backgrounds
  static const Color primaryBackground = Color(0xFFFFFFFF);      // Pure white
  static const Color secondaryBackground = Color(0xFFF7F7F7);    // Off-white/Light gray
  static const Color cardBackground = Color(0xFFFFFFFF);         // White cards

  // Text Colors - Black hierarchy
  static const Color textPrimary = Color(0xFF222222);            // Near black (softer than pure black)
  static const Color textSecondary = Color(0xFF717171);          // Medium gray
  static const Color textMuted = Color(0xFFB0B0B0);              // Light gray for hints
  static const Color textDisabled = Color(0xFFDDDDDD);           // Very light gray

  // Borders & Dividers
  static const Color borderLight = Color(0xFFDDDDDD);            // Light borders
  static const Color borderMedium = Color(0xFFB0B0B0);           // Medium borders
  static const Color divider = Color(0xFFEBEBEB);                // Very subtle dividers

  // Primary CTA & Accent - Black for minimal Airbnb style
  static const Color ctaPrimary = Color(0xFF000000);             // Pure black buttons
  static const Color ctaOnPrimary = Color(0xFFFFFFFF);           // White text on black

  // Alternative accent if you want to keep some color
  static const Color accentBlue = Color(0xFF3A86FF);             // Electric blue (optional)
  static const Color accentBlueDark = Color(0xFF1A73E8);         // Darker blue

  // Status Colors - Adjusted for white backgrounds
  static const Color statusSuccess = Color(0xFF008A05);          // Darker green for contrast
  static const Color statusError = Color(0xFFD93025);            // Google red
  static const Color statusWarning = Color(0xFFF9AB00);          // Amber warning
  static const Color statusInfo = Color(0xFF1A73E8);             // Blue info

  // Parking Status Colors
  static const Color parkingAvailable = Color(0xFF008A05);       // Dark green
  static const Color parkingOccupied = Color(0xFFD93025);        // Red
  static const Color parkingWarning = Color(0xFFF9AB00);         // Amber
  static const Color parkingActive = Color(0xFF1A73E8);          // Blue
  static const Color parkingSelected = Color(0xFF000000);        // Black

  // Shadow Colors - Very subtle
  static const Color shadowLight = Color(0x0A000000);            // 4% black opacity
  static const Color shadowMedium = Color(0x14000000);           // 8% black opacity
  static const Color shadowHeavy = Color(0x1F000000);            // 12% black opacity

  // ============================================================
  // MATERIAL 3 COLOR SCHEME
  // ============================================================

  static ColorScheme generateColorScheme() {
    return const ColorScheme.light(
      // Always light mode - no dark mode
      brightness: Brightness.light,

      // Primary - Black for buttons and key UI elements
      primary: Color(0xFF000000),                               // Black
      onPrimary: Color(0xFFFFFFFF),                             // White text on black
      primaryContainer: Color(0xFFF7F7F7),                      // Light gray container
      onPrimaryContainer: Color(0xFF222222),                    // Near black text

      // Secondary - Keep simple
      secondary: Color(0xFF717171),                             // Medium gray
      onSecondary: Color(0xFFFFFFFF),                           // White
      secondaryContainer: Color(0xFFEBEBEB),                    // Very light gray
      onSecondaryContainer: Color(0xFF222222),                  // Near black

      // Tertiary - Success green
      tertiary: Color(0xFF008A05),                              // Dark green
      onTertiary: Color(0xFFFFFFFF),                            // White
      tertiaryContainer: Color(0xFFE8F5E8),                     // Light green container
      onTertiaryContainer: Color(0xFF006400),                   // Darker green

      // Error - Red
      error: Color(0xFFD93025),                                 // Google red
      onError: Color(0xFFFFFFFF),                               // White
      errorContainer: Color(0xFFFFEBEE),                        // Light red
      onErrorContainer: Color(0xFFB71C1C),                      // Dark red

      // Surface & Background - Pure white
      surface: Color(0xFFFFFFFF),                               // White surface
      onSurface: Color(0xFF222222),                             // Near black text
      surfaceVariant: Color(0xFFF7F7F7),                        // Off-white variant
      onSurfaceVariant: Color(0xFF717171),                      // Medium gray

      // Outline & Borders
      outline: Color(0xFFDDDDDD),                               // Light border
      outlineVariant: Color(0xFFEBEBEB),                        // Very light border

      // Shadow
      shadow: Color(0x14000000),                                // 8% black shadow

      // Inverse - For dark elements on light backgrounds
      inverseSurface: Color(0xFF000000),                        // Black
      onInverseSurface: Color(0xFFFFFFFF),                      // White
      inversePrimary: Color(0xFFFFFFFF),                        // White

      // Surface containers - Layers of white/gray
      surfaceContainerLowest: Color(0xFFFFFFFF),                // Pure white
      surfaceContainerLow: Color(0xFFFAFAFA),                   // Almost white
      surfaceContainer: Color(0xFFF7F7F7),                      // Off-white
      surfaceContainerHigh: Color(0xFFF0F0F0),                  // Light gray
      surfaceContainerHighest: Color(0xFFEBEBEB),               // Lighter gray
    );
  }

  // ============================================================
  // SHADOW PRESETS - Airbnb Style
  // ============================================================

  static const BoxShadow lightShadow = BoxShadow(
    color: Color(0x0A000000),                                   // 4% opacity
    blurRadius: 8,
    offset: Offset(0, 1),
    spreadRadius: 0,
  );

  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x14000000),                                   // 8% opacity
    blurRadius: 12,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  static const BoxShadow heavyShadow = BoxShadow(
    color: Color(0x1F000000),                                   // 12% opacity
    blurRadius: 16,
    offset: Offset(0, 4),
    spreadRadius: 0,
  );

  static const BoxShadow cardShadow = BoxShadow(
    color: Color(0x0A000000),                                   // Very subtle
    blurRadius: 8,
    offset: Offset(0, 2),
    spreadRadius: 0,
  );

  // ============================================================
  // HELPER METHODS - Theme-aware colors
  // ============================================================

  /// Get primary text color
  static Color getPrimaryText(BuildContext context) {
    return textPrimary;  // Always near black
  }

  /// Get secondary text color
  static Color getSecondaryText(BuildContext context) {
    return textSecondary;  // Always medium gray
  }

  /// Get muted text color
  static Color getTextMuted(BuildContext context) {
    return textMuted;  // Always light gray
  }

  /// Get surface/background color
  static Color getSurfaceColor(BuildContext context) {
    return primaryBackground;  // Always white
  }

  /// Get card background color
  static Color getCardBackground(BuildContext context) {
    return cardBackground;  // Always white
  }

  /// Get secondary background (for contrast areas)
  static Color getSecondaryBackground(BuildContext context) {
    return secondaryBackground;  // Always off-white
  }

  /// Get button primary color
  static Color getButtonPrimary(BuildContext context) {
    return ctaPrimary;  // Always black
  }

  /// Get button primary text color
  static Color getButtonPrimaryText(BuildContext context) {
    return ctaOnPrimary;  // Always white
  }

  /// Get input background color
  static Color getInputBackground(BuildContext context) {
    return secondaryBackground;  // Light gray background
  }

  /// Get input text color
  static Color getInputText(BuildContext context) {
    return textPrimary;  // Near black
  }

  /// Get input border color
  static Color getInputBorder(BuildContext context) {
    return borderLight;  // Light border
  }

  /// Get divider color
  static Color getDividerColor(BuildContext context) {
    return divider;  // Very light gray
  }

  // ============================================================
  // PARKING STATUS COLORS
  // ============================================================

  static Color getParkingAvailableColor() => parkingAvailable;
  static Color getParkingOccupiedColor() => parkingOccupied;
  static Color getParkingWarningColor() => parkingWarning;
  static Color getParkingActiveColor() => parkingActive;
  static Color getParkingSelectedColor() => parkingSelected;

  // Backward compatibility aliases
  static Color getAppBackground(BuildContext context) => primaryBackground;
  static Color getCardBackgroundMatte(BuildContext context) => cardBackground;
  static Color getModalBackground(BuildContext context) => primaryBackground;
  static Color getTextPrimary(BuildContext context) => textPrimary;
  static Color getTextSecondary(BuildContext context) => textSecondary;
  static Color getTextDisabled(BuildContext context) => textDisabled;
}
