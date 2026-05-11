import 'dart:async';
import 'dart:ui';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:kaltrike_driver_app/src/features/commuter/services/assistant_methods.dart';
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart';
import 'package:kaltrike_driver_app/src/shared/models/directions.dart';

class PrecisePickupScreen extends StatefulWidget {
  const PrecisePickupScreen({super.key});

  @override
  State<PrecisePickupScreen> createState() => _PrecisePickupScreenState();
}

class _PrecisePickupScreenState extends State<PrecisePickupScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  Position? userCurrentPosition;
  double bottomPaddingOfMap = 0;

  LatLng? tappedLocation;
  String tappedAddress = "Tap anywhere on the map to set pickup location";
  bool _isLoading = false;

  // Modern blue color palette (consistent with previous screen)
  final Color _primaryBlue = Color(0xFF2196F3);
  final Color _darkBlue = Color(0xFF1976D2);
  final Color _lightBlue = Color(0xFFBBDEFB);
  final Color _accentBlue = Color(0xFF448AFF);
  final Color _backgroundColor = Color(0xFFF8FBFF);
  final Color _successGreen = Color(0xFF4CAF50);

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(17.411735, 121.43845),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Set Pickup Location',
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
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: false,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              setState(() {
                bottomPaddingOfMap = 200;
              });

              locateUserPosition();
            },
            onTap: (LatLng tappedPoint) {
              _handleMapTap(tappedPoint);
            },
            markers: tappedLocation != null
                ? {
              Marker(
                markerId: const MarkerId("tappedLocation"),
                position: tappedLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                infoWindow: InfoWindow(
                  title: 'Pickup Location',
                  snippet: tappedAddress,
                ),
              ),
            }
                : {},
          ),

          // Modern Address Card
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: _buildAddressCard(),
          ),

          // Modern Confirm Button
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
            color: _primaryBlue.withOpacity(0.15),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: _lightBlue,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _lightBlue.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: _primaryBlue,
              size: 22,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PICKUP LOCATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  tappedAddress,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return AnimatedOpacity(
      opacity: tappedLocation != null ? 1.0 : 0.6,
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primaryBlue.withOpacity(tappedLocation != null ? 0.3 : 0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: tappedLocation != null ? confirmPickUp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: tappedLocation != null ? _primaryBlue : Colors.grey[400],
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
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
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'SET PICKUP LOCATION',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> locateUserPosition() async {
    try {
      setState(() {
        _isLoading = true;
      });

      Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      userCurrentPosition = cPosition;

      LatLng latLngPosition =
      LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      CameraPosition cameraPosition =
      CameraPosition(target: latLngPosition, zoom: 16);

      newGoogleMapController!
          .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

      await updatePickUpAddress(latLngPosition);

    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error getting your location",
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
        tappedLocation = tappedPoint;
      });

      await updatePickUpAddress(tappedPoint);

      // Animate camera to tapped location
      newGoogleMapController?.animateCamera(
        CameraUpdate.newLatLng(tappedPoint),
      );

    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to get address details",
        backgroundColor: Colors.red[800],
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> updatePickUpAddress(LatLng latLng) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        String humanReadableAddress =
            "${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}";

        // Clean up any trailing commas
        humanReadableAddress = humanReadableAddress.replaceAll(RegExp(r',\s*$'), '');

        setState(() {
          tappedAddress = humanReadableAddress.isNotEmpty
              ? humanReadableAddress
              : "Selected location";
        });

        Directions userPickUpAddress = Directions();
        userPickUpAddress.locationLatitude = latLng.latitude;
        userPickUpAddress.locationLongitude = latLng.longitude;
        userPickUpAddress.locationName = humanReadableAddress;

        Provider.of<AppInfo>(context, listen: false)
            .updatePickUpLocationAddress(userPickUpAddress);
      }
    } catch (e) {
      setState(() {
        tappedAddress = "Selected location (address unavailable)";
      });
    }
  }

  void confirmPickUp() {
    if (tappedLocation != null) {
      Fluttertoast.showToast(
        msg: "Pickup location set successfully!",
        backgroundColor: _successGreen,
        textColor: Colors.white,
        toastLength: Toast.LENGTH_LONG,
      );
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: "Please tap a location on the map first",
        backgroundColor: Colors.orange[800],
        textColor: Colors.white,
      );
    }
  }
}