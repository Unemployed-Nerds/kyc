import 'package:flutter/material.dart';

/// KYCFlow palette. Composed in OKLCH (see DESIGN.md), shipped as sRGB.
/// Mood: "signing papers at a private bank — oxblood leather ledger,
/// crisp white paper, a brass pen."
abstract final class Palette {
  // Brand — oxblood wine, oklch(0.45 0.155 355)
  static const primary = Color(0xFF92225A);
  static const primaryDeep = Color(0xFF62153B);
  static const primaryText = Color(0xFF861A51);
  static const primaryTint = Color(0xFFF9ECF0);

  // Paper
  static const bg = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF8F5F6);
  static const ink = Color(0xFF1E1619);
  static const muted = Color(0xFF65565B);
  static const border = Color(0xFFE1DCDE);

  // Brass accent
  static const brass = Color(0xFFA26F17);
  static const brassText = Color(0xFF8D5E00);
  static const brassTint = Color(0xFFF8EFDE);

  // Status
  static const success = Color(0xFF2C7F44);
  static const successText = Color(0xFF126630);
  static const successTint = Color(0xFFE3F6E6);
  static const warning = Color(0xFFB26E1B);
  static const warningText = Color(0xFF8F5300);
  static const warningTint = Color(0xFFFFF1DA);
  static const danger = Color(0xFFBC2826);
  static const dangerText = Color(0xFFAA1F1F);
  static const dangerTint = Color(0xFFFDEBE9);

  // Dark surfaces (camera / liveness)
  static const inkSurface = Color(0xFF140D10);
  static const inkSurfaceHi = Color(0xFF251C20);
  static const onDarkMuted = Color(0xFFADA1A5);
}
