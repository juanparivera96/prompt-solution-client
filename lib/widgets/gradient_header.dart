import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Dark, rounded-bottom header used across the app (Recommendation, Profile).
class GradientHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final IconData? trailingIcon;
  final BorderRadius? borderRadius;
  final bool showLogo;

  const GradientHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.trailingIcon,
    this.borderRadius,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: borderRadius,
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.xl,
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        bottom: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                eyebrow,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
              if (trailingIcon != null)
                Icon(
                  trailingIcon,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (showLogo) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/Logo_Oficial_Blanco.png',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
