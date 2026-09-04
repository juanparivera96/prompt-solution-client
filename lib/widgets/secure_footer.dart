import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// "Canal encriptado" strip that appears at the bottom of most screens.
class SecureFooter extends StatelessWidget {
  final String label;

  const SecureFooter({super.key, this.label = 'CANAL ENCRIPTADO · BIJ-SECURE-V3'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.lightSecondaryBackground,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 14, color: AppColors.lightSuccess),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.lightSecondaryText,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
