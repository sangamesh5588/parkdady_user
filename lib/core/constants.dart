import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'Park Daddy';
  static const String appTagline = 'The Parking Boss';
  static const String appVersion = '1.0.0';

  // Animation Durations (Urban Company style - smoother interactions)
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  static const Duration microAnimationDuration = Duration(milliseconds: 150);

  // Form Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 20;
  static const int maxEmailLength = 100;
  static const int maxNameLength = 50;

  // Airbnb-Inspired Spacing (8px grid system with more breathing room)
  static const double spacing4 = 4.0;   // Extra small spacing
  static const double spacing8 = 8.0;   // Small spacing
  static const double spacing12 = 12.0; // Medium-small spacing
  static const double spacing16 = 16.0; // Card padding (increased for Airbnb style)
  static const double spacing20 = 20.0; // Default padding (more generous)
  static const double spacing24 = 24.0; // Section spacing (more whitespace)
  static const double spacing32 = 32.0; // Large section spacing
  static const double spacing40 = 40.0; // Extra large spacing
  static const double spacing48 = 48.0; // Major section spacing
  static const double spacing56 = 56.0; // Screen padding
  static const double spacing64 = 64.0; // Large screen spacing

  // Legacy spacing for backward compatibility
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Component Heights (Airbnb style - larger, more prominent)
  static const double buttonHeight = 56.0;      // Larger buttons (up from 52)
  static const double textFieldHeight = 56.0;   // Consistent height with buttons
  static const double searchBarHeight = 52.0;   // Prominent search bar
  static const double cardHeight = 80.0;        // Standard card height

  // Airbnb-Inspired Border Radius (more rounded, softer)
  static const double radius4 = 4.0;    // Small elements
  static const double radius8 = 8.0;    // Small cards, chips
  static const double radius12 = 12.0;  // Buttons, inputs (primary radius)
  static const double radius16 = 16.0;  // Large cards (Airbnb style)
  static const double radius20 = 20.0;  // Special elements
  static const double radius24 = 24.0;  // Pills, search bars
  static const double radiusFull = 999.0; // Fully rounded pills/badges

  // Legacy border radius for backward compatibility
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;

  // Urban Company Typography Scale
  static const double fontSize10 = 10.0; // Caption small
  static const double fontSize12 = 12.0; // Caption
  static const double fontSize14 = 14.0; // Body small
  static const double fontSize16 = 16.0; // Body
  static const double fontSize18 = 18.0; // Body large
  static const double fontSize20 = 20.0; // Headline small
  static const double fontSize24 = 24.0; // Headline
  static const double fontSize28 = 28.0; // Headline large
  static const double fontSize32 = 32.0; // Display small
  static const double fontSize40 = 40.0; // Display
  static const double fontSize48 = 48.0; // Display large

  // Legacy text styles for backward compatibility
  static const double headingFontSize = 24.0;
  static const double bodyFontSize = 16.0;
  static const double smallFontSize = 14.0;

  // Font Weights (Urban Company style)
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Shadow Elevations (Airbnb style - replaced with BoxShadow in AppColors)
  // Note: Use AppColors.lightShadow, AppColors.mediumShadow, etc. instead
  static const double elevation0 = 0.0;   // No shadow
  static const double elevation1 = 0.0;   // Deprecated - use AppColors.lightShadow
  static const double elevation2 = 0.0;   // Deprecated - use AppColors.mediumShadow
  static const double elevation3 = 0.0;   // Deprecated - use AppColors.heavyShadow
  static const double elevation4 = 0.0;   // Deprecated - use AppColors.heavyShadow

  // Icon Sizes (Airbnb style - consistent sizing)
  static const double iconSizeSmall = 20.0;    // Small icons
  static const double iconSizeMedium = 24.0;   // Default icons
  static const double iconSizeLarge = 28.0;    // Large icons
  static const double iconSizeXLarge = 32.0;   // Extra large icons

  // Card & List Spacing (Airbnb style - more generous)
  static const double cardSpacing = 24.0;      // Space between cards (increased)
  static const double listPadding = 20.0;      // Horizontal list padding (increased)
  static const double sectionSpacing = 32.0;   // Space between sections
}
