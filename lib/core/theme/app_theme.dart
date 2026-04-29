import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_shadows.dart';
import 'editorial_colors.dart';

class AppTheme {
  static ThemeData light() {
    const surface = Color(0xFFFFFFFF);
    final colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: EditorialColors.tribalRed,
      onPrimary: Colors.white,
      secondary: EditorialColors.tribalGold,
      onSecondary: EditorialColors.charcoal,
      tertiary: EditorialColors.tribalMaroon,
      error: const Color(0xFFB91C1C),
      onError: Colors.white,
      surface: surface,
      onSurface: EditorialColors.charcoal,
    );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: EditorialColors.charcoal,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: EditorialColors.charcoal,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: EditorialColors.charcoal,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: EditorialColors.charcoal,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: EditorialColors.charcoal,
      ),
      bodyMedium:
          GoogleFonts.inter(fontSize: 14, color: EditorialColors.charcoal),
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: AppRadii.circularLg(),
      side: BorderSide(
        color: EditorialColors.border.withValues(alpha: 0.82),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: EditorialColors.pageCream,
      splashFactory: InkRipple.splashFactory,
      splashColor: EditorialColors.tribalRed.withValues(alpha: 0.09),
      highlightColor: EditorialColors.tribalGold.withValues(alpha: 0.06),
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: EditorialColors.surfaceCream,
        foregroundColor: EditorialColors.charcoal,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: AppRadii.circularLg(),
          borderSide: const BorderSide(color: EditorialColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.circularLg(),
          borderSide: const BorderSide(color: EditorialColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.circularLg(),
          borderSide:
              const BorderSide(color: EditorialColors.tribalRed, width: 1.35),
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        shape: cardShape,
        color: surface,
        elevation: 0,
        shadowColor: const Color(0xFF171717).withValues(alpha: 0.07),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: AppRadii.circularLg()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: AppRadii.circularLg()),
          side: const BorderSide(color: EditorialColors.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        elevation: 0,
        shadowColor: const Color(0xFF171717).withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.circularXl(),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        elevation: 0,
        shadowColor: const Color(0xFF171717).withValues(alpha: 0.1),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),
    );
  }
}
