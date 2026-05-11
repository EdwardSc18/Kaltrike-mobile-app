class FareConfig {
  static const double baseFare = 20.0;
  static const double baseDistanceKm = 3.0;
  static const double additionalPerKm = 5.0;
  static const double maxServiceDistanceKm = 15.0;
  static const double rideSharingAdditionalPassengerFare = 20.0;
  static const double baggageFare = 20.0;

  static int normalizePassengerCount(int passengerCount) {
    return passengerCount < 1 ? 1 : passengerCount;
  }

  static int normalizeBaggageCount(int baggageCount) {
    return baggageCount < 0 ? 0 : baggageCount;
  }

  static double calculatePassengerFare({
    required bool isRideSharing,
    required int passengerCount,
  }) {
    final normalizedPassengers = isRideSharing
        ? normalizePassengerCount(passengerCount)
        : 1;

    return normalizedPassengers * baseFare;
  }

  static double calculateRideSharingFee({
    required bool isRideSharing,
    required int passengerCount,
  }) {
    if (!isRideSharing) return 0.0;

    final normalizedPassengers = normalizePassengerCount(passengerCount);
    final additionalPassengers = normalizedPassengers - 1;
    if (additionalPassengers <= 0) return 0.0;

    return additionalPassengers * rideSharingAdditionalPassengerFare;
  }

  static double calculateBaggageFee(int baggageCount) {
    final normalizedBaggage = normalizeBaggageCount(baggageCount);
    return normalizedBaggage * FareConfig.baggageFare;
  }

  static const String fareRuleName = 'fixed_base_plus_distance_v2';
}
