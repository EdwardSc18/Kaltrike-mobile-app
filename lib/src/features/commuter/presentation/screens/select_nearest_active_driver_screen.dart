import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaltrike_driver_app/src/features/commuter/services/assistant_methods.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart';

class SelectNearestActiveDriversScreen extends StatefulWidget {
  DatabaseReference? referenceRideRequest;

  SelectNearestActiveDriversScreen({this.referenceRideRequest});

  @override
  _SelectNearestActiveDriversScreenState createState() =>
      _SelectNearestActiveDriversScreenState();
}

class _SelectNearestActiveDriversScreenState
    extends State<SelectNearestActiveDriversScreen> {
  StreamSubscription<DatabaseEvent>? _activeDriversSubscription;
  StreamSubscription<DatabaseEvent>? _driversSubscription;
  List<dynamic> _filteredDriversList = [];
  Position? userCurrentPosition;
  Map<String, dynamic> _allDriversDetails = {};
  Map<String, dynamic> _activeDriversLocations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationAndListenForDrivers();
  }

  void _getCurrentLocationAndListenForDrivers() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      userCurrentPosition = position;
    });

    _listenForActiveDrivers();
    _listenForAllDrivers();
  }

  void _listenForActiveDrivers() {
    DatabaseReference activeDriversRef =
    FirebaseDatabase.instance.ref().child("activeDrivers");

    _activeDriversSubscription =
        activeDriversRef.onValue.listen((DatabaseEvent event) {
          if (event.snapshot.value != null) {
            final Map<dynamic, dynamic> activeDriversMap =
            event.snapshot.value as Map<dynamic, dynamic>;

            setState(() {
              _activeDriversLocations = Map<String, dynamic>.from(activeDriversMap);
              _updateFilteredDrivers();
            });
          } else {
            setState(() {
              _activeDriversLocations = {};
              _updateFilteredDrivers();
            });
          }
        });
  }

  void _listenForAllDrivers() {
    DatabaseReference driversRef =
    FirebaseDatabase.instance.ref().child("drivers");

    _driversSubscription = driversRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> driversMap =
        event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _allDriversDetails = Map<String, dynamic>.from(driversMap);
          _updateFilteredDrivers();
        });
      } else {
        setState(() {
          _allDriversDetails = {};
          _updateFilteredDrivers();
        });
      }
    });
  }

  void _updateFilteredDrivers() {
    if (userCurrentPosition == null ||
        _activeDriversLocations.isEmpty ||
        _allDriversDetails.isEmpty) {
      setState(() {
        _filteredDriversList = [];
        _isLoading = false;
      });
      return;
    }

    List<dynamic> nearbyDrivers = [];

    _activeDriversLocations.forEach((driverId, locationData) {
      if (_allDriversDetails.containsKey(driverId)) {
        final driverDetails = _allDriversDetails[driverId];
        final hasLocation = locationData["l"] != null &&
            locationData["l"] is List &&
            locationData["l"].length == 2;

        if (hasLocation) {
          final driverLat = locationData["l"][0] is double
              ? locationData["l"][0]
              : double.tryParse(locationData["l"][0].toString());
          final driverLng = locationData["l"][1] is double
              ? locationData["l"][1]
              : double.tryParse(locationData["l"][1].toString());

          if (driverLat != null && driverLng != null) {
            final distance = Geolocator.distanceBetween(
              userCurrentPosition!.latitude,
              userCurrentPosition!.longitude,
              driverLat,
              driverLng,
            );

            if (distance <= 10000) {
              nearbyDrivers.add({
                "id": driverId,
                ...driverDetails,
                "latitude": driverLat,
                "longitude": driverLng,
                "distance": distance,
              });
            }
          }
        }
      }
    });

    setState(() {
      _filteredDriversList = nearbyDrivers;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _activeDriversSubscription?.cancel();
    _driversSubscription?.cancel();
    dList = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dropOff = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    // If no destination, fare = 0 (safe fallback)
    final LatLng? destinationLatLng = dropOff == null
        ? null
        : LatLng(dropOff.locationLatitude!, dropOff.locationLongitude!);

    // Use the current fixed passenger fare rule (₱20 base fare)
    final double fixedFare = destinationLatLng == null
        ? 0.0
        : AssistantMethods.calculateFixedFareForDestination(destinationLatLng);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              widget.referenceRideRequest!.remove();
              Fluttertoast.showToast(msg: "You have cancelled the ride request");
              SystemNavigator.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFFEF4444),
                size: 20,
              ),
            ),
          ),
        ),
        title: const Text(
          "Available Drivers",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Builder(
        builder: (context) {
          final filteredList = _filteredDriversList
              .where((driver) =>
          driver["name"] != null &&
              driver["name"].toString().trim().isNotEmpty)
              .toList();

          final uniqueList =
          filteredList.fold<Map<String, dynamic>>({}, (map, driver) {
            final key = driver["id"]?.toString() ?? driver["name"].toString();
            map[key] = driver;
            return map;
          }).values.toList();

          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF2563EB),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Finding nearby drivers...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please wait a moment",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          if (uniqueList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.directions_car_rounded,
                      color: Colors.grey.shade400,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No drivers available",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Please try again later",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade300.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${uniqueList.length} drivers found",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Tap to select a driver",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: uniqueList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final driver = uniqueList[index];

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          chosenDriverId = driver["id"]?.toString() ?? "";
                        });
                        Navigator.pop(context, "driverChoosed");
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade100,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.grey.shade100,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFF2563EB).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: (driver["vechicle_details"] != null &&
                                    driver["vechicle_details"]["type"] !=
                                        null)
                                    ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    "images/${driver["vechicle_details"]["type"]}.png",
                                    fit: BoxFit.contain,
                                  ),
                                )
                                    : const Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF2563EB),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      driver["name"] ?? "Unknown Driver",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (driver["vechicle_details"]
                                    ?["vehicle_model"] !=
                                        null)
                                      Text(
                                        driver["vechicle_details"]
                                        ["vehicle_model"],
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        SmoothStarRating(
                                          rating: double.tryParse(driver[
                                          "ratings"]
                                              ?.toString() ??
                                              "0.0") ??
                                              0.0,
                                          color: const Color(0xFFF59E0B),
                                          borderColor:
                                          const Color(0xFFF59E0B),
                                          allowHalfRating: true,
                                          starCount: 5,
                                          size: 16,
                                          spacing: 1,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          (double.tryParse(driver["ratings"]
                                              ?.toString() ??
                                              "0.0") ??
                                              0.0)
                                              .toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF10B981),
                                          Color(0xFF059669)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "₱${fixedFare.toStringAsFixed(0)}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (driver["distance"] != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: Color(0xFF2563EB),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${(driver["distance"] / 1000).toStringAsFixed(1)} km",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
