import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight centralized utility for selective, tactile haptic feedback in RADIX.
///
/// Persists user preference under 'haptic_feedback_enabled' (default: true).
/// High-impact touchpoints:
/// 1. FAB (+) button click & rotation trigger
/// 2. Transaction form SAVE button confirmation
/// 3. Hold-to-Reset button initiation and 5s completion
/// 4. Intra-day Compass Sort button mode change
/// 5. Theme / Interval capsule selection change
class HapticHelper {
  static const String prefKey = 'haptic_feedback_enabled';
  static bool? _cachedEnabled;

  /// Loads the enabled state from SharedPreferences (cached for fast access).
  static Future<bool> isEnabled() async {
    if (_cachedEnabled != null) return _cachedEnabled!;
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedEnabled = prefs.getBool(prefKey) ?? true;
    } catch (_) {
      _cachedEnabled = true;
    }
    return _cachedEnabled!;
  }

  /// Sets and persists whether haptic feedback is globally enabled.
  static Future<void> setEnabled(bool enabled) async {
    _cachedEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, enabled);
    } catch (_) {}
  }

  /// Fast synchronous getter with fallback to true.
  static bool get isEnabledSync => _cachedEnabled ?? true;

  /// Tactile light vibration for selection clicks and button initiations.
  static Future<void> lightImpact() async {
    if (await isEnabled()) {
      await HapticFeedback.lightImpact();
    }
  }

  /// Medium vibration for confirmations (e.g. transaction saved).
  static Future<void> mediumImpact() async {
    if (await isEnabled()) {
      await HapticFeedback.mediumImpact();
    }
  }

  /// Selection click for capsule / tab switches.
  static Future<void> selectionClick() async {
    if (await isEnabled()) {
      await HapticFeedback.selectionClick();
    }
  }

  /// Heavy vibration for destructive actions and hold-to-reset completion.
  static Future<void> heavyImpact() async {
    if (await isEnabled()) {
      await HapticFeedback.heavyImpact();
    }
  }
}
