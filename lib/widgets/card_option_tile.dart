import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_text_styles.dart';
import '../models/payment_product.dart';

/// A selectable card / account tile used in the products list.
/// Highlights the recommended option with an accent border + badge.
class CardOptionTile extends StatelessWidget {
  final PaymentProduct product;
  final String rewardLabel;
  final bool recommended;
  final bool selected;
  final VoidCallback? onTap;

  const CardOptionTile({
    super.key,
    required this.product,
    required this.rewardLabel,
    this.recommended = false,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.lightAccent
        : (recommended ? AppColors.lightAccent : AppColors.lightOutline);

    return Material(
      color: AppColors.lightSurface,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: (recommended || selected) ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _iconFor(product.type),
                    color: AppColors.lightPrimary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.lightPrimaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${product.typeLabel} · ${product.maskedNumber}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.lightSecondaryText,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (recommended) const _RecommendedBadge(),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                rewardLabel,
                style: AppTextStyles.bodySmall.copyWith(
                  color: recommended
                      ? AppColors.lightAccent
                      : AppColors.lightSecondaryText,
                  fontWeight: recommended ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(ProductType type) {
    switch (type) {
      case ProductType.creditCard:
        return Icons.credit_card_rounded;
      case ProductType.debitCard:
        return Icons.credit_card;
      case ProductType.currentAccount:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _RecommendedBadge extends StatelessWidget {
  const _RecommendedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.lightAccent,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Colors.white, size: 12),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'MEJOR OPCIÓN',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
