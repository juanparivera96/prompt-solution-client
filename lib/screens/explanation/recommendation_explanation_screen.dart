import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/ai_recommendation.dart';
import '../../models/capa2_params.dart';
import '../../models/merchant.dart';
import '../../services/api_recommendation_service.dart';
import '../../services/api_status.dart';
import '../../widgets/data_row.dart';
import '../../widgets/gradient_header.dart';
import '../../widgets/secure_footer.dart';

/// "¿Por qué esta sugerencia?": breaks an AI recommendation down into what
/// each layer of the model contributed.
///
/// Every number comes from the API answer ([ai]). The utility formula and
/// its weights come from the API too ([ApiStatus.params]); the sum behind a
/// utility is only shown when it reproduces the utility the API returned.
class RecommendationExplanationScreen extends StatefulWidget {
  final Merchant merchant;
  final AiRecommendation ai;
  final ApiStatus status;

  const RecommendationExplanationScreen({
    super.key,
    required this.merchant,
    required this.ai,
    required this.status,
  });

  @override
  State<RecommendationExplanationScreen> createState() =>
      _RecommendationExplanationScreenState();
}

class _RecommendationExplanationScreenState
    extends State<RecommendationExplanationScreen> {
  @override
  void initState() {
    super.initState();
    // The weights arrive with the API check; ask again if it never succeeded.
    if (widget.status.params == null) widget.status.check();
  }

  @override
  Widget build(BuildContext context) {
    final ai = widget.ai;
    final methods = ai.methodsByUtility;
    final topUtility = ai.utilities.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GradientHeader(
            eyebrow: 'OPTIMIZADOR DE PAGOS',
            title: '¿Por qué esta sugerencia?',
            trailingIcon: Icons.insights_rounded,
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.status,
              builder: (context, _) {
                final params = widget.status.params;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Summary(ai: ai),
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionLabel('COMPARACIÓN DE LOS MEDIOS'),
                      for (final method in methods)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _MethodCard(
                            method: method,
                            ai: ai,
                            params: params,
                            topUtility: topUtility,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      const _SectionLabel('CÓMO DECIDE LA IA'),
                      _Steps(params: params, incentiveMethod: ai.incentiveMethod),
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionLabel('DATOS DE ESTA COMPRA'),
                      _Facts(merchant: widget.merchant, ai: ai),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Perfil y comercio son datos sintéticos de demostración. '
                        'La IA sugiere; tú decides con qué pagar.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.lightSecondaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('VOLVER AL PAGO'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SecureFooter(),
        ],
      ),
    );
  }
}

