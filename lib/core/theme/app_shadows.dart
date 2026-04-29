import 'package:flutter/material.dart';

/// Unified radii and soft shadows — Bukidnon-inspired app surfaces (Shopee-like cards).
abstract final class AppRadii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;

  static BorderRadius circularSm() => BorderRadius.circular(sm);

  static BorderRadius circularMd() => BorderRadius.circular(md);

  static BorderRadius circularLg() => BorderRadius.circular(lg);

  static BorderRadius circularXl() => BorderRadius.circular(xl);
}

abstract final class AppShadows {
  /// Resting card — subtle lift.
  static List<BoxShadow> get card => [
        BoxShadow(
          color: const Color(0xFF171717).withValues(alpha: 0.05),
          blurRadius: 11,
          offset: const Offset(0, 3),
        ),
      ];

  /// Modals / emphasis.
  static List<BoxShadow> get raised => [
        BoxShadow(
          color: const Color(0xFF171717).withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Hairline halo for FAB / nav accents.
  static List<BoxShadow> get softGlow => [
        BoxShadow(
          color: const Color(0xFFB71B1B).withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}
