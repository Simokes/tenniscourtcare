// lib/domain/entities/refill_recommendation.dart

class RefillRecommendation {
  final int recommendedBags;
  final String reason;
  final bool isCritical;

  const RefillRecommendation({
    required this.recommendedBags,
    required this.reason,
    this.isCritical = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefillRecommendation &&
          runtimeType == other.runtimeType &&
          recommendedBags == other.recommendedBags &&
          reason == other.reason &&
          isCritical == other.isCritical;

  @override
  int get hashCode =>
      recommendedBags.hashCode ^ reason.hashCode ^ isCritical.hashCode;

  @override
  String toString() =>
      'RefillRecommendation(bags: $recommendedBags, reason: "$reason", critical: $isCritical)';
}