/// The recommendation in one line, e.g. "Transferencia: probabilidad 19 % +
/// incentivo $14.500 → utilidad 0,58, frente a 0,33 de crédito."
/// Null when the API suggested nothing.
String? explanationHeadline(AiRecommendation ai) {
  final best = ai.recommended;
  if (best == null) return null;
  final probability = ai.propensities[best];
  final utility = ai.utilities[best];
  if (probability == null || utility == null) return null;

  final text = StringBuffer(
    '${_capitalized(best.label)}: probabilidad ${Formatters.percent(probability)}',
  );
  final incentive = ai.incentiveFor(best);
  if (incentive > 0) {
    text.write(' + incentivo ${Formatters.cop.format(incentive)}');
  }
  text.write(' → utilidad ${Formatters.decimal2.format(utility)}');

  final other = ai.runnerUp;
  final otherUtility = ai.utilities[other];
  if (other != null && otherUtility != null) {
    text.write(
      ', frente a ${Formatters.decimal2.format(otherUtility)} de ${other.label}',
    );
  }
  text.write('.');
  return text.toString();
}

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.lightSecondaryText,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({bool highlighted = false}) => BoxDecoration(
      color: AppColors.lightSurface,
      border: Border.all(
        color: highlighted ? AppColors.lightAccent : AppColors.lightOutline,
        width: highlighted ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(4),
    );

/// The API's sentence plus the one-line breakdown.
class _Summary extends StatelessWidget {
  final AiRecommendation ai;
  const _Summary({required this.ai});

  @override
  Widget build(BuildContext context) {
    final headline = explanationHeadline(ai);
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
          Text(
            ai.reason,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.lightPrimaryText,
            ),
          ),
          if (headline != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              headline,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.lightPrimaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One payment method: probability (layer 1), incentive and utility
/// (layer 2), and why it was discarded when it was.
class _MethodCard extends StatelessWidget {
  final PaymentMethod method;
  final AiRecommendation ai;
  final Capa2Params? params;

  /// Highest utility among all methods: the full length of the utility bar.
  final double topUtility;

  const _MethodCard({
    required this.method,
    required this.ai,
    required this.params,
    required this.topUtility,
  });

  /// "0,5 × 0,194 + 0,5 × 0,967 = 0,580". Null when the weights are unknown
  /// or the sum doesn't reproduce the utility the API decided with.
  String? _sum(double probability, double utility, double incentive) {
    final p = params;
    if (p == null) return null;
    if ((p.utility(probability, incentive) - utility).abs() > 0.001) return null;
    final d3 = Formatters.decimal3.format;
    final benefit = incentive > 0 ? d3(p.benefit(incentive)) : '0';
    return '${Formatters.compact.format(p.propensityWeight)} × ${d3(probability)}'
        ' + ${Formatters.compact.format(p.benefitWeight)} × $benefit'
        ' = ${d3(utility)}';
  }

  @override
  Widget build(BuildContext context) {
    final probability = ai.propensities[method] ?? 0;
    final utility = ai.utilities[method] ?? 0;
    final incentive = ai.incentiveFor(method);
    final recommended = method == ai.recommended;
    final excludedLabel =
        ApiRecommendationService.unavailableLabel(ai.excluded[method]);
    final excluded = excludedLabel != null;
    final sum = _sum(probability, utility, incentive);

    return Opacity(
      opacity: excluded ? 0.7 : 1,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: _cardDecoration(highlighted: recommended),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _capitalized(method.label),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.lightPrimaryText,
                    ),
                  ),
                ),
                if (method == ai.habit)
                  const _Badge('MÁS PROBABLE', AppColors.lightSecondaryText),
                if (recommended) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const _Badge('SUGERIDO', AppColors.lightAccent, filled: true),
                ],
                if (excluded) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const _Badge('DESCARTADO', AppColors.lightError),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _Metric(
              label: 'Probabilidad de uso',
              value: Formatters.percent(probability),
              share: probability,
              color: AppColors.lightSecondary,
            ),
            const SizedBox(height: AppSpacing.md),
            _Metric(
              label: 'Incentivo del comercio',
              value: incentive > 0 ? Formatters.cop.format(incentive) : 'No aplica',
            ),
            const SizedBox(height: AppSpacing.md),
            _Metric(
              label: 'Utilidad',
              value: Formatters.decimal2.format(utility),
              share: topUtility > 0 ? utility / topUtility : 0,
              color: AppColors.lightAccent,
              emphasized: true,
            ),
            if (sum != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                sum,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.lightSecondaryText,
                ),
              ),
            ],
            if (excluded) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.block_rounded,
                    size: 14,
                    color: AppColors.lightError,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      utility >= topUtility
                          ? '$excludedLabel. Tenía la mayor utilidad, pero no '
                              'puedes pagar con este medio.'
                          : '$excludedLabel. No entra en la comparación.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.lightError,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool filled;
  const _Badge(this.text, this.color, {this.filled = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: filled ? color : null,
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: filled ? Colors.white : color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// A labelled value, optionally with a bar showing it as a share (0-1).
class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final double? share;
  final Color? color;
  final bool emphasized;

  const _Metric({
    required this.label,
    required this.value,
    this.share,
    this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final share = this.share;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.lightSecondaryText,
              ),
            ),
            Text(
              value,
              style: (emphasized
                      ? AppTextStyles.labelLarge
                      : AppTextStyles.labelMedium)
                  .copyWith(color: AppColors.lightPrimaryText),
            ),
          ],
        ),
        if (share != null) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: share.clamp(0, 1).toDouble(),
              minHeight: 6,
              color: color,
              backgroundColor: AppColors.lightSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// The three steps of the decision, with the formula the API published.
