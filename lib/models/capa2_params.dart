/// Parameters of the layer-2 utility function, as published by the API in
/// `GET /v1/meta`:
///
///     utility = propensityWeight · probability
///             + benefitWeight · incentive / incentiveReferenceCop
///
/// The app only uses them to explain a recommendation; the decision itself
/// always comes from the API.
class Capa2Params {
  final double propensityWeight;
  final double benefitWeight;

  /// Incentive (COP) that counts as a benefit of 1.
  final double incentiveReferenceCop;

  /// Credit is discarded from this share of the credit limit in use (0-1).
  final double? maxCreditUsage;

  const Capa2Params({
    required this.propensityWeight,
    required this.benefitWeight,
    required this.incentiveReferenceCop,
    this.maxCreditUsage,
  });

  /// Null when the answer doesn't carry the parameters this app knows.
  static Capa2Params? fromMeta(Map<String, dynamic> meta) {
    final raw = meta['capa2'];
    if (raw is! Map) return null;
    final w1 = raw['w_propension'];
    final w2 = raw['w_beneficio'];
    final reference = raw['ref_incentivo_cop'];
    if (w1 is! num || w2 is! num || reference is! num || reference <= 0) {
      return null;
    }
    final maxUsage = raw['uso_cupo_max'];
    return Capa2Params(
      propensityWeight: w1.toDouble(),
      benefitWeight: w2.toDouble(),
      incentiveReferenceCop: reference.toDouble(),
      maxCreditUsage: maxUsage is num ? maxUsage.toDouble() : null,
    );
  }

  /// The incentive on the 0-1 scale the utility function works with.
  double benefit(double incentiveCop) => incentiveCop / incentiveReferenceCop;

  double utility(double probability, double incentiveCop) =>
      propensityWeight * probability + benefitWeight * benefit(incentiveCop);
}
