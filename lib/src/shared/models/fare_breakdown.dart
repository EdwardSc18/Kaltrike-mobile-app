class FareBreakdown {
  final double totalFare;
  final double distanceKm;
  final double coveredDistanceKm;
  final double additionalDistanceKm;
  final bool isOutOfRange;
  final String previewLabel;
  final String explanation;

  const FareBreakdown({
    required this.totalFare,
    required this.distanceKm,
    required this.coveredDistanceKm,
    required this.additionalDistanceKm,
    required this.isOutOfRange,
    required this.previewLabel,
    required this.explanation,
  });
}
