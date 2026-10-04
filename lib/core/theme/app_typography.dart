import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized typography rules for RADIX:
/// - Name of the app ('RADIX'), screen names ('SETTINGS', 'ANALYTICS', etc.),
///   big bold options, and Fulton footer keep their original fonts as before.
/// - All other text in the app changes to Open Sans (using ONLY bold and very bold).
class AppTypography {
  /// Enforces that Open Sans is only bold (w700) to very bold (w800/w900).
  static FontWeight resolveBoldWeight(
    FontWeight? requestedWeight, {
    FontWeight fallback = FontWeight.bold,
  }) {
    if (requestedWeight == null) return fallback;
    if (requestedWeight.value < FontWeight.bold.value) {
      return FontWeight.bold;
    }
    return requestedWeight;
  }

  /// Global size increment for Open Sans text across RADIX
  /// ensuring optimal legibility and balanced visual fit with the bold geometric UI.
  static const double sizeBoost = 2.0;

  /// Returns an Open Sans [TextStyle] using only bold and very bold weights.
  static TextStyle openSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    final double? adjustedSize = fontSize != null
        ? (fontSize + sizeBoost)
        : null;
    return GoogleFonts.openSans(
      fontSize: adjustedSize,
      fontWeight: resolveBoldWeight(fontWeight, fallback: FontWeight.bold),
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}
