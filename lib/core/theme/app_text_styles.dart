import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens: Inter for primary/secondary, JetBrains Mono for labels.
class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get displayLarge =>
      GoogleFonts.inter(fontSize: 56, fontWeight: FontWeight.w700, height: 1.1);

  static TextStyle get displayMedium =>
      GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w700, height: 1.1);

  static TextStyle get displaySmall =>
      GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headlineLarge =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headlineMedium =>
      GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get headlineSmall =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);

  static TextStyle get titleLarge =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get titleMedium =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get titleSmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.3);

  static TextStyle get bodyLarge =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle get bodySmall =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle get labelLarge => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get labelMedium => GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get labelSmall => GoogleFonts.jetBrainsMono(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  static TextStyle get monoDisplaySmall => GoogleFonts.jetBrainsMono(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        height: 1.2,
      );

  static TextStyle get monoHeadlineSmall => GoogleFonts.jetBrainsMono(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
      );
}
