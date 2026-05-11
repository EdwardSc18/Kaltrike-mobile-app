import 'package:flutter/cupertino.dart';
import 'package:kaltrike_driver_app/src/shared/models/directions.dart';
import 'package:kaltrike_driver_app/src/features/driver/models/trips_history_model.dart';

class AppInfo extends ChangeNotifier {
  Directions? userPickUpLocation, userDropOffLocation;
  int countTotalTrips = 0;
  List<String> historyTripsKeysList = [];
  List<TripsHistoryModel> allTripsHistoryInformationList = [];
  // track which trip keys we've already added (prevents duplicates)
  List<String> allTripsHistoryKeysList = [];
  String driverTotalEarnings = "0";
  String driverAverageRatings = "0";

  void updatePickUpLocationAddress(Directions userPickUpAddress) {
    userPickUpLocation = userPickUpAddress;
    notifyListeners();
  }

  void updateDropOffLocationAddress(Directions userDropOffAddress) {
    userDropOffLocation = userDropOffAddress;
    notifyListeners();
  }

  void updateOverAllTripsCounter(int overAllTripsCounter) {
    countTotalTrips = overAllTripsCounter;
    notifyListeners();
  }

  void updateOverAllTripsKeys(List<String> tripsKeysList) {
    historyTripsKeysList = tripsKeysList;
    notifyListeners();
  }

  /// Adds a trip model and (optionally) its firebase key.
  /// If tripKey is provided the method will skip adding duplicates by key.
  void updateOverAllTripsHistoryInformation(TripsHistoryModel eachTripHistory, {String? tripKey}) {
    if (tripKey != null) {
      if (allTripsHistoryKeysList.contains(tripKey)) {
        // already added, skip
        return;
      } else {
        allTripsHistoryKeysList.add(tripKey);
      }
    }

    allTripsHistoryInformationList.add(eachTripHistory);

    // keep counter in sync automatically
    countTotalTrips = allTripsHistoryInformationList.length;
    notifyListeners();
  }

  // Clear previous trips before reloading fresh ones
  void clearOverAllTripsHistoryInformation() {
    allTripsHistoryInformationList.clear();
    allTripsHistoryKeysList.clear();
    countTotalTrips = 0;
    notifyListeners();
  }

  void updateDriverTotalEarnings(String driverEarnings) {
    driverTotalEarnings = driverEarnings;
    notifyListeners();
  }

  void updateDriverAverageRatings(String driverRatings) {
    driverAverageRatings = driverRatings;
    notifyListeners();
  }
}
