import 'package:flutter/material.dart';

/// Applies comfortable phone-first touch targets across the app.
///
/// Interactive controls should remain easy to hit with gloves off, one-handed,
/// or while moving between training activities. Custom cards can still be
/// larger, but standard buttons and icon buttons should never feel tiny.
ThemeData phoneFriendlyTheme(ThemeData base) {
  final filled = base.filledButtonTheme.style ?? const ButtonStyle();
  final outlined = base.outlinedButtonTheme.style ?? const ButtonStyle();
  final text = base.textButtonTheme.style ?? const ButtonStyle();
  final icon = base.iconButtonTheme.style ?? const ButtonStyle();

  return base.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(
      style: filled.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: outlined.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(48, 52)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: text.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: icon.copyWith(
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    ),
  );
}
