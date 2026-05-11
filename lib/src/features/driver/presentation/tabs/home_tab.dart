import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kaltrike_driver_app/src/features/driver/services/push_notification_system.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/splash_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/validation_screen.dart';
import 'package:provider/provider.dart';
import 'package:kaltrike_driver_app/src/features/driver/services/assistant_methods.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/state/app_info.dart';
import 'package:kaltrike_driver_app/src/shared/models/directions.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  GoogleMapController? newGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(17.411735, 121.43845),
    zoom: 14.4746,
  );

  LocationPermission? _locationPermission;
  StreamSubscription<Position>? streamSubscriptionPosition;

  bool _isDriverInfoLoaded = false;
  PushNotificationSystem? pushNotificationSystem;
  bool _isRefreshing = false; // Track refresh state
  bool _isCheckingValidationStatus = false;
  bool _hasValidationStatusLoaded = false;
  bool _hasSubmittedValidationRequirements = false;

  LatLng? _lastCameraTarget;
  DateTime? _lastCameraMoveAt;

  String _validationStatus = 'pending';
  bool _isValidationApproved = false;

  //Location Permission
  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  // Get the current position
  locateDriverPosition() async {
    try {
      Position cPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      driverCurrentPosition = cPosition;

      LatLng latLngPosition =
      LatLng(driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      // animate camera
      CameraPosition cameraPosition =
      CameraPosition(target: latLngPosition, zoom: 16);

      _moveCameraIfNeeded(latLngPosition, force: true);

      // convert geoCode to readable text
      try {
        String humanReadableAddress =
        await AssistantMethods.searchAddressForGeographicCoOrdinates(
            driverCurrentPosition!, context);

        print("Driver address = $humanReadableAddress");
      } catch (e) {
        print("Error getting driver address: $e");
      }

      // driver ratings
      AssistantMethods.readDriverRatings(context);
    } catch (e) {
      print("Error locating driver position: $e");
    }
  }


  String _normalizeValidationStatus(Object? rawStatus) {
    final normalizedStatus = rawStatus?.toString().trim().toLowerCase();
    if (normalizedStatus == null || normalizedStatus.isEmpty) {
      return 'pending';
    }
    return normalizedStatus;
  }

  void _applyValidationData(Map<dynamic, dynamic> driverData) {
    final validationStatus = _normalizeValidationStatus(driverData['validationStatus']);
    final validationIdUrl = (driverData['validationIdUrl'] ?? '').toString().trim();
    final validationSelfieUrl = (driverData['validationSelfieUrl'] ?? '').toString().trim();
    final validationPermitUrl = (driverData['validationPermitUrl'] ?? '').toString().trim();

    _validationStatus = validationStatus;
    _isValidationApproved = validationStatus == 'approved' || validationStatus == 'validated';
    _hasSubmittedValidationRequirements = validationIdUrl.isNotEmpty &&
        validationSelfieUrl.isNotEmpty &&
        validationPermitUrl.isNotEmpty;
    _hasValidationStatusLoaded = true;
  }

  Future<void> _refreshValidationStatus({bool showFeedback = true}) async {
    if (currentFirebaseUser == null || _isCheckingValidationStatus) {
      return;
    }

    setState(() {
      _isCheckingValidationStatus = true;
    });

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('drivers')
          .child(currentFirebaseUser!.uid)
          .get();

      if (snapshot.value == null) {
        if (showFeedback) {
          Fluttertoast.showToast(
            msg: 'Unable to find your driver profile. Please log in again.',
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
        return;
      }

      final driverData = Map<dynamic, dynamic>.from(snapshot.value as Map);
      if (mounted) {
        setState(() {
          _applyValidationData(driverData);
        });
      } else {
        _applyValidationData(driverData);
      }

      if (!showFeedback) {
        return;
      }

      if (_isValidationApproved) {
        Fluttertoast.showToast(
          msg: 'Your validation is approved. You can now go online.',
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        return;
      }

      if (_hasSubmittedValidationRequirements) {
        Fluttertoast.showToast(
          msg: 'Your validation requirements were already submitted and are still pending admin review.',
          backgroundColor: Colors.orange,
          textColor: Colors.white,
        );
        return;
      }

      Fluttertoast.showToast(
        msg: 'No submitted validation requirements were found yet. Please tap Submit Validation Requirement.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Unable to check your validation status right now. Please try again.',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingValidationStatus = false;
        });
      } else {
        _isCheckingValidationStatus = false;
      }
    }
  }

  Future<void> _openValidationScreen() async {
    if (_isCheckingValidationStatus) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ValidationScreen()),
    );

    if (mounted) {
      _refreshValidationStatus(showFeedback: false);
    }
  }

  Widget _buildValidationPendingCard() {
    final statusLabel = _validationStatus.toUpperCase();
    final hasSubmittedRequirements = _hasSubmittedValidationRequirements;
    final cardAccentColor = hasSubmittedRequirements
        ? const Color(0xFFF59E0B)
        : const Color(0xFF2563EB);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: cardAccentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  hasSubmittedRequirements
                      ? Icons.hourglass_top_rounded
                      : Icons.verified_user_outlined,
                  color: cardAccentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasSubmittedRequirements
                          ? 'Validation is still pending'
                          : 'Validation requirements needed',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: cardAccentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cardAccentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            hasSubmittedRequirements
                ? 'Your validation documents were already submitted. Please wait for admin approval before going online.'
                : 'Your account cannot go online yet. Submit your validation requirements now, or confirm if you already submitted them before.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openValidationScreen,
              icon: const Icon(Icons.upload_file_rounded, size: 20),
              label: const Text(
                'Submit Validation Requirement',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isCheckingValidationStatus
                  ? null
                  : () => _refreshValidationStatus(),
              icon: _isCheckingValidationStatus
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.fact_check_outlined, size: 20),
              label: Text(
                _isCheckingValidationStatus ? 'Checking status...' : 'Already Submitted',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  readCurrentDriverInformation() async {
    currentFirebaseUser = fAuth.currentUser;

    await FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .once()
        .then((DatabaseEvent snap) {
      if (snap.snapshot.value != null) {
        final driverData = Map<dynamic, dynamic>.from(snap.snapshot.value as Map);

        onlineDriverData.id = driverData["id"];
        onlineDriverData.name = driverData["name"];
        onlineDriverData.phone = driverData["phone"];
        onlineDriverData.email = driverData["email"];
        onlineDriverData.vehicle_color =
        driverData["vechicle_details"]["vehicle_color"];
        onlineDriverData.vehicle_model =
        driverData["vechicle_details"]["vehicle_model"];
        onlineDriverData.plate_number =
        driverData["vechicle_details"]["plate_number"];

        driverVehicleType = driverData["vechicle_details"]["type"];

        if (mounted) {
          setState(() {
            _applyValidationData(driverData);
          });
        } else {
          _applyValidationData(driverData);
        }

        print("Vehicle Details :: ");
        print(onlineDriverData.vehicle_color);
        print(onlineDriverData.vehicle_model);
        print(onlineDriverData.plate_number);
      }
    });

    pushNotificationSystem = PushNotificationSystem();
    pushNotificationSystem?.initializeCloudMessaging(context);
    pushNotificationSystem?.generateAndGetToken();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      pushNotificationSystem?.onReturnToHomeTab();
    });

    AssistantMethods.readDriverEarnings(context);
  }

  // Refresh method to check for new ride requests
  Future<void> _refreshRideRequests() async {
    if (!isDriverActive) {
      Fluttertoast.showToast(msg: "You need to be online to check for rides");
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Simulate checking for new requests
      await Future.delayed(Duration(seconds: 2));

      // You can add your actual logic here to check for new ride requests
      // For example, query Firebase for nearby ride requests

      Fluttertoast.showToast(msg: "Checking for new ride requests...");

      // Add your actual ride request checking logic here
      // Example:
      // await checkForNearbyRideRequests();

    } catch (e) {
      print("Error refreshing ride requests: $e");
      Fluttertoast.showToast(msg: "Error checking for rides");
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();

    if (!_isDriverInfoLoaded) {
      readCurrentDriverInformation();
      _isDriverInfoLoaded = true;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      pushNotificationSystem?.onReturnToHomeTab();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          mapType: MapType.normal,
          myLocationEnabled: true,
          myLocationButtonEnabled: false, // Disable default location button
          zoomControlsEnabled: false, // Disable default zoom controls
          initialCameraPosition: _kGooglePlex,
          onMapCreated: (GoogleMapController controller) {
            _controllerGoogleMap.complete(controller);
            newGoogleMapController = controller;
            locateDriverPosition();

            // Clean up any pending ride requests when map is created
            WidgetsBinding.instance.addPostFrameCallback((_) {
              pushNotificationSystem?.onReturnToHomeTab();
            });
          },
        ),

        // Overlay when offline
        statusText != "Now Online"
            ? Container(
          height: MediaQuery.of(context).size.height,
          width: double.infinity,
          color: Colors.black87,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 160),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_off_rounded,
                      size: 50,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "You're Offline",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isValidationApproved
                        ? 'Go online when you are ready to accept rides.'
                        : 'Admin approval is required before you can go online.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.82),
                      height: 1.5,
                    ),
                  ),
                  if (_hasValidationStatusLoaded && !_isValidationApproved)
                    _buildValidationPendingCard(),
                ],
              ),
            ),
          ),
        )
            : Container(),

        // Header with Driver Info
        Positioned(
          top: 35,
          left: 20,
          right: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Driver Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Driver Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        onlineDriverData.name ?? "Driver",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${onlineDriverData.vehicle_model ?? 'Vehicle'} • ${onlineDriverData.plate_number ?? 'Plate'}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusText != "Now Online"
                        ? Colors.red.withOpacity(0.1)
                        : const Color(0xFF2563EB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusText != "Now Online"
                              ? Colors.red
                              : const Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText != "Now Online" ? "Offline" : "Online",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusText != "Now Online"
                              ? Colors.red
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Refresh Button (Top Right)
        Positioned(
          top: 120,
          right: 20,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _isRefreshing ? null : _refreshRideRequests,
                child: Stack(
                  children: [
                    Center(
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: _isRefreshing
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        )
                            : Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF2563EB),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Custom Location Button (Below Refresh Button)
        Positioned(
          top: 180,
          right: 20,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: () {
                  locateDriverPosition();
                  Fluttertoast.showToast(msg: "Locating your position...");
                },
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
            ),
          ),
        ),

        // Custom Zoom Controls (Right Side)
        Positioned(
          right: 20,
          top: MediaQuery.of(context).size.height * 0.4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Zoom In Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                    onTap: () {
                      newGoogleMapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(25),
                          topRight: Radius.circular(25),
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Divider
                Container(
                  width: 30,
                  height: 1,
                  color: Colors.grey.shade300,
                ),

                // Zoom Out Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                    onTap: () {
                      newGoogleMapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      );
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: const Icon(
                        Icons.remove_rounded,
                        color: Color(0xFF2563EB),
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Online/Offline Button
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: statusText != "Now Online"
                  ? const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
                  : const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: statusText != "Now Online"
                      ? Colors.red.withOpacity(0.4)
                      : Colors.blue.shade600.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                if (!_hasValidationStatusLoaded) {
                  Fluttertoast.showToast(
                    msg: 'Checking your validation status. Please wait a moment.',
                    backgroundColor: Colors.orange,
                    textColor: Colors.white,
                  );
                  return;
                }

                if (isDriverActive != true && !_isValidationApproved) {
                  Fluttertoast.showToast(
                    msg: 'Your account is still ${_validationStatus.toUpperCase()}. Use the validation options above while waiting for admin approval.',
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                  return;
                }

                //offline
                if (isDriverActive != true) {
                  driverIsOnlineNow();
                  updateDriversLocationAtRealTime();

                  setState(() {
                    statusText = "Now Online";
                    isDriverActive = true;
                  });

                  Fluttertoast.showToast(msg: "You are now online and ready to accept rides");
                }
                //online
                else {
                  driverIsOfflineNow();

                  // Clear any pending ride requests when going offline
                  pushNotificationSystem?.clearPendingRideRequests();

                  setState(() {
                    statusText = "Now Offline";
                    isDriverActive = false;
                  });

                  Fluttertoast.showToast(msg: "You are now offline");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: statusText != "Now Online"
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Go Online",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.stop_rounded, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    "Go Offline",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  driverIsOnlineNow() async {
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    driverCurrentPosition = pos;

    Geofire.initialize("activeDrivers");

    Geofire.setLocation(
      currentFirebaseUser!.uid,
      driverCurrentPosition!.latitude,
      driverCurrentPosition!.longitude,
    );

    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    // set online status
    ref.set("idle"); // searching for ride request

    // 🔥 auto-clean when disconnected/unexpected exit
    ref.onDisconnect().remove();
    FirebaseDatabase.instance
        .ref()
        .child("activeDrivers")
        .child(currentFirebaseUser!.uid)
        .onDisconnect()
        .remove();

    ref.onValue.listen((event) {});
  }

  void _moveCameraIfNeeded(LatLng target, {bool force = false}) {
    final now = DateTime.now();

    if (force || _lastCameraTarget == null || _lastCameraMoveAt == null) {
      _lastCameraTarget = target;
      _lastCameraMoveAt = now;
      newGoogleMapController?.moveCamera(CameraUpdate.newLatLng(target));
      return;
    }

    final movedMeters = Geolocator.distanceBetween(
      _lastCameraTarget!.latitude,
      _lastCameraTarget!.longitude,
      target.latitude,
      target.longitude,
    );

    final secondsPassed = now.difference(_lastCameraMoveAt!).inSeconds;

    if (movedMeters >= 25 || secondsPassed >= 4) {
      _lastCameraTarget = target;
      _lastCameraMoveAt = now;
      newGoogleMapController?.moveCamera(CameraUpdate.newLatLng(target));
    }
  }

  updateDriversLocationAtRealTime() {
    streamSubscriptionPosition?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 15,
    );

    streamSubscriptionPosition = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      driverCurrentPosition = position;

      if (isDriverActive == true) {
        Geofire.setLocation(
          currentFirebaseUser!.uid,
          driverCurrentPosition!.latitude,
          driverCurrentPosition!.longitude,
        );
      }

      final latLng = LatLng(
        driverCurrentPosition!.latitude,
        driverCurrentPosition!.longitude,
      );

      _moveCameraIfNeeded(latLng);
    });
  }

  driverIsOfflineNow() {
    Geofire.removeLocation(currentFirebaseUser!.uid);

    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    ref.remove();

    // stop updating driver's location
    streamSubscriptionPosition?.cancel();
  }

  @override
  void dispose() {
    streamSubscriptionPosition?.cancel();
    pushNotificationSystem?.disposeListeners();
    super.dispose();
  }
}