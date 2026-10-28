import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing the periodic budget reset interval and last reset timestamp.
class ResetIntervalService {
  static const String keyIntervalMonths = 'reset_interval_months';
  static const String keyLastResetTimestamp = 'last_reset_timestamp';

  /// Default interval is 1 month.
  static const int defaultIntervalMonths = 1;

  /// Retrieves the configured reset interval in months (range 1..6).
  static Future<int> getResetIntervalMonths() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getInt(keyIntervalMonths);
      if (val != null && val >= 1 && val <= 6) {
        return val;
      }
      return defaultIntervalMonths;
    } catch (e) {
      debugPrint('[ResetIntervalService] Error reading interval: $e');
      return defaultIntervalMonths;
    }
  }

  /// Immediately persists the reset interval in months (clamped to 1..6).
  static Future<void> setResetIntervalMonths(int months) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clamped = months.clamp(1, 6);
      await prefs.setInt(keyIntervalMonths, clamped);
    } catch (e) {
      debugPrint('[ResetIntervalService] Error saving interval: $e');
    }
  }

  /// Retrieves the last reset timestamp.
  /// If not set, defaults to the first day of the current month.
  static Future<DateTime> getLastResetTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(keyLastResetTimestamp);
      if (raw != null) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) {
          return parsed;
        }
      }

      // Default: 1st day of the current month
      final now = DateTime.now();
      final defaultDate = DateTime(now.year, now.month, 1);
      await prefs.setString(
        keyLastResetTimestamp,
        defaultDate.toIso8601String(),
      );
      return defaultDate;
    } catch (e) {
      debugPrint('[ResetIntervalService] Error reading last reset: $e');
      final now = DateTime.now();
      return DateTime(now.year, now.month, 1);
    }
  }

  /// Updates the last reset timestamp.
  static Future<void> setLastResetTimestamp(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(keyLastResetTimestamp, timestamp.toIso8601String());
    } catch (e) {
      debugPrint('[ResetIntervalService] Error saving last reset: $e');
    }
  }

  /// Calculates elapsed whole months between [now] and [lastReset].
  /// Guarantees non-negative result even if device clock was adjusted.
  static int calculateDeltaMonths(DateTime now, DateTime lastReset) {
    final delta =
        (now.year - lastReset.year) * 12 + (now.month - lastReset.month);
    return delta < 0 ? 0 : delta;
  }

  /// Determines if an automatic reset is due based on elapsed months.
  static bool isResetDue({
    required DateTime now,
    required DateTime lastReset,
    required int intervalMonths,
  }) {
    final delta = calculateDeltaMonths(now, lastReset);
    return delta >= intervalMonths;
  }
}
