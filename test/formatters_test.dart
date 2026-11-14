import 'package:flutter_test/flutter_test.dart';

import 'package:agent_payment_ai_recomendation/core/formatters.dart';
import 'package:agent_payment_ai_recomendation/data/mock_repository.dart';
import 'package:agent_payment_ai_recomendation/services/recommendation_service.dart';

void main() {
  test('pesos are written with the symbol first', () {
    expect(Formatters.cop.format(48000), r'$48.000');
    expect(Formatters.cop.format(1240500), r'$1.240.500');
    expect(Formatters.cop.format(0), r'$0');
    expect(Formatters.cop.format(4799.6), r'$4.800');
  });

  test('the rule-based texts use the same format', () {
    const repo = MockRepository();
    final result = const RecommendationService().rank(
      merchant: repo.decodeQr(null), // Restaurante El Portal, $145.200
      products: repo.userProducts(),
    );

    expect(result.reason, contains(r'Ganas $4.356 más que la peor opción'));
    final mastercard =
        result.ranked.firstWhere((s) => s.product.name == 'Mastercard Black');
    expect(mastercard.rewardLabel, r'2% Cashback ($2.904)');
  });
}
