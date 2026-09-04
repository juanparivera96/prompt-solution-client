import 'merchant.dart';

enum ProductType { creditCard, debitCard, currentAccount }

/// Reward mechanics available on a financial product.
enum RewardType { points, cashback, miles, none }

/// A rule that defines how a product rewards spending
/// on a given [MerchantCategory].
class RewardRule {
  final MerchantCategory category;
  final RewardType type;

  /// Multiplier for points/miles, or percentage (0.02 = 2%) for cashback.
  final double rate;

  const RewardRule({
    required this.category,
    required this.type,
    required this.rate,
  });
}

/// A financial product the user owns and can pay with.
class PaymentProduct {
  final String id;
  final String name;
  final ProductType type;
  final String maskedNumber; // "**** 8821"
  final String brand; // Visa Infinite, Mastercard Black, etc.

  /// Default reward when no category-specific rule matches.
  final RewardRule defaultReward;

  /// Category-specific rules (higher rate takes precedence).
  final List<RewardRule> categoryRules;

  const PaymentProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.maskedNumber,
    required this.brand,
    required this.defaultReward,
    this.categoryRules = const [],
  });

  /// Returns the best rule for [category], falling back to [defaultReward].
  RewardRule ruleFor(MerchantCategory category) {
    for (final r in categoryRules) {
      if (r.category == category) return r;
    }
    return defaultReward;
  }

  String get typeLabel {
    switch (type) {
      case ProductType.creditCard:
        return 'CRÉDITO';
      case ProductType.debitCard:
        return 'DÉBITO';
      case ProductType.currentAccount:
        return 'CUENTA';
    }
  }
}
