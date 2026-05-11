import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/models/user_ride_request_information.dart';
import 'package:kaltrike_driver_app/src/core/services/local_notification_service.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/widgets/notification_dialog_box.dart';

class PushNotificationSystem
{
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  List<UserRideRequestInformation> pendingRideRequests = [];
  bool isDialogShowing = false;
  BuildContext? _currentContext;
  bool _isRefreshingDialog = false;
  StreamSubscription<DatabaseEvent>? _rideStatusSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastRealtimeRideRequestId;
  DateTime? _lastRealtimeRideRequestAt;

  Future initializeCloudMessaging(BuildContext context) async
  {
    _currentContext = context;
    await _startRealtimeRideRequestListener();
    _listenForTokenRefresh();

    //1. Terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? remoteMessage)
    {
      if(remoteMessage != null)
      {
        readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
      }
    });

    //2. Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
      if (remoteMessage != null) {
        // Show local notification
        LocalNotificationService.showNotification(
          title: remoteMessage.notification?.title ?? "New Ride Request",
          body: remoteMessage.notification?.body ?? "Tap to view details",
          payload: remoteMessage.data["rideRequestId"],
        );

        // Process the ride request
        readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
      }
    });

    //3. Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage)
    {
      if(remoteMessage != null)
      {
        readUserRideRequestInformation(remoteMessage.data["rideRequestId"], context);
      }
    });
  }

  Future<void> _startRealtimeRideRequestListener() async {
    if (currentFirebaseUser == null) {
      return;
    }

    await _rideStatusSubscription?.cancel();

    final rideStatusRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus");

    _rideStatusSubscription = rideStatusRef.onValue.listen((event) {
      final rideRequestId = event.snapshot.value?.toString();

      if (rideRequestId == null ||
          rideRequestId.isEmpty ||
          rideRequestId == "idle" ||
          rideRequestId == "accepted") {
        return;
      }

      final now = DateTime.now();
      if (_lastRealtimeRideRequestId == rideRequestId &&
          _lastRealtimeRideRequestAt != null &&
          now.difference(_lastRealtimeRideRequestAt!) < const Duration(seconds: 2)) {
        return;
      }

      _lastRealtimeRideRequestId = rideRequestId;
      _lastRealtimeRideRequestAt = now;

      if (_currentContext != null) {
        print("⚡ [DRIVER] Realtime ride signal received: $rideRequestId");
        readUserRideRequestInformation(rideRequestId, _currentContext!);
      }
    });
  }

  void _listenForTokenRefresh() {
    _tokenRefreshSubscription ??= messaging.onTokenRefresh.listen((newToken) {
      if (currentFirebaseUser == null || newToken.isEmpty) {
        return;
      }

      FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .child("token")
          .set(newToken);
    });
  }

  void readUserRideRequestInformation(String userRideRequestId, BuildContext context)
  {
    _currentContext = context;

    // Check if this ride request is already in the pending list to prevent duplicates
    bool isAlreadyInList = pendingRideRequests.any((request) => request.rideRequestId == userRideRequestId);

    if (isAlreadyInList) {
      print("Ride request $userRideRequestId is already in pending list - skipping duplicate");
      return; // Skip if already exists
    }

    // First, check if this ride request still exists in Firebase
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(userRideRequestId)
        .once()
        .then((snapData)
    {
      if(snapData.snapshot.value != null)
      {
        double originLat = double.parse((snapData.snapshot.value! as Map)["origin"]["latitude"]);
        double originLng = double.parse((snapData.snapshot.value! as Map)["origin"]["longitude"]);
        String originAddress = (snapData.snapshot.value! as Map)["originAddress"];

        double destinationLat = double.parse((snapData.snapshot.value! as Map)["destination"]["latitude"]);
        double destinationLng = double.parse((snapData.snapshot.value! as Map)["destination"]["longitude"]);
        String destinationAddress = (snapData.snapshot.value! as Map)["destinationAddress"];

        String userName = (snapData.snapshot.value! as Map)["userName"];
        String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

        // Read ride sharing information
        String rideSharingChoice = (snapData.snapshot.value! as Map)["rideSharing"] ?? "no";
        String passengerCount = (snapData.snapshot.value! as Map)["passengerCount"] ?? "1";

        String? rideRequestId = snapData.snapshot.key;

        // Double-check for duplicates (in case of race condition)
        bool isStillDuplicate = pendingRideRequests.any((request) => request.rideRequestId == rideRequestId);
        if (isStillDuplicate) {
          print("Ride request $rideRequestId is still duplicate - skipping");
          return;
        }

        UserRideRequestInformation userRideRequestDetails = UserRideRequestInformation();

        userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
        userRideRequestDetails.originAddress = originAddress;

        userRideRequestDetails.destinationLatLng = LatLng(destinationLat, destinationLng);
        userRideRequestDetails.destinationAddress = destinationAddress;

        userRideRequestDetails.userName = userName;
        userRideRequestDetails.userPhone = userPhone;

        // Store ride sharing information
        userRideRequestDetails.rideSharingChoice = rideSharingChoice;
        userRideRequestDetails.passengerCount = passengerCount;

        userRideRequestDetails.rideRequestId = rideRequestId;

        // Add to pending requests list
        pendingRideRequests.add(userRideRequestDetails);
        print("Added ride request $rideRequestId to pending list. Total: ${pendingRideRequests.length}");

        // Show the notification dialog if not already showing
        if (!isDialogShowing) {
          showNotificationDialog(context);
        } else {
          // If dialog is already showing, just update the state - don't close and reopen
          _refreshCurrentDialog();
        }
      }
      else
      {
        // If ride request doesn't exist in Firebase, remove it from pending list if it's there
        pendingRideRequests.removeWhere((request) => request.rideRequestId == userRideRequestId);
        Fluttertoast.showToast(msg: "This Ride Request Id do not exists.");
      }
    });
  }

  void _refreshCurrentDialog() {
    // Instead of closing and reopening, we can trigger a state update in the current dialog
    // This prevents the duplication issue
    if (_currentContext != null && isDialogShowing) {
      // This will trigger a rebuild of the current dialog with updated data
      showNotificationDialog(_currentContext!);
    }
  }

  void showNotificationDialog(BuildContext context) {
    _currentContext = context;

    // Prevent multiple dialogs during refresh
    if (_isRefreshingDialog) {
      return;
    }

    // If we're already showing a dialog and this is a refresh, close the current one first
    if (isDialogShowing) {
      Navigator.of(context).pop();
    }

    // Check if we still have pending requests (might have been cleared)
    if (pendingRideRequests.isEmpty) {
      isDialogShowing = false;
      _isRefreshingDialog = false;
      return;
    }

    isDialogShowing = true;
    _isRefreshingDialog = false;

    // Determine which ride request to show initially
    UserRideRequestInformation? initialRideRequest;
    if (pendingRideRequests.isNotEmpty) {
      // Show the most recent ride request as the initial one
      initialRideRequest = pendingRideRequests.last;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => NotificationDialogBox(
        userRideRequestDetails: initialRideRequest,
        allPendingRequests: pendingRideRequests,
      ),
    ).then((value) {
      // This runs when dialog is dismissed by any means
      isDialogShowing = false;
      _isRefreshingDialog = false;
    });
  }

  void handleRideAccepted(UserRideRequestInformation acceptedRide) {
    // Clear all pending requests and notifications when a ride is accepted
    pendingRideRequests.clear();
    LocalNotificationService.clearAllRideNotifications();

    // Dialog will be closed by the NotificationDialogBox itself when navigating to NewTripScreen
  }

  void handleRideDismissed(UserRideRequestInformation dismissedRide) {
    // Remove only the dismissed ride from pending requests
    pendingRideRequests.removeWhere((request) => request.rideRequestId == dismissedRide.rideRequestId);

    // Cancel the specific ride request in database
    cancelRideRequest(dismissedRide.rideRequestId!);

    // If no more requests, close dialog
    if (pendingRideRequests.isEmpty) {
      isDialogShowing = false;
      if (_currentContext != null) {
        Navigator.of(_currentContext!).pop();
      }
    } else {
      // Instead of closing and reopening, just refresh the current dialog
      _isRefreshingDialog = true;
      _refreshCurrentDialog();
    }
  }

  void cancelRideRequest(String rideRequestId) {
    FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(rideRequestId)
        .remove()
        .then((value) {
      print("Ride request $rideRequestId cancelled from database");
    }).catchError((error) {
      print("Error cancelling ride request: $error");
    });
  }

  void checkAndCleanPendingRequests() {
    if (pendingRideRequests.isNotEmpty) {
      _cleanUpPendingRequests().then((_) {
        if (pendingRideRequests.isEmpty && isDialogShowing && _currentContext != null) {
          try {
            Navigator.of(_currentContext!).pop();
          } catch (e) {
            // Ignore if no dialog to pop
          }
          isDialogShowing = false;
        } else if (pendingRideRequests.isNotEmpty && !isDialogShowing && _currentContext != null) {
          showNotificationDialog(_currentContext!);
        }
      });
    }
  }

  Future<void> _cleanUpPendingRequests() async {
    List<String> requestsToRemove = [];

    // Check each pending request's current status in Firebase
    for (final request in pendingRideRequests) {
      if (request.rideRequestId == null) {
        continue;
      }

      try {
        final snapshot = await FirebaseDatabase.instance.ref()
            .child("All Ride Requests")
            .child(request.rideRequestId!)
            .once();

        if (snapshot.snapshot.value == null) {
          // Ride request no longer exists
          requestsToRemove.add(request.rideRequestId!);
          continue;
        }

        final rideData = snapshot.snapshot.value as Map;
        String status = rideData["status"] ?? "pending";
        String? assignedDriverId = rideData["driverId"];

        // Only remove if ride is completed, cancelled, or assigned to another driver
        if (status == "completed" || status == "cancelled" ||
            (assignedDriverId != null && assignedDriverId.isNotEmpty && assignedDriverId != currentFirebaseUser!.uid)) {
          requestsToRemove.add(request.rideRequestId!);
        }
      } catch (error) {
        print("Error checking ride request ${request.rideRequestId}: $error");
      }
    }

    // Remove invalid requests
    if (requestsToRemove.isNotEmpty) {
      pendingRideRequests.removeWhere((request) => requestsToRemove.contains(request.rideRequestId));
      print("Cleaned up ${requestsToRemove.length} invalid ride requests");
    }
  }

  // Add this method to manually clear pending requests if needed
  void clearPendingRideRequests() {
    pendingRideRequests.clear();
    isDialogShowing = false;
    _isRefreshingDialog = false;
  }

  void onReturnToHomeTab() {
    _cleanUpPendingRequests().then((_) {
      print("Home tab cleanup completed. Pending requests: ${pendingRideRequests.length}");
    });
  }

  Future generateAndGetToken() async
  {
    String? registrationToken = await messaging.getToken();
    print("FCM Registration Token: ");
    print(registrationToken);

    if (registrationToken != null && registrationToken.isNotEmpty) {
      FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .child("token")
          .set(registrationToken);
    }

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }

  Future<void> disposeListeners() async {
    await _rideStatusSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}