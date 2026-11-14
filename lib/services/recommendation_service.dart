import 'package:intl/intl.dart';

import '../core/formatters.dart';
import '../models/merchant.dart';
import '../models/payment_product.dart';
import '../models/payment_recommendation.dart';

/// Scores each product by monetary benefit and returns a ranked list.
///
/// Scoring model (MVP):
///  - points: rate * amount * 0.01  (~ 1 point ≈ $10 COP → 1% of spend per multiplier)
///  - miles:  rate * amount * 0.015 (~ 1 mile  ≈ $15 COP)
///  - cashback: rate * amount
///  - none: 0
///
/// The result includes a human reason for the top choice and the delta
/// versus the worst alternative (usually a debit account).
class RecommendationService {
  static const double _pointValue = 0.01;
  static const double _mileValue = 0.015;

  static final NumberFormat _cop = Formatters.cop;

  const RecommendationService();

  PaymentRecommendation rank({
    required Merchant merchant,
    required List<PaymentProduct> products,
  }) {
    final scored = products
        .map((p) => _score(p, merchant))
        .toList()
      ..sort((a, b) => b.benefitValue.compareTo(a.benefitValue));

    final best = scored.first;
    final worst = scored.last;
    final delta = best.benefitValue - worst.benefitValue;

    return PaymentRecommendation(
      ranked: scored,
      reason: _reasonFor(best, merchant, delta),
      deltaVsBaseline: delta,
    );
  }

  ScoredProduct _score(PaymentProduct product, Merchant merchant) {
    final rule = product.ruleFor(merchant.category);
    final value = _benefitValue(rule, merchant.amount);
    return ScoredProduct(
      product: product,
      rewardType: rule.type,
      rewardLabel: _label(rule, merchant.amount),
      benefitValue: value,
    );
  }

  double _benefitValue(RewardRule rule, int amount) {
    switch (rule.type) {
      case RewardType.points:
        return rule.rate * amount * _pointValue;
      case RewardType.miles:
        return rule.rate * amount * _mileValue;
      case RewardType.cashback:
        return rule.rate * amount;
      case RewardType.none:
        return 0;
    }
  }

  String _label(RewardRule rule, int amount) {
    switch (rule.type) {
      case RewardType.points:
        final pts = (rule.rate * amount * 0.003).round();
        return 'Gana ${rule.rate.toStringAsFixed(0)}x Puntos ($pts pts)';
      case RewardType.miles:
        final miles = (rule.rate * amount * 0.002).round();
        return 'Gana ${rule.rate.toStringAsFixed(0)}x Millas ($miles millas)';
      case RewardType.cashback:
        final money = rule.rate * amount;
        final pct = (rule.rate * 100).toStringAsFixed(0);
        return '$pct% Cashback (${_cop.format(money)})';
      case RewardType.none:
        return 'Sin beneficios adicionales';
    }
  }

  String _reasonFor(ScoredProduct best, Merchant merchant, double delta) {
    final categoryName = _categoryName(merchant.category);
    final saving = delta > 0 ? ' Ganas ${_cop.format(delta)} más que la peor opción.' : '';
    switch (best.rewardType) {
      case RewardType.points:
        return 'Seleccionamos ${best.product.name}: '
            'multiplica tus puntos en $categoryName.$saving';
      case RewardType.miles:
        return 'Seleccionamos ${best.product.name}: '
            'acumula millas extra en $categoryName.$saving';
      case RewardType.cashback:
        return 'Seleccionamos ${best.product.name}: '
            'obtienes el mayor cashback disponible en $categoryName.$saving';
      case RewardType.none:
        return 'No hay opciones con beneficios activos para esta compra.';
    }
  }

  String _categoryName(MerchantCategory c) {
    switch (c) {
      case MerchantCategory.restaurant:
        return 'restaurantes';
      case MerchantCategory.grocery:
        return 'supermercados';
      case MerchantCategory.travel:
        return 'viajes';
      case MerchantCategory.fuel:
        return 'combustible';
      case MerchantCategory.clothing:
        return 'tiendas de ropa';
      case MerchantCategory.pharmacy:
        return 'farmacias';
      case MerchantCategory.online:
        return 'compras online';
      case MerchantCategory.other:
        return 'este comercio';
    }
  }
}
