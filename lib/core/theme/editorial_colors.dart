import 'package:flutter/material.dart';

/// Warm editorial palette: cream surfaces, deep crimson, antique gold, charcoal type.
abstract final class EditorialColors {
  static const pageCream = Color(0xFFFFFBF5);
  static const surfaceCream = Color(0xFFFFF6ED);
  static const parchment = Color(0xFFFFF9F2);
  static const blush = Color(0xFFFDF2E9);
  static const parchmentDeep = Color(0xFFF3ECE3);

  static const crimson = Color(0xFFA51C1C);
  static const crimsonDeep = Color(0xFF7A1515);

  static const gold = Color(0xFFC9A227);
  static const goldSoft = Color(0xFFD4AF37);
  static const amberHighlight = Color(0xFFE3BC2D);

  static const charcoal = Color(0xFF2C2C2C);
  static const ink = Color(0xFF1A1A1A);
  static const muted = Color(0xFF6B7280);
  static const border = Color(0xFFE8DFD4);

  // —— Bukidnon / tribal-inspired brand tokens (see app-wide UI plan)
  /// Deep earthy red.
  static const tribalRed = Color(0xFFB71B1B);
  /// Golden yellow accent.
  static const tribalGold = Color(0xFFE5BF20);
  /// Warm cream surfaces.
  static const tribalCream = Color(0xFFFFF1E3);
  /// Gradient stop darker than tribal red.
  static const tribalMaroon = Color(0xFF5C1414);
}

/// Ready-made gradients for headers and soft page depth.
abstract final class BukidnonGradients {
  static LinearGradient get profileHero => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          EditorialColors.tribalRed,
          EditorialColors.tribalMaroon,
          Color(0xFFE85C4A),
        ],
      );

  static LinearGradient get cardWarm => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          EditorialColors.tribalCream.withValues(alpha: 0.55),
        ],
      );

  static LinearGradient get pageAmbient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          EditorialColors.tribalCream.withValues(alpha: 0.35),
          Colors.white,
        ],
      );
}
