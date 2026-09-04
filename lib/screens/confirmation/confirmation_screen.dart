import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/merchant.dart';
import '../../models/payment_product.dart';
import '../../models/payment_recommendation.dart';
import '../../services/session_manager.dart';
import '../../widgets/summary_row.dart';

/// Post-payment summary: shows the amount paid, the winning card and the
/// benefits earned from applying the recommendation.
class ConfirmationScreen extends StatelessWidget {
  final Merchant merchant;
  final ScoredProduct selection;
  final PaymentRecommendation recommendation;

  const ConfirmationScreen({
    super.key,
    required this.merchant,
    required this.selection,
    required this.recommendation,
  });

  String get _authCode {
    final n = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'BJ-${n.toString().padLeft(6, '0')}';
  }

  String get _dateTime {
    final f = DateFormat('MMM d, h:mm a', 'es_CO');
    return f.format(DateTime.now());
  }

  int get _pointsEarned {
    if (selection.rewardType == RewardType.points) {
      return (selection.benefitValue / 0.01 * 0.003).round();
    }
    return 0;
  }

  double get _cashback =>
      selection.rewardType == RewardType.cashback ? selection.benefitValue : 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SuccessHeader(),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AmountCard(merchant: merchant),
                  const SizedBox(height: AppSpacing.lg),
                  _OptimizationCard(
                    recommendation: recommendation,
                    selection: selection,
                    pointsEarned: _pointsEarned,
                    cashback: _cashback,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Detalles del Pago',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.lightPrimaryText,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _DetailsCard(
                    txId: merchant.id,
                    productLabel:
                        '${selection.product.name} ${selection.product.maskedNumber}',
                    authCode: _authCode,
                    dateTime: _dateTime,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Descargar Comprobante'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FilledButton(
                    onPressed: () {
                      SessionManager.instance.logout();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.login,
                        (_) => false,
                      );
                    },
                    child: const Text('Volver al Inicio'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 16, color: AppColors.lightSuccess),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Procesado con seguridad BIJ Encryption',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.lightSecondaryText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.xxl,
        bottom: AppSpacing.xxl,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.lightPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.lightSuccess,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 48),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '¡Pago Exitoso!',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu transacción ha sido optimizada',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final Merchant merchant;
  const _AmountCard({required this.merchant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.lightOutline),
      ),
      child: Column(
        children: [
          Text(
            'VALOR PAGADO',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.lightSecondaryText,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            Formatters.cop.format(merchant.amount),
            style: AppTextStyles.monoDisplaySmall.copyWith(
              color: AppColors.lightPrimaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.store_rounded,
                  color: AppColors.lightPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  merchant.name,
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.lightPrimaryText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OptimizationCard extends StatelessWidget {
  final PaymentRecommendation recommendation;
  final ScoredProduct selection;
  final int pointsEarned;
  final double cashback;

  const _OptimizationCard({
    required this.recommendation,
    required this.selection,
    required this.pointsEarned,
    required this.cashback,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.lightPrimaryContainer,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.lightPrimary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resultado de Optimización',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.lightPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightSuccess,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up,
                        color: Colors.white, size: 12),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '+${Formatters.cop.format(recommendation.deltaVsBaseline)}',
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
          Text(
            recommendation.reason,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BenefitStat(label: 'Puntos Ganados', value: '$pointsEarned pts'),
              ),
              Expanded(
                child: _BenefitStat(
                  label: 'Cashback',
                  value: Formatters.cop.format(cashback),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BenefitStat extends StatelessWidget {
  final String label;
  final String value;
  const _BenefitStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.lightPrimary.withValues(alpha: 0.7),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.lightPrimary,
          ),
        ),
      ],
    );
  }
}

class _DetailsCard extends StatelessWidget {
  final String txId;
  final String productLabel;
  final String authCode;
  final String dateTime;

  const _DetailsCard({
    required this.txId,
    required this.productLabel,
    required this.authCode,
    required this.dateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.lightOutline),
      ),
      child: Column(
        children: [
          SummaryRow(label: 'ID Transacción', value: txId),
          const Divider(height: 1),
          SummaryRow(label: 'Medio de Pago', value: productLabel),
          const Divider(height: 1),
          SummaryRow(label: 'Código Autorización', value: authCode),
          const Divider(height: 1),
          SummaryRow(label: 'Fecha y Hora', value: dateTime),
        ],
      ),
    );
  }
}
