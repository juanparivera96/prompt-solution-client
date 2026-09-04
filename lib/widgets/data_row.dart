import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';

/// Two-column label/value row used in transaction detail cards.
class LabeledDataRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospaceValue;

  const LabeledDataRow({
    super.key,
    required this.label,
    required this.value,
    this.monospaceValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.lightSecondaryText,
              letterSpacing: 1,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: (monospaceValue
                      ? AppTextStyles.labelMedium
                      : AppTextStyles.titleSmall)
                  .copyWith(color: AppColors.lightPrimaryText),
            ),
          ),
        ],
      ),
    );
  }
}
