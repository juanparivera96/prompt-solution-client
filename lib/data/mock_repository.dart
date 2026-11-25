import '../models/demo_profile.dart';
import '../models/merchant.dart';
import '../models/payment_product.dart';
import '../models/user_stats.dart';

/// In-memory data source used until the real bank API is wired.
/// Kept intentionally simple: static seed data + a QR payload decoder.
class MockRepository {
  const MockRepository();

  /// Products of the customer [profileId] (the first customer when it is
  /// null or unknown), with the money in each.
  ///
  /// Plays the part of the bank's core system: the app gets them when the
  /// session starts, so nobody has to type a balance.
  List<PaymentProduct> userProducts([String? profileId]) =>
      profileById(profileId).products;

  /// Password of every demo customer. Synthetic data for the demo.
  static const String demoPassword = 'demo2026';

  /// The bank's customers in the demo. Their ids are the ones the
  /// recommendation API knows (`GET /v1/meta`), and the balance and credit
  /// usage of each are the ones in its catalog, so the model decides with
  /// the same numbers whether they come from the app or from the API.
  List<DemoProfile> demoProfiles() => [
        DemoProfile(
          id: 'USR-1385',
          name: 'Saldo holgado',
          username: 'holgado',
          password: demoPassword,
          products: _products(
            balance: 900000,
            visaUsed: 7040000,
            mastercardUsed: 3520000,
          ),
        ),
        DemoProfile(
          id: 'USR-1483',
          name: 'Saldo ajustado',
          username: 'ajustado',
          password: demoPassword,
          products: _products(
            balance: 150000,
            visaUsed: 1200000,
            mastercardUsed: 600000,
          ),
        ),
        DemoProfile(
          id: 'USR-1372',
          name: 'Busca cashback',
          username: 'cashback',
          password: demoPassword,
          trait: 'muy sensible al cashback',
          products: _products(
            balance: 400000,
            visaUsed: 5920000,
            mastercardUsed: 2960000,
          ),
        ),
        DemoProfile(
          id: 'USR-1167',
          name: 'Sin tarjeta de crédito',
          username: 'sincredito',
          password: demoPassword,
          products: _products(balance: 600000),
        ),
      ];

  /// The customer with these credentials, or null when they don't match.
  /// The username ignores case and surrounding spaces; the password doesn't.
  DemoProfile? authenticate(String username, String password) {
    final user = username.trim().toLowerCase();
    for (final profile in demoProfiles()) {
      if (profile.username == user && profile.password == password) {
        return profile;
      }
    }
    return null;
  }

  /// The profile with [id], or the first one when [id] is null or unknown.
  DemoProfile profileById(String? id) {
    final profiles = demoProfiles();
    return profiles.firstWhere((p) => p.id == id, orElse: () => profiles.first);
  }

  UserStats userStats() => const UserStats(
        totalBenefits: 1240500,
        totalPoints: 45200,
        totalCashback: 320000,
        growthPercent: 12,
      );

  /// Decodes a QR payload into a [Merchant]. The MVP accepts either:
  ///  - a pipe-separated string: `id|name|location|category|amount`
  ///  - or any string, falling back to a demo restaurant transaction.
  Merchant decodeQr(String? payload) {
    if (payload != null && payload.contains('|')) {
      final parts = payload.split('|');
      if (parts.length >= 5) {
        return Merchant(
          id: parts[0],
          name: parts[1],
          location: parts[2],
          category: _parseCategory(parts[3]),
          amount: int.tryParse(parts[4]) ?? 0,
        );
      }
    }
    return const Merchant(
      id: 'TXN-99284-B',
      name: 'Restaurante El Portal',
      location: 'Bogotá, COL',
      category: MerchantCategory.restaurant,
      amount: 145200,
    );
  }

  MerchantCategory _parseCategory(String raw) {
    return MerchantCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == raw.toLowerCase(),
      orElse: () => MerchantCategory.other,
    );
  }
}

const double _visaLimit = 8000000;
const double _mastercardLimit = 4000000;

/// The bank's product line with one customer's money in it.
///
/// [balance] is the account balance; the debit card draws from that account.
/// [visaUsed] and [mastercardUsed] are what the customer owes on each credit
/// card: a customer without them has no credit cards.
List<PaymentProduct> _products({
  required double balance,
  double? visaUsed,
  double? mastercardUsed,
}) {
  return [
    if (visaUsed != null)
      PaymentProduct(
        id: 'p1',
        name: 'Visa Infinite',
        brand: 'Visa Infinite',
        type: ProductType.creditCard,
        maskedNumber: '**** 8821',
        creditLimitCop: _visaLimit,
        creditUsedCop: visaUsed,
        defaultReward: const RewardRule(
          category: MerchantCategory.other,
          type: RewardType.points,
          rate: 1.0,
        ),
        categoryRules: const [
          RewardRule(
            category: MerchantCategory.restaurant,
            type: RewardType.points,
            rate: 3.0,
          ),
          RewardRule(
            category: MerchantCategory.travel,
            type: RewardType.miles,
            rate: 2.0,
          ),
        ],
      ),
    if (mastercardUsed != null)
      PaymentProduct(
        id: 'p2',
        name: 'Mastercard Black',
        brand: 'Mastercard Black',
        type: ProductType.creditCard,
        maskedNumber: '**** 4410',
        creditLimitCop: _mastercardLimit,
        creditUsedCop: mastercardUsed,
        defaultReward: const RewardRule(
          category: MerchantCategory.other,
          type: RewardType.cashback,
          rate: 0.02,
        ),
        categoryRules: const [
          RewardRule(
            category: MerchantCategory.grocery,
            type: RewardType.cashback,
            rate: 0.04,
          ),
        ],
      ),
    PaymentProduct(
      id: 'p4',
      name: 'Tarjeta Débito',
      brand: 'Tarjeta Débito',
      type: ProductType.debitCard,
      maskedNumber: '**** 5530',
      balanceCop: balance,
      defaultReward: const RewardRule(
        category: MerchantCategory.other,
        type: RewardType.none,
        rate: 0,
      ),
    ),
    PaymentProduct(
      id: 'p3',
      name: 'Cuenta Corriente',
      brand: 'Cuenta Corriente',
      type: ProductType.currentAccount,
      maskedNumber: '**** 1002',
      balanceCop: balance,
      defaultReward: const RewardRule(
        category: MerchantCategory.other,
        type: RewardType.none,
        rate: 0,
      ),
    ),
  ];
}
