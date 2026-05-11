import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart';
import 'package:kaltrike_driver_app/src/shared/models/directions.dart';

class TapDestinationScreen extends StatefulWidget {
  @override
  _TapDestinationScreenState createState() => _TapDestinationScreenState();
}

class _TapDestinationScreenState extends State<TapDestinationScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(17.411735, 121.43845),
    zoom: 14.4746,
  );

  LatLng? _selectedLocation;
  String _selectedAddress = "Tap anywhere on the map to select your destination";
  Set<Marker> _markers = {};
  bool _isLoading = false;

  // Modern blue color palette
  final Color _primaryBlue = Color(0xFF2196F3);
  final Color _darkBlue = Color(0xFF1976D2);
  final Color _lightBlue = Color(0xFFBBDEFB);
  final Color _accentBlue = Color(0xFF448AFF);
  final Color _backgroundColor = Color(0xFFF8FBFF);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500), () {
      _goToCurrentLocation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Select Destination',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 2,
        shadowColor: _primaryBlue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: _kInitialPosition,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
            },
            onTap: _handleMapTap,
          ),

          // Address Card
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildAddressCard(),
          ),

          // Current Location FAB
          Positioned(
            bottom: 100,
            right: 20,
            child: _buildLocationFab(),
          ),

          // Confirm Button
          if (_selectedLocation != null)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: _buildConfirmButton(),
            ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                  strokeWidth: 3,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: _lightBlue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedAddress,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _goToCurrentLocation,
        backgroundColor: Colors.white,
        foregroundColor: _primaryBlue,
        elevation: 0,
        child: Icon(
          Icons.my_location_rounded,
          size: 24,
        ),
        tooltip: 'Current Location',
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _confirmSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_rounded,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'CONFIRM DESTINATION',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    try {
      setState(() {
        _isLoading = true;
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(
          msg: "Please enable location services",
          backgroundColor: Colors.red[800],
          textColor: Colors.white,
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(
            msg: "Location permission denied",
            backgroundColor: Colors.red[800],
            textColor: Colors.white,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
          msg: "Location permission permanently denied",
          backgroundColor: Colors.red[800],
          textColor: Colors.white,
        );
        return;
      }

      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      LatLng currentLatLng = LatLng(currentPosition.latitude, currentPosition.longitude);

      newGoogleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 16),
      );

    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error getting current location",
        backgroundColor: Colors.red[800],
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleMapTap(LatLng tappedPoint) async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Placemark> placemarks = await placemarkFromCoordinates(
        tappedPoint.latitude,
        tappedPoint.longitude,
      );

      String address = "Selected location";
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final parts = <String>[
          ?placemark.name,
          ?placemark.street,
          ?placemark.subLocality,
          ?placemark.locality,
          ?placemark.administrativeArea,
        ].where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString().trim()).toSet().toList();
        if (parts.isNotEmpty) {
          address = parts.join(', ');
        }
      }

      if (address == "Selected location") {
        address = "${tappedPoint.latitude.toStringAsFixed(6)}, ${tappedPoint.longitude.toStringAsFixed(6)}";
      }

      setState(() {
        _selectedLocation = tappedPoint;
        _selectedAddress = address;

        _markers = {
          Marker(
            markerId: MarkerId('selected_destination'),
            position: tappedPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'Selected Destination',
              snippet: address,
            ),
          ),
        };
      });

      newGoogleMapController?.animateCamera(
        CameraUpdate.newLatLng(tappedPoint),
      );

    } catch (e) {
      setState(() {
        _selectedAddress = "Failed to get address details";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedLocation == null) return;

    var dropOffLocation = Directions(
        locationName: _selectedAddress,
        locationLatitude: _selectedLocation!.latitude,
        locationLongitude: _selectedLocation!.longitude,
        locationId: "tapped_destination_${DateTime.now().millisecondsSinceEpoch}"
    );

    Provider.of<AppInfo>(context, listen: false).updateDropOffLocationAddress(dropOffLocation);

    // Show success feedback
    Fluttertoast.showToast(
      msg: "Destination set successfully!",
      backgroundColor: _primaryBlue,
      textColor: Colors.white,
    );

    Navigator.pop(context, "destinationSelected");
  }
}