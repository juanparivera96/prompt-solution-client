import 'ai_recommendation.dart';
import 'payment_product.dart';

/// Where a ranking comes from: the AI model behind the API, or the local
/// reward rules used as fallback when the model can't answer.
enum RecommendationSource { ai, rules }

/// Result of scoring a single product for a specific transaction.
class ScoredProduct {
  final PaymentProduct product;
  final RewardType rewardType;

  /// Human-readable benefit line ("Gana 3x Puntos", "2% Cashback ($2.904)").
  final String rewardLabel;

  /// Monetary value of the benefit in COP (points estimated at $10 each).
  final double benefitValue;

  /// Probability (0-1) that the user pays with this product's payment method,
  /// as estimated by the AI model. Null when the ranking comes from rules.
  final double? probability;

  /// Why this product can't be used for the purchase ("Saldo insuficiente").
  /// Null when it can.
  final String? unavailableReason;

  const ScoredProduct({
    required this.product,
    required this.rewardType,
    required this.rewardLabel,
    required this.benefitValue,
    this.probability,
    this.unavailableReason,
  });

  bool get isAvailable => unavailableReason == null;
}

/// Ranked list of products for a transaction, with the best one at index 0.
class PaymentRecommendation {
  final List<ScoredProduct> ranked;

  /// Textual reason explaining why the top product wins.
  final String reason;

  /// Delta in COP versus the worst alternative (e.g. debit). When the source
  /// is the AI model, the saving obtained by following the suggestion.
  final double deltaVsBaseline;

  final RecommendationSource source;

  /// False when no product can be suggested (no payment method is feasible).
  final bool hasSuggestion;

  /// Extra line shown next to the source, e.g. why the rules were used.
  final String? notice;

  /// The API answer behind an AI ranking: what the "why" screen explains.
  /// Null when the ranking comes from the rules.
  final AiRecommendation? ai;

  /// True when the rules were used because the AI gave no answer, so asking
  /// again may work.
  final bool canRetryAi;

  const PaymentRecommendation({
    required this.ranked,
    required this.reason,
    required this.deltaVsBaseline,
    this.source = RecommendationSource.rules,
    this.hasSuggestion = true,
    this.notice,
    this.ai,
    this.canRetryAi = false,
  });

  ScoredProduct get best => ranked.first;

  PaymentRecommendation withNotice(String notice, {bool canRetryAi = false}) =>
      PaymentRecommendation(
        ranked: ranked,
        reason: reason,
        deltaVsBaseline: deltaVsBaseline,
        source: source,
        hasSuggestion: hasSuggestion,
        notice: notice,
        ai: ai,
        canRetryAi: canRetryAi,
      );
}
