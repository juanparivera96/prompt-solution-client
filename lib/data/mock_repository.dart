import '../models/demo_profile.dart';
import '../models/merchant.dart';
import '../models/payment_product.dart';
import '../models/user_stats.dart';

/// In-memory data source used until the real bank API is wired.
/// Kept intentionally simple: static seed data + a QR payload decoder.
class MockRepository {
  const MockRepository();

  List<PaymentProduct> userProducts() => const [
        PaymentProduct(
          id: 'p1',
          name: 'Visa Infinite',
          brand: 'Visa Infinite',
          type: ProductType.creditCard,
          maskedNumber: '**** 8821',
          defaultReward: RewardRule(
            category: MerchantCategory.other,
            type: RewardType.points,
            rate: 1.0,
          ),
          categoryRules: [
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
        PaymentProduct(
          id: 'p2',
          name: 'Mastercard Black',
          brand: 'Mastercard Black',
          type: ProductType.creditCard,
          maskedNumber: '**** 4410',
          defaultReward: RewardRule(
            category: MerchantCategory.other,
            type: RewardType.cashback,
            rate: 0.02,
          ),
          categoryRules: [
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
          defaultReward: RewardRule(
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
          defaultReward: RewardRule(
            category: MerchantCategory.other,
            type: RewardType.none,
            rate: 0,
          ),
        ),
      ];

  /// Buyers the recommendation API knows (same ids as its catalog). The
  /// balance and credit usage are what make the model answer differently.
  List<DemoProfile> demoProfiles() => const [
        DemoProfile(
          id: 'USR-1385',
          name: 'Saldo holgado',
          description: r'Saldo de $900.000 · cupo de crédito usado al 88 %',
        ),
        DemoProfile(
          id: 'USR-1483',
          name: 'Saldo ajustado',
          description: r'Saldo de $150.000 · cupo de crédito usado al 15 %',
        ),
        DemoProfile(
          id: 'USR-1372',
          name: 'Busca cashback',
          description: r'Saldo de $400.000 · muy sensible al cashback',
        ),
      ];

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
