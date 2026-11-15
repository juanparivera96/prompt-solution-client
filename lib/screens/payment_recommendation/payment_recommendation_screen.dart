import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_repository.dart';
import '../../models/ai_recommendation.dart';
import '../../models/demo_profile.dart';
import '../../models/merchant.dart';
import '../../models/payment_recommendation.dart';
import '../../services/api_recommendation_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/ai_status_banner.dart';
import '../../widgets/card_option_tile.dart';
import '../../widgets/data_row.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/secure_footer.dart';
import '../confirmation/confirmation_screen.dart';
import '../explanation/recommendation_explanation_screen.dart';

/// Detailed view: merchant info, total to pay, ranked product list with
/// the recommended option highlighted, and confirm/cancel actions.
///
/// The ranking is requested from the recommendation API when the screen
/// opens. If the API is asleep the screen says so while it wakes up, and the
/// user can pay with the local rules instead of waiting.
class PaymentRecommendationScreen extends StatefulWidget {
  final String qrPayload;

  /// Injected in tests. By default the screen creates (and closes) its own.
  final ApiRecommendationService? service;

  const PaymentRecommendationScreen({
    super.key,
    required this.qrPayload,
    this.service,
  });

  @override
  State<PaymentRecommendationScreen> createState() =>
      _PaymentRecommendationScreenState();
}

class _PaymentRecommendationScreenState
    extends State<PaymentRecommendationScreen> {
  static const _repo = MockRepository();

  late final Merchant _merchant;
  late final DemoProfile _profile;
  late final ApiRecommendationService _service;

  /// Null while the recommendation is being requested.
  PaymentRecommendation? _recommendation;

  /// Null while loading, or when no product can pay this purchase.
  String? _selectedProductId;

  /// True while waiting for a sleeping API to wake up.
  bool _waking = false;

  /// When the request in progress started.
  DateTime _requestedAt = DateTime.now();

  /// Number of the latest request; the answer of an older one is dropped.
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _merchant = _repo.decodeQr(widget.qrPayload);
    _profile = _repo.profileById(SessionManager.instance.demoProfileId);
    _service = widget.service ?? ApiRecommendationService();
    _load();
  }

  @override
  void dispose() {
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    _requestedAt = DateTime.now();
    final recommendation = await _service.recommend(
      merchant: _merchant,
      products: _profile.products,
      profileId: _profile.id,
      onWaking: () {
        if (mounted && request == _request) setState(() => _waking = true);
      },
    );
    if (!mounted || request != _request) return;
    _show(recommendation);
  }

  void _show(PaymentRecommendation recommendation) {
    setState(() {
      _waking = false;
      _recommendation = recommendation;
      _selectedProductId =
          recommendation.hasSuggestion ? recommendation.best.product.id : null;
    });
  }

  /// The user chose not to wait for the API to wake up.
  void _useRulesNow() {
    _request++; // The answer of the request in progress will be dropped.
    _show(
      _service.rules
          .rank(merchant: _merchant, products: _profile.products)
          .withNotice(
            'No esperaste a que la IA despertara. '
            'Se usaron las reglas de beneficios.',
            canRetryAi: true,
          ),
    );
  }

  void _retryWithAi() {
    setState(() {
      _recommendation = null;
      _selectedProductId = null;
      _waking = false;
    });
    _load();
  }

  void _explain(PaymentRecommendation recommendation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecommendationExplanationScreen(
          merchant: _merchant,
          ai: recommendation.ai!,
          status: _service.status,
        ),
      ),
    );
  }

  void _confirm(PaymentRecommendation recommendation) {
    final selection = recommendation.ranked
        .firstWhere((s) => s.product.id == _selectedProductId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          merchant: _merchant,
          selection: selection,
          recommendation: recommendation,
        ),
      ),
    );
  }

  void _cancel() {
    SessionManager.instance.logout();
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  /// "Probabilidad de pagar con débito: 49 %". Only for AI rankings.
  String? _probabilityLabel(ScoredProduct s) {
    final probability = s.probability;
    if (probability == null) return null;
    final method = PaymentMethod.ofProduct(s.product.type).label;
    final percent = (probability * 100).round();
    return 'Probabilidad de pagar con $method: $percent %';
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = _recommendation;
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
                  _TransactionCard(merchant: _merchant, profile: _profile),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'PRODUCTOS DISPONIBLES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.lightSecondaryText,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (recommendation == null && _waking)
                    _WakingBanner(since: _requestedAt, onSkip: _useRulesNow)
                  else if (recommendation == null)
                    const _LoadingBanner()
                  else ...[
                    _SourceLabel(
                      recommendation: recommendation,
                      onRetry: recommendation.canRetryAi ? _retryWithAi : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ReasonBanner(reason: recommendation.reason),
                    if (recommendation.ai != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _explain(recommendation),
                          icon: const Icon(Icons.insights_rounded, size: 18),
                          label: const Text('¿POR QUÉ ESTA SUGERENCIA?'),
                        ),
                      )
                    else
                      const SizedBox(height: AppSpacing.md),
                    ...recommendation.ranked.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: CardOptionTile(
                          product: s.product,
                          rewardLabel: s.rewardLabel,
                          detail: _probabilityLabel(s),
                          unavailableReason: s.unavailableReason,
                          recommended: recommendation.hasSuggestion &&
                              s.product.id == recommendation.best.product.id,
                          selected: s.product.id == _selectedProductId,
                          onTap: () => setState(
                              () => _selectedProductId = s.product.id),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed:
                        recommendation == null || _selectedProductId == null
                            ? null
                            : () => _confirm(recommendation),
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
  final DemoProfile profile;
  const _TransactionCard({required this.merchant, required this.profile});

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
          LabeledDataRow(label: 'PERFIL DEMO', value: profile.name.toUpperCase()),
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

/// Shown while the recommendation API is being queried.
class _LoadingBanner extends StatelessWidget {
  const _LoadingBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.lg),
          Text(
            'Consultando el modelo de IA…',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown while a sleeping API wakes up: says what is going on, how long it
/// has taken, and lets the user pay with the rules instead of waiting.
class _WakingBanner extends StatelessWidget {
  final DateTime since;
  final VoidCallback onSkip;
  const _WakingBanner({required this.since, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.lightAccent.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.lightAccent.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: ElapsedBuilder(
                  since: since,
                  builder: (_, seconds) => Text(
                    'Despertando la IA… $seconds s',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.lightPrimaryText,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'El servidor gratuito del modelo se apaga cuando no se usa y puede '
            'tardar hasta un minuto en volver. Cuando responda verás la '
            'recomendación de la IA.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onSkip,
              child: const Text('NO ESPERAR: USAR REGLAS'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tells the user whether the ranking comes from the AI model or from the
/// local rules, and why when it is the fallback.
class _SourceLabel extends StatelessWidget {
  final PaymentRecommendation recommendation;

  /// Asks the AI again. Null when asking again wouldn't change the answer.
  final VoidCallback? onRetry;

  const _SourceLabel({required this.recommendation, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final fromAi = recommendation.source == RecommendationSource.ai;
    final color = fromAi ? AppColors.lightAccent : AppColors.lightWarning;
    final notice = recommendation.notice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              fromAi ? Icons.auto_awesome_rounded : Icons.rule_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              fromAi ? 'RECOMENDADO POR IA' : 'RECOMENDACIÓN POR REGLAS',
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        if (notice != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            notice,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.lightSecondaryText,
            ),
          ),
        ],
        if (onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('REINTENTAR CON IA'),
          ),
      ],
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
