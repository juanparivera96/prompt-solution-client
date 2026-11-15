import 'package:flutter_test/flutter_test.dart';

import 'package:agent_payment_ai_recomendation/data/mock_repository.dart';
import 'package:agent_payment_ai_recomendation/models/ai_recommendation.dart';
import 'package:agent_payment_ai_recomendation/models/customer_context.dart';
import 'package:agent_payment_ai_recomendation/models/merchant.dart';
import 'package:agent_payment_ai_recomendation/models/payment_product.dart';

const _repo = MockRepository();

const _noReward = RewardRule(
  category: MerchantCategory.other,
  type: RewardType.none,
  rate: 0,
);

PaymentProduct _card({required double limit, required double used}) =>
    PaymentProduct(
      id: 'c$limit',
      name: 'Tarjeta',
      brand: 'Tarjeta',
      type: ProductType.creditCard,
      maskedNumber: '**** 0000',
      defaultReward: _noReward,
      creditLimitCop: limit,
      creditUsedCop: used,
    );

PaymentProduct _account(double balance) => PaymentProduct(
      id: 'a$balance',
      name: 'Cuenta',
      brand: 'Cuenta',
      type: ProductType.currentAccount,
      maskedNumber: '**** 0000',
      defaultReward: _noReward,
      balanceCop: balance,
    );

void main() {
  // The API's catalog (api/data/catalog.json) holds these same numbers. As
  // long as they match, the model receives the same inputs whether the data
  // comes from the app or from the catalog.
  const catalog = {
    'USR-1385': (balance: 900000.0, creditUsage: 0.88),
    'USR-1483': (balance: 150000.0, creditUsage: 0.15),
    'USR-1372': (balance: 400000.0, creditUsage: 0.74),
  };

  for (final MapEntry(key: id, value: expected) in catalog.entries) {
    test('customer $id sends the balance and credit usage of the catalog', () {
      final customer = _repo.profileById(id).context;

      expect(customer.balanceCop, expected.balance);
      expect(customer.creditUsage, expected.creditUsage);
      expect(customer.methods, PaymentMethod.values.toSet());
    });
  }

  test('the customer without a credit card sends credit usage 1', () {
    final customer = _repo.profileById('USR-1167').context;

    expect(customer.balanceCop, 600000);
    expect(customer.hasCredit, isFalse);
    expect(customer.creditUsage, 1);
    expect(customer.methods, {PaymentMethod.debit, PaymentMethod.transfer});
    expect(customer.toJson(), {
      'saldo_cop': 600000,
      'uso_cupo': 1,
      'medios': ['DEBIT_CARD', 'DIRECT_ACCOUNT_TRANSFER'],
    });
  });

  test('credit usage is what is owed over the limit, across all cards', () {
    final customer = CustomerContext.fromProducts([
      _card(limit: 6000000, used: 3000000),
      _card(limit: 2000000, used: 0),
    ]);

    expect(customer.creditUsage, 0.375);
    expect(customer.balanceCop, 0);
    expect(customer.methods, {PaymentMethod.credit});
  });

  test('the balance is the one of the fullest account', () {
    final customer = CustomerContext.fromProducts([
      _account(80000),
      _account(250000),
    ]);

    expect(customer.balanceCop, 250000);
    expect(customer.creditUsage, 1);
  });

  test('every demo customer has a unique id', () {
    final ids = _repo.demoProfiles().map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
