import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_repository.dart';
import '../../models/demo_profile.dart';
import '../../models/merchant.dart';
import '../../models/payment_product.dart';
import '../../models/user_stats.dart';
import '../../services/recommendation_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/card_option_tile.dart';
import '../../widgets/data_row.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/secure_footer.dart';

/// Profile of the customer logged in: their money, their products (with
/// the balance or credit available in each) and a benefits summary. Also
/// exposes a floating QR shortcut to keep the flow one tap away.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const _repo = MockRepository();
  static const _service = RecommendationService();

  void _logout(BuildContext context) {
    SessionManager.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = SessionManager.instance.profile;
    if (profile == null) return _NoSession(onLogin: () => _logout(context));

    final stats = _repo.userStats();

    // Use the "restaurant" scenario as default context so the UI can show
    // category-aware reward hints on each card.
    final demoMerchant = _repo.decodeQr(null);
    final ranked =
        _service.rank(merchant: demoMerchant, products: profile.products);

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
            eyebrow: 'MI PERFIL',
            title: 'Banco Inteligente Javeriana',
            trailingIcon: Icons.auto_awesome_rounded,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CustomerCard(profile: profile),
                  const SizedBox(height: AppSpacing.xl),
                  _BenefitsCard(stats: stats),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'TUS PRODUCTOS (${profile.products.length})',
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
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('CERRAR SESIÓN'),
                  ),
                  // Room for the floating button over the last item.
                  const SizedBox(height: AppSpacing.xxxl * 2),
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

/// Who is logged in and the money they have: balance and credit, the same
/// numbers the app sends to the recommendation API.
class _CustomerCard extends StatelessWidget {
  final DemoProfile profile;
  const _CustomerCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final customer = profile.context;
    final cards =
        profile.products.where((p) => p.type == ProductType.creditCard);
    final creditAvailable =
        cards.fold<double>(0, (sum, p) => sum + (p.creditAvailableCop ?? 0));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: Border.all(color: AppColors.lightOutline),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lightAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.lightAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.lightPrimaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Usuario: ${profile.username}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LabeledDataRow(
            label: 'SALDO DISPONIBLE',
            value: Formatters.cop.format(customer.balanceCop),
          ),
          if (customer.hasCredit) ...[
            LabeledDataRow(
              label: 'CUPO DISPONIBLE',
              value: Formatters.cop.format(creditAvailable),
            ),
            LabeledDataRow(
              label: 'CUPO DE CRÉDITO USADO',
              value: Formatters.percent(customer.creditUsage),
            ),
          ] else
            const LabeledDataRow(
              label: 'TARJETA DE CRÉDITO',
              value: 'No tiene',
            ),
          if (profile.trait != null)
            LabeledDataRow(label: 'PERFIL', value: profile.trait!),
        ],
      ),
    );
  }
}

/// Shown if the profile is opened without a session.
class _NoSession extends StatelessWidget {
  final VoidCallback onLogin;
  const _NoSession({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inicia sesión para ver tu perfil.',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.lightPrimaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: onLogin,
                child: const Text('INICIAR SESIÓN'),
              ),
            ],
          ),
        ),
      ),
    );
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
