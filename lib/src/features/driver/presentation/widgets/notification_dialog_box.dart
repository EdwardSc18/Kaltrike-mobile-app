import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/main_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/services/assistant_methods.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/new_trip_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/models/user_ride_request_information.dart';

class NotificationDialogBox extends StatefulWidget {
  UserRideRequestInformation? userRideRequestDetails;
  List<UserRideRequestInformation>? allPendingRequests;

  NotificationDialogBox({this.userRideRequestDetails, this.allPendingRequests});

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  List<LatLng> polyLinePositionCoordinates = [];
  Set<Polyline> setOfPolyline = {};
  PolylinePoints polylinePoints = PolylinePoints(apiKey: '');
  bool isPolylineLoaded = false;
  late GoogleMapController mapController;
  bool _showRideSelection = false;
  List<UserRideRequestInformation> _currentRideRequests = [];
  bool _isProcessingSelection = false;

  // Modern blue color scheme
  final Color _primaryBlue = const Color(0xFF2196F3);
  final Color _darkBlue = const Color(0xFF1976D2);
  final Color _lightBlue = const Color(0xFFE3F2FD);
  final Color _accentBlue = const Color(0xFF42A5F5);
  final Color _backgroundColor = const Color(0xFFF8FBFF);
  final Color _cardColor = Colors.white;
  final Color _textPrimary = const Color(0xFF263238);
  final Color _textSecondary = const Color(0xFF546E7A);
  final Color _successGreen = const Color(0xFF4CAF50);
  final Color _warningRed = const Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _loadPolylineDirection();
    _initializeRideRequests();
  }

  void _initializeRideRequests() {
    if (widget.allPendingRequests != null && widget.allPendingRequests!.isNotEmpty) {
      _currentRideRequests = List.from(widget.allPendingRequests!);
    } else if (widget.userRideRequestDetails != null) {
      _currentRideRequests = [widget.userRideRequestDetails!];
    }
  }

  void _showRideSelectionDialog() {
    setState(() {
      _showRideSelection = true;
    });
  }

  void _hideRideSelectionDialog() {
    setState(() {
      _showRideSelection = false;
    });
  }

  void _handleRideSelection(UserRideRequestInformation selectedRide) async {
    if (_isProcessingSelection) return;

    setState(() {
      _isProcessingSelection = true;
    });

    try {
      // Cancel all other ride requests
      await _cancelOtherRideRequests(selectedRide.rideRequestId!);

      // Accept the selected ride
      await _acceptSelectedRide(selectedRide);

    } catch (error) {
      setState(() {
        _isProcessingSelection = false;
      });

      Fluttertoast.showToast(
        msg: "Error processing selection: $error",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _cancelOtherRideRequests(String selectedRideRequestId) async {
    try {
      DatabaseReference rideRequestsRef = FirebaseDatabase.instance.ref().child("All Ride Requests");

      for (final rideRequest in _currentRideRequests) {
        if (rideRequest.rideRequestId == selectedRideRequestId) {
          continue; // Skip the selected ride
        }

        // Cancel this ride request in Firebase
        await rideRequestsRef.child(rideRequest.rideRequestId!).update({
          "status": "cancelled",
          "cancellation_reason": "Driver selected another ride request",
          "cancelled_by": "driver_system",
          "updated_at": ServerValue.timestamp,
        });

        print("Cancelled ride request: ${rideRequest.rideRequestId}");
      }

      Fluttertoast.showToast(
        msg: "Other ride requests have been cancelled",
        backgroundColor: _darkBlue,
        textColor: Colors.white,
      );
    } catch (error) {
      print("Error cancelling other ride requests: $error");
      Fluttertoast.showToast(
        msg: "Error cancelling other requests",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      rethrow;
    }
  }

  Future<void> _acceptSelectedRide(UserRideRequestInformation selectedRide) async {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(selectedRide.rideRequestId!)
        .once()
        .then((snap) {
      if(snap.snapshot.value != null) {
        String driverName = onlineDriverData.name ?? "Driver";
        String driverPhone = onlineDriverData.phone ?? "Not available";

        String driverVehicleDetails = "";
        if (onlineDriverData.vehicle_model != null && onlineDriverData.plate_number != null) {
          driverVehicleDetails = "${onlineDriverData.vehicle_model} (${onlineDriverData.plate_number})";
        } else if (onlineDriverData.vehicle_model != null) {
          driverVehicleDetails = onlineDriverData.vehicle_model!;
        } else if (onlineDriverData.plate_number != null) {
          driverVehicleDetails = onlineDriverData.plate_number!;
        } else {
          driverVehicleDetails = "Vehicle not specified";
        }

        if (onlineDriverData.vehicle_color != null) {
          driverVehicleDetails += " - ${onlineDriverData.vehicle_color}";
        }

        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("newRideStatus")
            .set("accepted");

        FirebaseDatabase.instance.ref()
            .child("All Ride Requests")
            .child(selectedRide.rideRequestId!)
            .update({
          "status": "accepted",
          "driverId": currentFirebaseUser!.uid,
          "driverName": driverName,
          "driverPhone": driverPhone,
          "vehicle_details": driverVehicleDetails,
          "accepted_at": ServerValue.timestamp,
        }).then((value) {
          Navigator.push(context, MaterialPageRoute(builder: (c)=> NewTripScreen(
            userRideRequestDetails: selectedRide,
          )));
        });
      } else {
        Fluttertoast.showToast(
          msg: "This ride request do not exists.",
          backgroundColor: _warningRed,
          textColor: Colors.white,
        );
      }
    });
  }

  void _removeRideRequest(UserRideRequestInformation rideRequest) {
    setState(() {
      _currentRideRequests.removeWhere(
            (request) => request.rideRequestId == rideRequest.rideRequestId,
      );
    });
  }

  Future<void> _loadPolylineDirection() async {
    if (widget.userRideRequestDetails?.originLatLng != null &&
        widget.userRideRequestDetails?.destinationLatLng != null) {

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        widget.userRideRequestDetails!.originLatLng!,
        widget.userRideRequestDetails!.destinationLatLng!,
      );

      if (directionDetailsInfo != null && directionDetailsInfo.e_points != null) {
        List<PointLatLng> decodedPolyLinePointsResultList =
        PolylinePoints.decodePolyline(directionDetailsInfo.e_points!);

        polyLinePositionCoordinates.clear();

        if (decodedPolyLinePointsResultList.isNotEmpty) {
          for (var pointLatLng in decodedPolyLinePointsResultList) {
            polyLinePositionCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
          }
        }

        setState(() {
          setOfPolyline.clear();
          setOfPolyline.add(
            Polyline(
              color: _primaryBlue,
              width: 6,
              polylineId: const PolylineId("NotificationRoute"),
              jointType: JointType.round,
              points: polyLinePositionCoordinates,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              geodesic: true,
            ),
          );
          isPolylineLoaded = true;
        });
      }
    }
  }

  void _zoomIn() {
    mapController.animateCamera(
      CameraUpdate.zoomIn(),
    );
  }

  void _zoomOut() {
    mapController.animateCamera(
      CameraUpdate.zoomOut(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Show ride selection dialog if there are multiple requests
    if (_showRideSelection && _currentRideRequests.length > 1) {
      return _buildRideSelectionDialog(screenWidth, screenHeight);
    }

    // Show single notification dialog
    return _buildSingleNotificationDialog(screenWidth, screenHeight);
  }

  Widget _buildSingleNotificationDialog(double screenWidth, double screenHeight) {
    return Dialog(
      insetPadding: EdgeInsets.only(
        top: 40,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: Colors.transparent,
      elevation: 8,
      child: Container(
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: _cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 4),
                  Text(
                    "New Ride Request",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildRideTypeIndicator(),
                  if (_currentRideRequests.length > 1) ...[
                    const SizedBox(height: 8),
                    _buildMultipleRequestsIndicator(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Map Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMapSection(screenHeight, screenWidth),
            ),

            const SizedBox(height: 16),

            // Addresses Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAddressesSection(screenWidth, screenHeight),
            ),

            const SizedBox(height: 16),

            // Buttons Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActionButtons(screenWidth, screenHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideSelectionDialog(double screenWidth, double screenHeight) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: _backgroundColor,
      elevation: 8,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: _backgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Multiple Ride Requests",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose a ride to accept",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Ride requests list
            Container(
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.4,
                minHeight: 200,
              ),
              child: _currentRideRequests.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                itemCount: _currentRideRequests.length,
                itemBuilder: (context, index) {
                  final rideRequest = _currentRideRequests[index];
                  return _buildRideRequestCard(rideRequest, context);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Footer instruction
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swipe_left,
                    color: _primaryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Swipe left to dismiss a request",
                    style: TextStyle(
                      fontSize: 14,
                      color: _primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Back button
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: _hideRideSelectionDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryBlue,
                  side: BorderSide(color: _primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text("Back to Single View"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleRequestsIndicator() {
    return GestureDetector(
      onTap: _showRideSelectionDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt_rounded,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              "${_currentRideRequests.length} requests available",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypeIndicator() {
    final isSharedRide = widget.userRideRequestDetails!.rideSharingChoice == "yes";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSharedRide ? Icons.group_rounded : Icons.person_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            isSharedRide
                ? "Shared Ride - ${widget.userRideRequestDetails!.passengerCount} passenger(s)"
                : "Private Ride",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSection(double screenHeight, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(
                Icons.route_rounded,
                color: _primaryBlue,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                "Route Overview",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              height: screenHeight * 0.20,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _lightBlue,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildMapContent(),
              ),
            ),
            if (isPolylineLoaded)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: _cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildZoomButton(Icons.add_rounded, _zoomIn),
                      Container(
                        height: 1,
                        color: _lightBlue,
                      ),
                      _buildZoomButton(Icons.remove_rounded, _zoomOut),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    if (!isPolylineLoaded) {
      return Container(
        color: _lightBlue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(_primaryBlue),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Loading Route...",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Please wait while we prepare your route",
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.userRideRequestDetails!.originLatLng ?? const LatLng(0, 0),
        zoom: 12,
      ),
      polylines: setOfPolyline,
      markers: _buildMapMarkers(),
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      myLocationButtonEnabled: false,
      onMapCreated: (GoogleMapController controller) {
        mapController = controller;
        _fitMapBounds();
      },
    );
  }

  Set<Marker> _buildMapMarkers() {
    return {
      Marker(
        markerId: const MarkerId("origin"),
        position: widget.userRideRequestDetails!.originLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: "Pickup Location",
          snippet: widget.userRideRequestDetails!.originAddress,
        ),
        zIndex: 2,
      ),
      Marker(
        markerId: const MarkerId("destination"),
        position: widget.userRideRequestDetails!.destinationLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: "Dropoff Location",
          snippet: widget.userRideRequestDetails!.destinationAddress,
        ),
        zIndex: 1,
      ),
    };
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onPressed) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          width: 36,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: _primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildAddressesSection(double screenWidth, double screenHeight) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _lightBlue,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _accentBlue.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _buildAddressRow(
            Icons.near_me_rounded,
            "Pickup",
            widget.userRideRequestDetails!.originAddress!,
            Colors.green,
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: _accentBlue.withOpacity(0.2),
          ),
          const SizedBox(height: 8),
          _buildAddressRow(
            Icons.location_on_rounded,
            "Dropoff",
            widget.userRideRequestDetails!.destinationAddress!,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(IconData icon, String title, String address, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: iconColor.withOpacity(0.3),
            ),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: TextStyle(
                  fontSize: 13,
                  color: _textSecondary,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(double screenWidth, double screenHeight) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            "Decline",
            _warningRed,
            Icons.close_rounded,
            _cancelRideRequest,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            _currentRideRequests.length > 1 ? "View All" : "Accept",
            _currentRideRequests.length > 1 ? _primaryBlue : _successGreen,
            _currentRideRequests.length > 1 ? Icons.list_alt_rounded : Icons.check_rounded,
            _currentRideRequests.length > 1 ? _showRideSelectionDialog : () => acceptRideRequest(context),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, Color color, IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(
              text.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ride Selection Components
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_transportation,
              color: _primaryBlue,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No Pending Requests",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "New ride requests will appear here",
            style: TextStyle(
              fontSize: 14,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideRequestCard(UserRideRequestInformation rideRequest, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Dismissible(
      key: Key(rideRequest.rideRequestId!),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.delete_rounded,
              color: Colors.white,
              size: screenWidth * 0.06,
            ),
            const SizedBox(width: 8),
            Text(
              "Dismiss",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildDismissConfirmationDialog();
          },
        );
      },
      onDismissed: (direction) {
        _removeRideRequest(rideRequest);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: _cardColor,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryBlue, _darkBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
            title: Text(
              rideRequest.userName ?? "Passenger",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: screenWidth * 0.04,
                color: _textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                _buildLocationRow(
                  Icons.near_me,
                  "From: ${rideRequest.originAddress?.split(',').first ?? 'Unknown'}",
                ),
                const SizedBox(height: 2),
                _buildLocationRow(
                  Icons.location_on,
                  "To: ${rideRequest.destinationAddress?.split(',').first ?? 'Unknown'}",
                ),
                if (rideRequest.rideSharingChoice == "yes") ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _lightBlue,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _accentBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          color: _primaryBlue,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Shared Ride - ${rideRequest.passengerCount} passenger(s)",
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: _primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isProcessingSelection ? Colors.grey.shade300 : _lightBlue,
                shape: BoxShape.circle,
              ),
              child: _isProcessingSelection
                  ? CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(_primaryBlue),
              )
                  : Icon(
                Icons.arrow_forward_ios_rounded,
                size: screenWidth * 0.035,
                color: _primaryBlue,
              ),
            ),
            onTap: _isProcessingSelection
                ? null
                : () {
              _handleRideSelection(rideRequest);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: _textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildDismissConfirmationDialog() {
    return Dialog(
      backgroundColor: _cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Dismiss Ride Request?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Are you sure you want to dismiss this ride request?",
              style: TextStyle(
                fontSize: 14,
                color: _textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSecondary,
                      side: BorderSide(color: _textSecondary.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    child: Text("Dismiss"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _fitMapBounds() {
    if (widget.userRideRequestDetails!.originLatLng != null &&
        widget.userRideRequestDetails!.destinationLatLng != null) {

      final bounds = LatLngBounds(
        southwest: LatLng(
          widget.userRideRequestDetails!.originLatLng!.latitude < widget.userRideRequestDetails!.destinationLatLng!.latitude
              ? widget.userRideRequestDetails!.originLatLng!.latitude
              : widget.userRideRequestDetails!.destinationLatLng!.latitude,
          widget.userRideRequestDetails!.originLatLng!.longitude < widget.userRideRequestDetails!.destinationLatLng!.longitude
              ? widget.userRideRequestDetails!.originLatLng!.longitude
              : widget.userRideRequestDetails!.destinationLatLng!.longitude,
        ),
        northeast: LatLng(
          widget.userRideRequestDetails!.originLatLng!.latitude > widget.userRideRequestDetails!.destinationLatLng!.latitude
              ? widget.userRideRequestDetails!.originLatLng!.latitude
              : widget.userRideRequestDetails!.destinationLatLng!.latitude,
          widget.userRideRequestDetails!.originLatLng!.longitude > widget.userRideRequestDetails!.destinationLatLng!.longitude
              ? widget.userRideRequestDetails!.originLatLng!.longitude
              : widget.userRideRequestDetails!.destinationLatLng!.longitude,
        ),
      );

      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }
  }

  void _cancelRideRequest() {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .update({
      "status": "cancelled",
      "cancelled_by": "driver",
      "cancelled_at": ServerValue.timestamp,
      "cancellation_reason": "Driver declined the ride request",
      "cancellation_notified": true,  // ADD THIS FLAG
    }).then((value) {
      FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .child("newRideStatus")
          .set("idle");
    }).then((value) {
      FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .child("tripsHistory")
          .child(widget.userRideRequestDetails!.rideRequestId!)
          .remove();
    }).then((value) {
      // Send cancellation notification to commuter
      _sendCancellationNotificationToCommuter();

      Fluttertoast.showToast(
        msg: "Ride Request has been Declined.",
        backgroundColor: _darkBlue,
        textColor: Colors.white,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => MainScreen()),
            (route) => false,
      );
    });
  }

// Add this method to send notification to commuter
  Future<void> _sendCancellationNotificationToCommuter() async {
    try {
      // Get commuter's device token from user data
      DatabaseReference userRef = FirebaseDatabase.instance.ref()
          .child("users")
          .child(widget.userRideRequestDetails!.userPhone!)
          .child("token");

      DataSnapshot tokenSnapshot = await userRef.get();

      if (tokenSnapshot.value != null) {
        String deviceToken = tokenSnapshot.value.toString();

        // Send FCM notification
        final accessToken = await AssistantMethods.getAccessToken();

        if (accessToken.isNotEmpty) {
          final url = "https://fcm.googleapis.com/v1/projects/kaltrikedriverapp/messages:send";

          final headers = {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          };

          final body = {
            "message": {
              "token": deviceToken,
              "notification": {
                "title": "Ride Cancelled",
                "body": "Driver has declined your ride request"
              },
              "data": {
                "rideRequestId": widget.userRideRequestDetails!.rideRequestId!,
                "status": "cancelled",
                "cancelled_by": "driver",
                "action": "ride_cancelled",
              }
            }
          };

          await http.post(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode(body),
          );
        }
      }
    } catch (error) {
      print("Error sending cancellation notification to commuter: $error");
    }
  }

  acceptRideRequest(BuildContext context) {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .once()
        .then((snap) {
      if(snap.snapshot.value != null) {
        String driverName = onlineDriverData.name ?? "Driver";
        String driverPhone = onlineDriverData.phone ?? "Not available";

        String driverVehicleDetails = "";
        if (onlineDriverData.vehicle_model != null && onlineDriverData.plate_number != null) {
          driverVehicleDetails = "${onlineDriverData.vehicle_model} (${onlineDriverData.plate_number})";
        } else if (onlineDriverData.vehicle_model != null) {
          driverVehicleDetails = onlineDriverData.vehicle_model!;
        } else if (onlineDriverData.plate_number != null) {
          driverVehicleDetails = onlineDriverData.plate_number!;
        } else {
          driverVehicleDetails = "Vehicle not specified";
        }

        if (onlineDriverData.vehicle_color != null) {
          driverVehicleDetails += " - ${onlineDriverData.vehicle_color}";
        }

        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("newRideStatus")
            .set("accepted");

        FirebaseDatabase.instance.ref()
            .child("All Ride Requests")
            .child(widget.userRideRequestDetails!.rideRequestId!)
            .update({
          "status": "accepted",
          "driverId": currentFirebaseUser!.uid,
          "driverName": driverName,
          "driverPhone": driverPhone,
          "vehicle_details": driverVehicleDetails,
          "accepted_at": ServerValue.timestamp,
        }).then((value) async {
          await _cancelOtherPendingRideRequests();
          Navigator.push(context, MaterialPageRoute(builder: (c)=> NewTripScreen(
            userRideRequestDetails: widget.userRideRequestDetails,
          )));
        });
      } else {
        Fluttertoast.showToast(
          msg: "This ride request do not exists.",
          backgroundColor: _warningRed,
          textColor: Colors.white,
        );
      }
    });
  }

  Future<void> _cancelOtherPendingRideRequests() async {
    try {
      if (widget.allPendingRequests == null || widget.allPendingRequests!.isEmpty) {
        print("No other pending requests to cancel");
        return;
      }

      int cancelledCount = 0;

      for (final pendingRequest in widget.allPendingRequests!) {
        if (pendingRequest.rideRequestId == widget.userRideRequestDetails!.rideRequestId) {
          continue;
        }

        try {
          await FirebaseDatabase.instance.ref()
              .child("All Ride Requests")
              .child(pendingRequest.rideRequestId!)
              .update({
            "status": "cancelled",
            "cancellation_reason": "Driver selected another ride request",
            "cancelled_at": ServerValue.timestamp,
            "cancelled_by": "system",
          });

          cancelledCount++;
          print("Cancelled ride request: ${pendingRequest.rideRequestId}");

          await _sendCancellationNotification(pendingRequest);

        } catch (error) {
          print("Error cancelling ride request ${pendingRequest.rideRequestId}: $error");
        }
      }

      print("Successfully cancelled $cancelledCount other ride requests");
      await _cleanUpOtherPendingRequests();

    } catch (error) {
      print("Error in _cancelOtherPendingRideRequests: $error");
    }
  }

  Future<void> _cleanUpOtherPendingRequests() async {
    try {
      DatabaseReference rideRequestsRef = FirebaseDatabase.instance.ref().child("All Ride Requests");

      DataSnapshot snapshot = await rideRequestsRef.get();

      if (snapshot.value != null) {
        Map<dynamic, dynamic> allRideRequests = snapshot.value as Map<dynamic, dynamic>;
        int cleanedCount = 0;

        for (var rideRequestId in allRideRequests.keys) {
          if (rideRequestId == widget.userRideRequestDetails!.rideRequestId) {
            continue;
          }

          var rideRequestData = allRideRequests[rideRequestId] as Map<dynamic, dynamic>;
          String status = rideRequestData["status"]?.toString() ?? "pending";
          String? driverId = rideRequestData["driverId"]?.toString();

          if (status == "pending" && (driverId == null || driverId.isEmpty)) {
            String? timeString = rideRequestData["time"]?.toString();
            if (timeString != null) {
              DateTime requestTime = DateTime.parse(timeString);
              DateTime currentTime = DateTime.now();
              Duration difference = currentTime.difference(requestTime);

              if (difference.inMinutes <= 5) {
                await rideRequestsRef.child(rideRequestId.toString()).update({
                  "status": "cancelled",
                  "cancellation_reason": "No available drivers",
                  "cancelled_at": ServerValue.timestamp,
                  "cancelled_by": "system",
                });
                cleanedCount++;
              }
            }
          }
        }

        print("Cleaned up $cleanedCount additional pending requests");
      }
    } catch (error) {
      print("Error in _cleanUpOtherPendingRequests: $error");
    }
  }

  Future<void> _sendCancellationNotification(UserRideRequestInformation cancelledRequest) async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance.ref()
          .child("users")
          .child(cancelledRequest.userPhone!)
          .child("token");

      DataSnapshot tokenSnapshot = await userRef.get();

      if (tokenSnapshot.value != null) {
        String deviceToken = tokenSnapshot.value.toString();

        Map<String, String> notificationPayload = {
          "title": "Ride Cancelled",
          "body": "Sorry, your ride request has been cancelled as the driver selected another ride.",
          "rideRequestId": cancelledRequest.rideRequestId!,
          "type": "ride_cancelled"
        };

        print("Sent cancellation notification to commuter for ride: ${cancelledRequest.rideRequestId}");
      }
    } catch (error) {
      print("Error sending cancellation notification: $error");
    }
  }
}