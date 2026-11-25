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
  final String brand; // Tarjeta Crédito, Tarjeta Débito, Saldo disponible

  /// Default reward when no category-specific rule matches.
  final RewardRule defaultReward;

  /// Category-specific rules (higher rate takes precedence).
  final List<RewardRule> categoryRules;

  /// Money in the account, in COP: set for accounts and for the debit card
  /// that draws from one. Null for credit cards.
  final double? balanceCop;

  /// Credit limit and the part of it already used, in COP. Credit cards only.
  final double? creditLimitCop;
  final double? creditUsedCop;

  const PaymentProduct({
    required this.id,
    required this.name,
    required this.type,
    required this.maskedNumber,
    required this.brand,
    required this.defaultReward,
    this.categoryRules = const [],
    this.balanceCop,
    this.creditLimitCop,
    this.creditUsedCop,
  });

  /// Credit still available on a card, in COP. Null when it isn't one.
  double? get creditAvailableCop {
    final limit = creditLimitCop;
    final used = creditUsedCop;
    return limit == null || used == null ? null : limit - used;
  }

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
        return 'TRANSFERENCIA';
    }
  }
}