class _Steps extends StatelessWidget {
  final Capa2Params? params;
  final PaymentMethod? incentiveMethod;
  const _Steps({required this.params, required this.incentiveMethod});

  @override
  Widget build(BuildContext context) {
    final p = params;
    final maxUsage = p?.maxCreditUsage;
    final compact = Formatters.compact.format;
    final incentiveScope = incentiveMethod == null
        ? 'El incentivo solo suma en el medio al que aplica.'
        : 'El incentivo solo suma en ${incentiveMethod!.label}.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Step(
            number: '1',
            title: 'Capa 1 · Probabilidad',
            body: 'Un modelo XGBoost estima con qué medio es más probable que '
                'pagues, según tu perfil, el comercio, el monto y el momento '
                'de la compra.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _Step(
            number: '2',
            title: 'Capa 2 · Utilidad',
            formula: p == null
                ? null
                : 'utilidad = ${compact(p.propensityWeight)} × probabilidad'
                    ' + ${compact(p.benefitWeight)} × (incentivo ÷ '
                    '${Formatters.cop.format(p.incentiveReferenceCop)})',
            body: p == null
                ? 'La utilidad combina la probabilidad con el incentivo del '
                    'comercio. $incentiveScope'
                : incentiveScope,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Step(
            number: '3',
            title: 'Factibilidad',
            body: 'Se descartan los medios con los que no puedes pagar: débito '
                'y transferencia si el saldo no cubre la compra, y crédito si '
                '${maxUsage == null ? 'el cupo está casi lleno' : 'el cupo usado llega al ${Formatters.percent(maxUsage)}'}. '
                'Se sugiere el de mayor utilidad entre los que quedan.',
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String number;
  final String title;
  final String body;
  final String? formula;

  const _Step({
    required this.number,
    required this.title,
    required this.body,
    this.formula,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.lightPrimary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.lightPrimaryText,
                ),
              ),
              if (formula != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  formula!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.lightPrimaryText,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                body,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.lightSecondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The inputs the API decided with, for traceability.
class _Facts extends StatelessWidget {
  final Merchant merchant;
  final AiRecommendation ai;
  const _Facts({required this.merchant, required this.ai});

  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  /// "sábado, 11 h · quincena", in Bogotá time. Null when the API didn't say.
  String? get _moment {
    final hour = ai.hour;
    final weekday = ai.weekday;
    if (hour == null || weekday == null || weekday < 0 || weekday > 6) {
      return null;
    }
    final payroll = ai.payrollDay == true ? ' · quincena' : '';
    return '${_weekdays[weekday]}, $hour h$payroll';
  }

  @override
  Widget build(BuildContext context) {
    final balance = ai.balanceCop;
    final moment = _moment;
    final latency = ai.latencyMs;
    final incentiveMethod = ai.incentiveMethod;
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledDataRow(
            label: 'MONTO',
            value: Formatters.cop.format(merchant.amount),
          ),
          if (balance != null)
            LabeledDataRow(
              label: 'SALDO DISPONIBLE',
              value: Formatters.cop.format(balance),
            ),
          LabeledDataRow(
            label: 'INCENTIVO',
            value: ai.incentiveCop > 0 && incentiveMethod != null
                ? '${Formatters.cop.format(ai.incentiveCop)} por ${incentiveMethod.label}'
                : 'Sin incentivo',
          ),
          if (moment != null)
            LabeledDataRow(label: 'MOMENTO (BOGOTÁ)', value: moment),
          if (ai.modelVersion.isNotEmpty)
            LabeledDataRow(
              label: 'MODELO',
              value: ai.modelVersion,
              monospaceValue: true,
            ),
          if (latency != null)
            LabeledDataRow(
              label: 'TIEMPO DE RESPUESTA',
              value: '${latency.round()} ms',
            ),
        ],
      ),
    );
  }
}
