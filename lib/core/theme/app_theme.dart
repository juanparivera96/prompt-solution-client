import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Central ThemeData factory. Consumes design tokens defined in
/// [AppColors], [AppTextStyles], [AppSpacing] and [AppRadii].
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _base(_lightScheme);
  static ThemeData dark() => _base(_darkScheme);

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnPrimary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightPrimaryText,
    error: AppColors.lightError,
    onError: AppColors.lightOnPrimary,
    outline: AppColors.lightOutline,
  );

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    secondary: AppColors.darkSecondary,
    onSecondary: AppColors.darkOnPrimary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkPrimaryText,
    error: AppColors.darkError,
    onError: AppColors.darkOnPrimary,
    outline: AppColors.darkOutline,
  );

  static ThemeData _base(ColorScheme scheme) {
    final isLight = scheme.brightness == Brightness.light;
    final background =
        isLight ? AppColors.lightBackground : AppColors.darkBackground;
    final primaryText =
        isLight ? AppColors.lightPrimaryText : AppColors.darkPrimaryText;
    final secondaryText =
        isLight ? AppColors.lightSecondaryText : AppColors.darkSecondaryText;
    final hint = isLight ? AppColors.lightHint : AppColors.darkHint;
    final divider = isLight ? AppColors.lightDivider : AppColors.darkDivider;
    final outline = isLight ? AppColors.lightOutline : AppColors.darkOutline;

    final textTheme = TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: primaryText),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: primaryText),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: primaryText),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primaryText),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primaryText),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primaryText),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: primaryText),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: primaryText),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: primaryText),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primaryText),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primaryText),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondaryText),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primaryText),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondaryText),
      labelSmall: AppTextStyles.labelSmall.copyWith(color: secondaryText),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      dividerColor: divider,
      hintColor: hint,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.lightSurface : AppColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: secondaryText),
        hintStyle: textTheme.bodyMedium?.copyWith(color: hint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          minimumSize: const Size.fromHeight(48),
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 1, space: 1),
    );
  }
}
