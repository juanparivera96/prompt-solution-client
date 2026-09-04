import 'payment_product.dart';

/// Result of scoring a single product for a specific transaction.
class ScoredProduct {
  final PaymentProduct product;
  final RewardType rewardType;

  /// Human-readable benefit line ("Gana 3x Puntos", "2% Cashback ($2.904)").
  final String rewardLabel;

  /// Monetary value of the benefit in COP (points estimated at $10 each).
  final double benefitValue;

  const ScoredProduct({
    required this.product,
    required this.rewardType,
    required this.rewardLabel,
    required this.benefitValue,
  });
}

/// Ranked list of products for a transaction, with the best one at index 0.
class PaymentRecommendation {
  final List<ScoredProduct> ranked;

  /// Textual reason explaining why the top product wins.
  final String reason;

  /// Delta in COP versus the worst alternative (e.g. debit).
  final double deltaVsBaseline;

  const PaymentRecommendation({
    required this.ranked,
    required this.reason,
    required this.deltaVsBaseline,
  });

  ScoredProduct get best => ranked.first;
}
