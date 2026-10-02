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

  /// Returns an Open Sans [TextStyle] using only bold and very bold weights.
  static TextStyle openSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.openSans(
      fontSize: fontSize,
      fontWeight: resolveBoldWeight(fontWeight, fallback: FontWeight.bold),
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
    );
  }
}
