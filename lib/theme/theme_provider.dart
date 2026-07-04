import 'package:flutter/material.dart';

/// InheritedNotifier that propagates a [ValueNotifier<ThemeMode>] down the
/// widget tree. Any descendant can read the current theme mode and listen for
/// changes via `ThemeProvider.of(context)`.
class ThemeProvider extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const ThemeProvider({
    super.key,
    required ValueNotifier<ThemeMode> notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Returns the nearest [ThemeProvider]'s notifier in the ancestor chain.
  static ValueNotifier<ThemeMode> of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!.notifier!;
  }

  /// Convenience: read the current [ThemeMode] value.
  static ThemeMode read(BuildContext context) {
    return of(context).value;
  }
}
