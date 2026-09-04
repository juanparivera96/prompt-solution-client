import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_repository.dart';
import '../../models/merchant.dart';
import '../../models/payment_recommendation.dart';
import '../../services/recommendation_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/card_option_tile.dart';
import '../../widgets/data_row.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/secure_footer.dart';
import '../confirmation/confirmation_screen.dart';

/// Detailed view: merchant info, total to pay, ranked product list with
/// the recommended option highlighted, and confirm/cancel actions.
class PaymentRecommendationScreen extends StatefulWidget {
  final String qrPayload;
  const PaymentRecommendationScreen({super.key, required this.qrPayload});

  @override
  State<PaymentRecommendationScreen> createState() =>
      _PaymentRecommendationScreenState();
}

class _PaymentRecommendationScreenState
    extends State<PaymentRecommendationScreen> {
  static const _repo = MockRepository();
  static const _service = RecommendationService();

  late final Merchant _merchant;
  late final PaymentRecommendation _recommendation;
  late String _selectedProductId;

  @override
  void initState() {
    super.initState();
    _merchant = _repo.decodeQr(widget.qrPayload);
    _recommendation = _service.rank(
      merchant: _merchant,
      products: _repo.userProducts(),
    );
    _selectedProductId = _recommendation.best.product.id;
  }

  ScoredProduct get _selected =>
      _recommendation.ranked.firstWhere((s) => s.product.id == _selectedProductId);

  void _confirm() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          merchant: _merchant,
          selection: _selected,
          recommendation: _recommendation,
        ),
      ),
    );
  }

  void _cancel() {
    SessionManager.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            eyebrow: 'OPTIMIZADOR DE PAGOS',
            title: 'Banco Inteligente Javeriana',
            trailingIcon: Icons.auto_awesome_rounded,
            showLogo: false,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TransactionCard(merchant: _merchant),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'PRODUCTOS DISPONIBLES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.lightSecondaryText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ReasonBanner(reason: _recommendation.reason),
                  const SizedBox(height: AppSpacing.md),
                  ..._recommendation.ranked.map(
                    (s) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CardOptionTile(
                        product: s.product,
                        rewardLabel: s.rewardLabel,
                        recommended: s.product.id == _recommendation.best.product.id,
                        selected: s.product.id == _selectedProductId,
                        onTap: () => setState(
                            () => _selectedProductId = s.product.id),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _confirm,
                    child: const Text('CONFIRMAR PAGO'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: _cancel,
                    child: const Text('CANCELAR TRANSACCIÓN'),
                  ),
                ],
              ),
            ),
          ),
          const SecureFooter(),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Merchant merchant;
  const _TransactionCard({required this.merchant});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        border: Border.all(color: AppColors.lightOutline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.lightSecondaryBackground,
              border: Border(
                bottom: BorderSide(color: AppColors.lightOutline),
              ),
            ),
            child: Text(
              'DATOS DE LA TRANSACCIÓN',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.lightSecondaryText,
                letterSpacing: 1,
              ),
            ),
          ),
          LabeledDataRow(label: 'COMERCIO', value: merchant.name.toUpperCase()),
          LabeledDataRow(label: 'UBICACIÓN', value: merchant.location.toUpperCase()),
          LabeledDataRow(label: 'ID', value: merchant.id, monospaceValue: true),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            color: AppColors.lightAccent.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL A PAGAR',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.lightPrimaryText,
                  ),
                ),
                Text(
                  Formatters.cop.format(merchant.amount),
                  style: AppTextStyles.monoHeadlineSmall.copyWith(
                    color: AppColors.lightPrimaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonBanner extends StatelessWidget {
  final String reason;
  const _ReasonBanner({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.lightAccent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.lightAccent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_rounded,
              size: 20, color: AppColors.lightAccent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              reason,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightPrimaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
