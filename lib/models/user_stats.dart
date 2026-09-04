/// Aggregated benefit history shown on the profile screen.
class UserStats {
  final double totalBenefits;
  final int totalPoints;
  final double totalCashback;
  final double growthPercent;

  const UserStats({
    required this.totalBenefits,
    required this.totalPoints,
    required this.totalCashback,
    required this.growthPercent,
  });
}
