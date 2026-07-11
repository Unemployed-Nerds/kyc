import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

const kSans = 'InstrumentSans';
const kSerif = 'InstrumentSerif';

/// True when the OS asks for reduced motion; swap movement for fades.
bool reduceMotion(BuildContext context) =>
    MediaQuery.of(context).disableAnimations;

abstract final class AppTheme {
  static const _scheme = ColorScheme.light(
    primary: Palette.primary,
    onPrimary: Colors.white,
    primaryContainer: Palette.primaryTint,
    onPrimaryContainer: Palette.primaryText,
    secondary: Palette.brass,
    onSecondary: Colors.white,
    secondaryContainer: Palette.brassTint,
    onSecondaryContainer: Palette.brassText,
    error: Palette.danger,
    onError: Colors.white,
    errorContainer: Palette.dangerTint,
    onErrorContainer: Palette.dangerText,
    surface: Palette.bg,
    onSurface: Palette.ink,
    surfaceContainerHighest: Palette.surface,
    onSurfaceVariant: Palette.muted,
    outline: Palette.border,
    outlineVariant: Palette.border,
  );

  // Fixed scale, ratio ~1.2. Product UI: no fluid sizes.
  static const _text = TextTheme(
    displaySmall: TextStyle(
      fontFamily: kSerif,
      fontSize: 34,
      height: 1.15,
      color: Palette.ink,
    ),
    headlineMedium: TextStyle(
      fontFamily: kSans,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: -0.3,
      color: Palette.ink,
    ),
    headlineSmall: TextStyle(
      fontFamily: kSans,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: -0.2,
      color: Palette.ink,
    ),
    titleMedium: TextStyle(
      fontFamily: kSans,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: Palette.ink,
    ),
    titleSmall: TextStyle(
      fontFamily: kSans,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
      color: Palette.ink,
    ),
    bodyLarge: TextStyle(
      fontFamily: kSans,
      fontSize: 16,
      height: 1.45,
      color: Palette.ink,
    ),
    bodyMedium: TextStyle(
      fontFamily: kSans,
      fontSize: 15,
      height: 1.45,
      color: Palette.ink,
    ),
    bodySmall: TextStyle(
      fontFamily: kSans,
      fontSize: 13,
      height: 1.4,
      color: Palette.muted,
    ),
    labelLarge: TextStyle(
      fontFamily: kSans,
      fontSize: 15,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: Palette.ink,
    ),
    labelMedium: TextStyle(
      fontFamily: kSans,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Palette.muted,
    ),
    labelSmall: TextStyle(
      fontFamily: kSans,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Palette.muted,
    ),
  );

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _scheme,
      scaffoldBackgroundColor: Palette.bg,
      fontFamily: kSans,
      textTheme: _text,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Palette.bg,
        foregroundColor: Palette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: kSans,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Palette.ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Palette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Palette.border,
          disabledForegroundColor: Palette.muted,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: kSans,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Palette.ink,
          side: const BorderSide(color: Palette.border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: kSans,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Palette.primaryText,
          textStyle: const TextStyle(
            fontFamily: kSans,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Palette.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: Palette.muted),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Palette.danger, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Palette.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Palette.ink,
        contentTextStyle: const TextStyle(
          fontFamily: kSans,
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Palette.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: _text.headlineSmall,
        contentTextStyle: _text.bodyMedium,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Palette.primary,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: Palette.bg,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: Palette.primary,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
