/// Merchant category — used by the recommendation engine
/// to match category-specific rewards (e.g. 3x on restaurants).
enum MerchantCategory {
  restaurant,
  grocery,
  travel,
  fuel,
  online,
  other,
}

/// A merchant decoded from a QR payload.
class Merchant {
  final String id;
  final String name;
  final String location;
  final MerchantCategory category;
  final int amount; // amount in minor units-free integer (COP has no cents)

  const Merchant({
    required this.id,
    required this.name,
    required this.location,
    required this.category,
    required this.amount,
  });
}
