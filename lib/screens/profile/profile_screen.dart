import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_repository.dart';
import '../../models/merchant.dart';
import '../../models/user_stats.dart';
import '../../services/recommendation_service.dart';
import '../../widgets/card_option_tile.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/secure_footer.dart';

/// User profile: benefits summary and connected financial products.
/// Also exposes a floating QR shortcut to keep the flow one tap away.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _repo = MockRepository();
  static const _service = RecommendationService();

  @override
  Widget build(BuildContext context) {
    final stats = _repo.userStats();
    final products = _repo.userProducts();

    // Use the "restaurant" scenario as default context so the UI can show
    // category-aware reward hints on each card.
    final demoMerchant = _repo.decodeQr(null);
    final ranked = _service.rank(merchant: demoMerchant, products: products);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.qrScanner),
        backgroundColor: AppColors.lightAccent,
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          'ESCANEAR QR',
          style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            eyebrow: 'PAYMENT OPTIMIZER',
            title: 'Banco Inteligente Javeriana',
            trailingIcon: Icons.auto_awesome_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BenefitsCard(stats: stats),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'TUS PRODUCTOS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.lightSecondaryText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...ranked.ranked.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CardOptionTile(
                        product: s.product,
                        rewardLabel: _profileLabel(s.rewardLabel, demoMerchant),
                        recommended:
                            s.product.id == ranked.best.product.id,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                ],
              ),
            ),
          ),
          const SecureFooter(),
        ],
      ),
    );
  }

  String _profileLabel(String base, Merchant m) {
    if (m.category == MerchantCategory.restaurant &&
        base.startsWith('Gana 3x Puntos')) {
      return 'Gana 3x Puntos (Mejor para Restaurantes)';
    }
    return base;
  }
}

class _BenefitsCard extends StatelessWidget {
  final UserStats stats;
  const _BenefitsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.lightAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL BENEFICIOS GANADOS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.lightSecondaryText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.cop.format(stats.totalBenefits),
                    style: AppTextStyles.monoHeadlineSmall.copyWith(
                      color: AppColors.lightPrimaryText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightSuccess,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.white, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '+${stats.growthPercent.toStringAsFixed(0)}%',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatColumn(
                label: 'PUNTOS',
                value: '${Formatters.integer.format(stats.totalPoints)} pts',
                align: CrossAxisAlignment.start,
              ),
              _StatColumn(
                label: 'CASHBACK',
                value: Formatters.cop.format(stats.totalCashback),
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final CrossAxisAlignment align;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.align,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.lightSecondaryText,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.lightPrimaryText,
          ),
        ),
      ],
    );
  }
}
