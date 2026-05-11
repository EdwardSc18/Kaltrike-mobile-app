import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kaltrike_driver_app/src/core/config/fare_config.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/main_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaltrike_driver_app/src/features/driver/services/assistant_methods.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/models/user_ride_request_information.dart';
import 'package:kaltrike_driver_app/src/shared/models/chat_message.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/widgets/fare_amount_collection_dialog.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/widgets/progress_dialog.dart';

class WaitingForPaymentDialog extends StatefulWidget {
  final double totalFareAmount;

  const WaitingForPaymentDialog({super.key, required this.totalFareAmount});

  @override
  State<WaitingForPaymentDialog> createState() => _WaitingForPaymentDialogState();
}

class _WaitingForPaymentDialogState extends State<WaitingForPaymentDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Color(0xFFF59E0B),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Payment in progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFF59E0B),
                  letterSpacing: 0.3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Waiting for commuter payment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Please wait while the commuter confirms the fare payment before you collect the cash.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    'Expected cash to collect',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₱${widget.totalFareAmount.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Listening for payment confirmation...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class NewTripScreen extends StatefulWidget {

  UserRideRequestInformation? userRideRequestDetails;

  NewTripScreen({
    this.userRideRequestDetails,
  });

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  GoogleMapController? newTripGoogleMapController;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(17.411735, 121.43845),
    zoom: 14.4746,
  );

  String? buttonTitle = "Arrived";
  Color? buttonColor = Color(0xFF10B981);
  String statusBtn = "accepted";

  Set<Marker> setOfMarkers = Set<Marker>();
  Set<Circle> setOfCircle = Set<Circle>();
  Set<Polyline> setOfPolyline = Set<Polyline>();
  List<LatLng> polyLinePositionCoordinates = [];
  PolylinePoints polylinePoints = PolylinePoints(apiKey: '');

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocator = Geolocator();
  Position? onlineDriverCurrentPosition;

  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "";
  bool isRequestDirectionDetails = false;

  // Chat functionality variables
  bool _isChatOpen = false;
  bool _isChatMinimized = false;
  double _chatHeight = 300.0;
  double _chatWidth = 320.0;
  double _minChatHeight = 200.0;
  double _maxChatHeight = 500.0;
  double _minChatWidth = 280.0;
  double _maxChatWidth = 400.0;
  Offset _chatPosition = Offset(16, 100);

  DateTime? _lastPolylineRefreshAt;
  LatLng? _lastPolylineOrigin;
  DateTime? _lastDurationRefreshAt;
  DateTime? _lastFollowCameraAt;
  LatLng? _lastFollowCameraTarget;
  List<ChatMessage> _chatMessages = [];
  TextEditingController _messageController = TextEditingController();
  StreamSubscription<DatabaseEvent>? _chatSubscription;
  final ScrollController _chatScrollController = ScrollController();
  FocusNode _chatFocusNode = FocusNode();

  // FIXED: Improved map orientation control
  List<LatLng> driverPositionHistory = [];
  Timer? _routeUpdateTimer;
  LatLng? _currentDestination;
  bool _isMapFlipped = false;
  bool _isManualControl = false;
  LatLng? _manualTarget;
  double? _manualBearing;
  double? _manualZoom;

  static const double _destinationUnlockRadiusMeters = 100.0;
  double? _distanceToActiveTargetMeters;
  bool _isRefreshingPolyline = false;

  @override
  void initState() {
    super.initState();
    onlineDriverCurrentPosition = driverCurrentPosition;
    _updateLiveDistanceState(refreshUi: false);
    saveAssignedDriverDetailsToUserRideRequest();

    // Start listening for ride cancellations
    _listenForRideCancellation();

    _chatFocusNode.addListener(() {
      if (_chatFocusNode.hasFocus && _isChatOpen) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  // Helper methods for chat
  void _toggleChatMinimize() {
    setState(() {
      _isChatMinimized = !_isChatMinimized;
    });
  }

  bool _hasUnreadMessages() {
    // You can implement logic to track unread messages here
    return false;
  }

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return '';
    }
  }

  @override
  void dispose() {
    _routeUpdateTimer?.cancel();
    streamSubscriptionDriverLivePosition?.cancel();
    _chatSubscription?.cancel();
    _messageController.dispose();
    _chatScrollController.dispose();
    _chatFocusNode.dispose();
    super.dispose();
  }

  // FIXED: Improved camera control with manual override
  void _updateCameraPosition(LatLng target, {double? bearing, double? zoom, bool isManual = false}) {
    if (newTripGoogleMapController == null) return;

    if (isManual) {
      _isManualControl = true;
      _manualTarget = target;
      _manualBearing = bearing;
      _manualZoom = zoom ?? 14;
    }

    CameraPosition cameraPosition = CameraPosition(
      target: target,
      zoom: zoom ?? 14,
      bearing: bearing ?? 0,
      tilt: isManual ? 45 : 0,
    );

    newTripGoogleMapController!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  }

  // FIXED: Improved flip function that maintains orientation
  void _flipMapOrientation() {
    if (newTripGoogleMapController == null) return;

    setState(() {
      _isMapFlipped = !_isMapFlipped;
    });

    LatLng target;
    double bearing;

    if (_isMapFlipped) {
      target = widget.userRideRequestDetails!.destinationLatLng!;
      bearing = _calculateBearing(
        onlineDriverCurrentPosition != null
            ? LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude)
            : widget.userRideRequestDetails!.originLatLng!,
        target,
      );
    } else {
      target = widget.userRideRequestDetails!.originLatLng!;
      bearing = _calculateBearing(
        onlineDriverCurrentPosition != null
            ? LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude)
            : target,
        target,
      );
    }

    _updateCameraPosition(
      target,
      bearing: bearing,
      zoom: 14,
      isManual: true,
    );
  }

  void _resetManualControl() {
    _isManualControl = false;
    _manualTarget = null;
    _manualBearing = null;
    _manualZoom = null;
  }

  void _resetToFollowDriver() {
    _resetManualControl();
    if (onlineDriverCurrentPosition != null) {
      _updateCameraPosition(
        LatLng(onlineDriverCurrentPosition!.latitude, onlineDriverCurrentPosition!.longitude),
        zoom: 16,
      );
    }
  }

  Widget _buildMapControls() {
    return Positioned(
      top: 60,
      right: 16,
      child: Column(
        children: [
          if (_isManualControl)
            Container(
              margin: EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: _resetToFollowDriver,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.my_location,
                  color: Colors.blue,
                ),
                mini: true,
              ),
            ),
          FloatingActionButton(
            onPressed: _flipMapOrientation,
            backgroundColor: Colors.white,
            child: Icon(
              _isMapFlipped ? Icons.navigation : Icons.flag,
              color: _isMapFlipped ? Colors.red : Colors.green,
            ),
            mini: true,
          ),
        ],
      ),
    );
  }

  Widget _buildChatInterface() {
    return Positioned(
      left: _chatPosition.dx,
      top: _chatPosition.dy,
      child: Column(
        children: [
          // Chat Messages Window
          if (_isChatOpen)
            Container(
              width: _chatWidth,
              height: _isChatMinimized ? 40 : _chatHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: _isChatMinimized
                  ? _buildMinimizedChatHeader()
                  : Stack(
                children: [
                  Column(
                    children: [
                      // Resize Handle - for height
                      _buildResizeHandle(),

                      // Chat Header
                      _buildChatHeader(),

                      // Messages List
                      Expanded(
                        child: _buildMessagesList(),
                      ),

                      // Message Input
                      _buildMessageInput(),
                    ],
                  ),

                  // Right side resize handle for width
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _buildWidthResizeHandle(),
                  ),

                  // Bottom right corner resize handle for both dimensions
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _buildCornerResizeHandle(),
                  ),
                ],
              ),
            ),

          // Chat Toggle Button
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _toggleChat,
            backgroundColor: _isChatOpen ? Color(0xFFEF4444) : Color(0xFF2563EB),
            child: Icon(
              _isChatOpen ? Icons.close : Icons.chat,
              color: Colors.white,
              size: 20,
            ),
            mini: true,
          ),
        ],
      ),
    );
  }

  Widget _buildResizeHandle() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _chatHeight = (_chatHeight - details.delta.dy)
              .clamp(_minChatHeight, _maxChatHeight);
        });
      },
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidthResizeHandle() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _chatWidth = (_chatWidth + details.delta.dx)
              .clamp(_minChatWidth, _maxChatWidth);
        });
      },
      child: Container(
        width: 12,
        margin: EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.grey.shade300.withOpacity(0.7),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildCornerResizeHandle() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _chatWidth = (_chatWidth + details.delta.dx)
              .clamp(_minChatWidth, _maxChatWidth);
          _chatHeight = (_chatHeight - details.delta.dy)
              .clamp(_minChatHeight, _maxChatHeight);
        });
      },
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Color(0xFF2563EB).withOpacity(0.7),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Icon(
          Icons.open_with_rounded,
          color: Colors.white,
          size: 12,
        ),
      ),
    );
  }

  Widget _buildMinimizedChatHeader() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _chatPosition = Offset(
            _chatPosition.dx + details.delta.dx,
            _chatPosition.dy + details.delta.dy,
          );
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF2563EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Color(0xFF2563EB),
                size: 14,
              ),
              radius: 12,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chat with ${widget.userRideRequestDetails!.userName!}",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            // Show notification badge if there are unread messages
            if (_hasUnreadMessages())
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.expand_less, color: Colors.white, size: 16),
              onPressed: _toggleChatMinimize,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _chatPosition = Offset(
            _chatPosition.dx + details.delta.dx,
            _chatPosition.dy + details.delta.dy,
          );
        });
      },
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF2563EB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(_isChatMinimized ? 16 : 0),
            topRight: Radius.circular(_isChatMinimized ? 16 : 0),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              radius: 14,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chat with ${widget.userRideRequestDetails!.userName!}",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            // Minimize Button
            IconButton(
              icon: Icon(
                  _isChatMinimized ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 18
              ),
              onPressed: _toggleChatMinimize,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 4),
            // Close Button
            IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 18),
              onPressed: _toggleChat,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return _chatMessages.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.grey.shade400,
            size: 48,
          ),
          SizedBox(height: 8),
          Text(
            "No messages yet",
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4)
        ],
      ),
    )
        : ListView.builder(
      controller: _chatScrollController,
      padding: EdgeInsets.all(12),
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        ChatMessage message = _chatMessages[index];
        bool isDriver = message.senderId == currentFirebaseUser!.uid;

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isDriver
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isDriver)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF8B5CF6),
                  child: Text(
                    message.senderName!.substring(0, 1),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: _chatWidth * 0.7,
                  ),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDriver
                        ? Color(0xFF2563EB)
                        : Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isDriver)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text(
                            message.senderName!,
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Text(
                        message.message!,
                        style: TextStyle(
                          color: isDriver
                              ? Colors.white
                              : Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _formatMessageTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDriver
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDriver)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF10B981),
                  child: Text(
                    "D",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _chatFocusNode,
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF2563EB),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  LatLng? _getActiveTargetLatLng() {
    if (rideRequestStatus == "accepted") {
      return widget.userRideRequestDetails!.originLatLng;
    }
    if (rideRequestStatus == "arrived" || rideRequestStatus == "ontrip") {
      return widget.userRideRequestDetails!.destinationLatLng;
    }
    return null;
  }

  void _updateLiveDistanceState({bool refreshUi = true}) {
    if (onlineDriverCurrentPosition == null) {
      return;
    }

    final targetLatLng = _getActiveTargetLatLng();
    if (targetLatLng == null) {
      return;
    }

    final distanceMeters = Geolocator.distanceBetween(
      onlineDriverCurrentPosition!.latitude,
      onlineDriverCurrentPosition!.longitude,
      targetLatLng.latitude,
      targetLatLng.longitude,
    );

    if (refreshUi && mounted) {
      setState(() {
        _distanceToActiveTargetMeters = distanceMeters;
      });
    } else {
      _distanceToActiveTargetMeters = distanceMeters;
    }
  }

  String _formatDistanceLabel(double? distanceMeters) {
    if (distanceMeters == null) {
      return "Updating...";
    }

    if (distanceMeters >= 1000) {
      return "${(distanceMeters / 1000).toStringAsFixed(1)} km away";
    }

    return "${distanceMeters.round()} m away";
  }

  String _buildEtaOrDistanceText() {
    if (durationFromOriginToDestination.trim().isNotEmpty) {
      return durationFromOriginToDestination;
    }
    return _formatDistanceLabel(_distanceToActiveTargetMeters);
  }

  String _buildTripActionHint(bool isEndTripEnabled) {
    if (rideRequestStatus != "ontrip") {
      return "";
    }

    if (isEndTripEnabled) {
      return "You are within ${_destinationUnlockRadiusMeters.toInt()} meters of the destination. You can end the trip now.";
    }

    return "Move within ${_destinationUnlockRadiusMeters.toInt()} meters of the destination to unlock End Trip. Current distance: ${_formatDistanceLabel(_distanceToActiveTargetMeters)}.";
  }

  @override
  Widget build(BuildContext context) {
    createDriverIconMarker();
    _updateLiveDistanceState(refreshUi: false);
    bool isEndTripEnabled = rideRequestStatus == "ontrip" && hasReachedDestination();

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircle,
            polylines: setOfPolyline,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;

              setState(() {
                mapPadding = 400;
              });

              onlineDriverCurrentPosition = driverCurrentPosition;
              _updateLiveDistanceState(refreshUi: false);

              var driverCurrentLatLng = LatLng(
                driverCurrentPosition!.latitude,
                driverCurrentPosition!.longitude,
              );

              var userPickUpLatLng = widget.userRideRequestDetails!.originLatLng;

              drawPolyLineFromOriginToDestination(
                driverCurrentLatLng,
                userPickUpLatLng!,
                showLoading: false,
              );
              updateDurationTimeAtRealTime(forceUpdate: true);
              updatePolylineAsDriverMoves();
            },
          ),

          _buildMapControls(),

          _buildChatInterface(),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Color(0xFF8B5CF6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  color: Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.userRideRequestDetails!.userName!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    GestureDetector(
                                      onTap: () async {
                                        String number = widget.userRideRequestDetails!.userPhone!;
                                        await launch("tel:$number");
                                      },
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            color: Color(0xFF2563EB),
                                            size: 14,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            widget.userRideRequestDetails!.userPhone!,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF2563EB),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ETA / Distance",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    _buildEtaOrDistanceText(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1E293B),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 16),

                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.north_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Pickup Location",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      widget.userRideRequestDetails!.originAddress!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E293B),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 16),

                          Container(
                            height: 1,
                            color: Colors.grey.shade200,
                            margin: EdgeInsets.symmetric(horizontal: 20),
                          ),

                          SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.south_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Drop-off Location",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      widget.userRideRequestDetails!.destinationAddress!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF1E293B),
                                        height: 1.3,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    if (rideRequestStatus == "ontrip") ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isEndTripEnabled
                              ? const Color(0xFFECFDF5)
                              : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEndTripEnabled
                                ? const Color(0xFFA7F3D0)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isEndTripEnabled ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              color: isEndTripEnabled ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _buildTripActionHint(isEndTripEnabled),
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                  color: isEndTripEnabled
                                      ? const Color(0xFF047857)
                                      : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14),
                    ],

                    Row(
                      children: [
                        // Cancel Ride Button
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFEF4444).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _cancelRideAfterAcceptance,
                                child: Container(
                                  height: 56,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Cancel Ride",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Main Action Button (Arrived/Start Trip/End Trip)
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: isEndTripEnabled || rideRequestStatus != "ontrip"
                                  ? (rideRequestStatus == "accepted"
                                  ? LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                                  : rideRequestStatus == "arrived"
                                  ? LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)])
                                  : LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]))
                                  : LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade500]),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                if (isEndTripEnabled || rideRequestStatus != "ontrip")
                                  BoxShadow(
                                    color: (rideRequestStatus == "accepted"
                                        ? Color(0xFF10B981)
                                        : rideRequestStatus == "arrived"
                                        ? Color(0xFF2563EB)
                                        : Color(0xFFEF4444)).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: isEndTripEnabled || rideRequestStatus != "ontrip" ? () async {
                                  if(rideRequestStatus == "accepted") {
                                    rideRequestStatus = "arrived";
                                    FirebaseDatabase.instance.ref()
                                        .child("All Ride Requests")
                                        .child(widget.userRideRequestDetails!.rideRequestId!)
                                        .child("status")
                                        .set(rideRequestStatus);

                                    setState(() {
                                      buttonTitle = "Start Trip";
                                      buttonColor = Color(0xFF2563EB);
                                    });

                                    _updateLiveDistanceState();
                                    await updatePolylineFromCurrentPosition(forceUpdate: true);
                                    await updateDurationTimeAtRealTime(forceUpdate: true);
                                  } else if(rideRequestStatus == "arrived") {
                                    rideRequestStatus = "ontrip";
                                    FirebaseDatabase.instance.ref()
                                        .child("All Ride Requests")
                                        .child(widget.userRideRequestDetails!.rideRequestId!)
                                        .child("status")
                                        .set(rideRequestStatus);

                                    setState(() {
                                      buttonTitle = "End Trip";
                                      buttonColor = Color(0xFFEF4444);
                                    });
                                    _updateLiveDistanceState();
                                    await updatePolylineFromCurrentPosition(forceUpdate: true);
                                    await updateDurationTimeAtRealTime(forceUpdate: true);
                                  } else if(rideRequestStatus == "ontrip") {
                                    endTripNow();
                                  }
                                } : null,
                                child: Container(
                                  height: 56,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        rideRequestStatus == "accepted"
                                            ? Icons.location_on_rounded
                                            : rideRequestStatus == "arrived"
                                            ? Icons.directions_car_rounded
                                            : Icons.flag_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        buttonTitle!,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> drawPolyLineFromOriginToDestination(
      LatLng originLatLng,
      LatLng destinationLatLng, {
        bool showLoading = false,
      }) async {
    if (showLoading) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => ProgressDialog(message: "Please wait..."),
      );
    }

    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(originLatLng, destinationLatLng);
    if (showLoading && mounted) {
      Navigator.pop(context);
    }

    if (directionDetailsInfo == null) {
      print("Failed to get direction details");
      return;
    }

    PolylinePoints pPoints = PolylinePoints(apiKey: '');
    List<PointLatLng> decodedPolyLinePointsResultList = PolylinePoints.decodePolyline(directionDetailsInfo.e_points!);

    polyLinePositionCoordinates.clear();

    if(decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        polyLinePositionCoordinates.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setOfPolyline.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: rideRequestStatus == "accepted"
            ? const Color(0xFF10B981)
            : const Color(0xFF2563EB),
        width: 5,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polyLinePositionCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      setOfPolyline.add(polyline);
      _currentDestination = destinationLatLng;
      durationFromOriginToDestination =
      directionDetailsInfo.duration_text?.trim().isNotEmpty == true
          ? directionDetailsInfo.duration_text!
          : durationFromOriginToDestination;
      _distanceToActiveTargetMeters = Geolocator.distanceBetween(
        originLatLng.latitude,
        originLatLng.longitude,
        destinationLatLng.latitude,
        destinationLatLng.longitude,
      );
    });

    _resetManualControl();
    _setCameraBounds(originLatLng, destinationLatLng);
    _updateMarkersAndCircles(originLatLng, destinationLatLng);
  }

  void _setCameraBounds(LatLng originLatLng, LatLng destinationLatLng) {
    LatLngBounds boundsLatLng;
    if(originLatLng.latitude > destinationLatLng.latitude && originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if(originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if(originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng = LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newTripGoogleMapController!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));
  }

  void _updateMarkersAndCircles(LatLng originLatLng, LatLng destinationLatLng) {
    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      setOfMarkers.removeWhere((marker) =>
      marker.markerId.value == "originID" || marker.markerId.value == "destinationID");
      setOfMarkers.add(originMarker);
      setOfMarkers.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Color(0xFF10B981),
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Color(0xFFEF4444),
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      setOfCircle.clear();
      setOfCircle.add(originCircle);
      setOfCircle.add(destinationCircle);
    });
  }

  void _initializeChat() {
    String chatRoomId = widget.userRideRequestDetails!.rideRequestId!;

    _chatSubscription = FirebaseDatabase.instance
        .ref()
        .child("chatRooms")
        .child(chatRoomId)
        .child("messages")
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> messagesData = event.snapshot.value as Map<dynamic, dynamic>;
        List<ChatMessage> loadedMessages = [];

        messagesData.forEach((key, value) {
          ChatMessage message = ChatMessage.fromJson(Map<String, dynamic>.from(value));
          message.messageId = key;
          loadedMessages.add(message);
        });

        loadedMessages.sort((a, b) => (a.timestamp ?? "").compareTo(b.timestamp ?? ""));

        setState(() {
          _chatMessages = loadedMessages;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _chatScrollController.animateTo(
            _chatScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        });
      }
    });
  }

  void _sendMessage() {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    String chatRoomId = widget.userRideRequestDetails!.rideRequestId!;
    String messageId = FirebaseDatabase.instance
        .ref()
        .child("chatRooms")
        .child(chatRoomId)
        .child("messages")
        .push()
        .key!;

    ChatMessage newMessage = ChatMessage(
      messageId: messageId,
      senderId: currentFirebaseUser!.uid,
      senderName: onlineDriverData.name,
      message: messageText,
      timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      messageType: "text",
    );

    FirebaseDatabase.instance
        .ref()
        .child("chatRooms")
        .child(chatRoomId)
        .child("messages")
        .child(messageId)
        .set(newMessage.toJson())
        .then((_) {
      _messageController.clear();

      FirebaseDatabase.instance
          .ref()
          .child("chatRooms")
          .child(chatRoomId)
          .child("lastUpdate")
          .set(DateTime.now().millisecondsSinceEpoch.toString());
    });
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });

    if (_isChatOpen && _chatMessages.isEmpty) {
      _initializeChat();
    }
  }

  bool _shouldRefreshPolyline(LatLng origin, {bool forceUpdate = false}) {
    if (forceUpdate) {
      _lastPolylineOrigin = origin;
      _lastPolylineRefreshAt = DateTime.now();
      return true;
    }

    final now = DateTime.now();

    if (_lastPolylineOrigin == null || _lastPolylineRefreshAt == null) {
      _lastPolylineOrigin = origin;
      _lastPolylineRefreshAt = now;
      return true;
    }

    final movedMeters = Geolocator.distanceBetween(
      _lastPolylineOrigin!.latitude,
      _lastPolylineOrigin!.longitude,
      origin.latitude,
      origin.longitude,
    );

    final secondsPassed = now.difference(_lastPolylineRefreshAt!).inSeconds;
    final double moveThresholdMeters = rideRequestStatus == "ontrip" ? 150 : 120;
    final int minRefreshSeconds = rideRequestStatus == "ontrip" ? 20 : 15;

    if (movedMeters >= moveThresholdMeters || secondsPassed >= minRefreshSeconds) {
      _lastPolylineOrigin = origin;
      _lastPolylineRefreshAt = now;
      return true;
    }

    return false;
  }

  bool _shouldRefreshDuration() {
    final now = DateTime.now();

    if (_lastDurationRefreshAt == null ||
        now.difference(_lastDurationRefreshAt!).inSeconds >= 20) {
      _lastDurationRefreshAt = now;
      return true;
    }

    return false;
  }

  void _followDriverCameraIfNeeded(LatLng target, {bool force = false}) {
    final now = DateTime.now();

    if (force || _lastFollowCameraTarget == null || _lastFollowCameraAt == null) {
      _lastFollowCameraTarget = target;
      _lastFollowCameraAt = now;
      newTripGoogleMapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ),
      );
      return;
    }

    final movedMeters = Geolocator.distanceBetween(
      _lastFollowCameraTarget!.latitude,
      _lastFollowCameraTarget!.longitude,
      target.latitude,
      target.longitude,
    );

    final secondsPassed = now.difference(_lastFollowCameraAt!).inSeconds;

    if (movedMeters >= 25 || secondsPassed >= 4) {
      _lastFollowCameraTarget = target;
      _lastFollowCameraAt = now;
      newTripGoogleMapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ),
      );
    }
  }

  // FIXED: Improved driver position updates that respect manual control
  void updatePolylineAsDriverMoves() {
    _routeUpdateTimer?.cancel();

    _routeUpdateTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      if (onlineDriverCurrentPosition != null && _currentDestination != null) {
        _checkAndUpdateRouteIfNeeded();
      }
    });

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 15,
    );

    streamSubscriptionDriverLivePosition = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      driverCurrentPosition = position;
      onlineDriverCurrentPosition = position;
      _updateLiveDistanceState();

      final latLngLiveDriverPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      driverPositionHistory.add(latLngLiveDriverPosition);
      if (driverPositionHistory.length > 10) {
        driverPositionHistory.removeAt(0);
      }

      final animatingMarker = Marker(
        markerId: const MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: const InfoWindow(title: "This is your Position"),
      );

      setState(() {
        setOfMarkers.removeWhere(
              (element) => element.markerId.value == "AnimatedMarker",
        );
        setOfMarkers.add(animatingMarker);
      });

      if (!_isManualControl) {
        _followDriverCameraIfNeeded(latLngLiveDriverPosition);
      }

      if (_shouldRefreshPolyline(latLngLiveDriverPosition)) {
        await updatePolylineFromCurrentPosition();
      }

      final driverLatLngDataMap = {
        "latitude": position.latitude.toString(),
        "longitude": position.longitude.toString(),
      };
      FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails!.rideRequestId!)
          .child("driverLocation")
          .set(driverLatLngDataMap);
    });
  }

  void _checkAndUpdateRouteIfNeeded() {
    if (driverPositionHistory.length < 3) return;

    LatLng currentPos = driverPositionHistory.last;
    double minDistance = double.infinity;

    for (var point in polyLinePositionCoordinates) {
      double distance = Geolocator.distanceBetween(
          currentPos.latitude, currentPos.longitude,
          point.latitude, point.longitude
      );
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    if (minDistance > 200 && _currentDestination != null) {
      print("Route deviation detected, recalculating...");
      updatePolylineFromCurrentPosition(forceUpdate: true);
    }
  }

  Future<void> updatePolylineFromCurrentPosition({bool forceUpdate = false}) async {
    if (onlineDriverCurrentPosition == null || _isRefreshingPolyline) return;

    final originLatLng = LatLng(
      onlineDriverCurrentPosition!.latitude,
      onlineDriverCurrentPosition!.longitude,
    );

    if (!_shouldRefreshPolyline(originLatLng, forceUpdate: forceUpdate)) {
      return;
    }

    _isRefreshingPolyline = true;

    try {
      LatLng destinationLatLng;

      if (rideRequestStatus == "accepted") {
        destinationLatLng = widget.userRideRequestDetails!.originLatLng!;
      } else if (rideRequestStatus == "arrived" || rideRequestStatus == "ontrip") {
        destinationLatLng = widget.userRideRequestDetails!.destinationLatLng!;
      } else {
        return;
      }

      final directionDetailsInfo =
      await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng,
        destinationLatLng,
      );

      if (directionDetailsInfo == null) {
        return;
      }

      final decodedPolyLinePointsResultList =
      PolylinePoints.decodePolyline(directionDetailsInfo.e_points!);

      polyLinePositionCoordinates.clear();

      for (final pointLatLng in decodedPolyLinePointsResultList) {
        polyLinePositionCoordinates.add(
          LatLng(pointLatLng.latitude, pointLatLng.longitude),
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        setOfPolyline.clear();
        setOfPolyline.add(
          Polyline(
            color: rideRequestStatus == "accepted"
                ? const Color(0xFF10B981)
                : const Color(0xFF2563EB),
            width: 5,
            polylineId: const PolylineId("LiveDriverRoute"),
            jointType: JointType.round,
            points: polyLinePositionCoordinates,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            geodesic: true,
          ),
        );
        durationFromOriginToDestination =
        directionDetailsInfo.duration_text?.trim().isNotEmpty == true
            ? directionDetailsInfo.duration_text!
            : durationFromOriginToDestination;
        _currentDestination = destinationLatLng;
        _distanceToActiveTargetMeters = Geolocator.distanceBetween(
          originLatLng.latitude,
          originLatLng.longitude,
          destinationLatLng.latitude,
          destinationLatLng.longitude,
        );
      });

      if (forceUpdate) {
        _resetManualControl();
      }
    } finally {
      _isRefreshingPolyline = false;
    }
  }


  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * pi / 180;
    double startLng = start.longitude * pi / 180;
    double endLat = end.latitude * pi / 180;
    double endLng = end.longitude * pi / 180;

    double dLng = endLng - startLng;
    double y = sin(dLng) * cos(endLat);
    double x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    double bearing = atan2(y, x);
    bearing = bearing * 180 / pi;
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  createDriverIconMarker() {
    if(iconAnimatedMarker == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value) {
        iconAnimatedMarker = value;
      });
    }
  }

  Future<void> updateDurationTimeAtRealTime({bool forceUpdate = false}) async {
    if (onlineDriverCurrentPosition == null) {
      return;
    }

    _updateLiveDistanceState(refreshUi: false);

    if (!forceUpdate && isRequestDirectionDetails == true) {
      return;
    }

    if (forceUpdate) {
      _lastDurationRefreshAt = DateTime.now();
    } else if (!_shouldRefreshDuration()) {
      return;
    }

    isRequestDirectionDetails = true;

    try {
      final originLatLng = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      final LatLng destinationLatLng =
      rideRequestStatus == "accepted"
          ? widget.userRideRequestDetails!.originLatLng!
          : widget.userRideRequestDetails!.destinationLatLng!;

      final directionInformation =
      await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng,
        destinationLatLng,
      );

      if (!mounted || directionInformation == null) {
        if (mounted) {
          setState(() {
            durationFromOriginToDestination = _formatDistanceLabel(_distanceToActiveTargetMeters);
          });
        }
        return;
      }

      setState(() {
        durationFromOriginToDestination =
        directionInformation.duration_text?.trim().isNotEmpty == true
            ? directionInformation.duration_text!
            : durationFromOriginToDestination;
      });
    } finally {
      isRequestDirectionDetails = false;
    }
  }

  bool hasReachedDestination() {
    if (rideRequestStatus != "ontrip") return false;

    final localDistance = _distanceToActiveTargetMeters;
    if (localDistance != null) {
      return localDistance <= _destinationUnlockRadiusMeters;
    }

    if (onlineDriverCurrentPosition == null) return false;

    double distanceToDestination = Geolocator.distanceBetween(
      onlineDriverCurrentPosition!.latitude,
      onlineDriverCurrentPosition!.longitude,
      widget.userRideRequestDetails!.destinationLatLng!.latitude,
      widget.userRideRequestDetails!.destinationLatLng!.longitude,
    );

    return distanceToDestination <= _destinationUnlockRadiusMeters;
  }

  double _computeFixedFareForThisTrip() {
    final origin = widget.userRideRequestDetails?.originLatLng;
    final destination = widget.userRideRequestDetails?.destinationLatLng;
    if (origin == null || destination == null) return FareConfig.baseFare;

    // fallback: straight-line distance when trip directions were not cached here
    final distanceMeters = Geolocator.distanceBetween(
      origin.latitude,
      origin.longitude,
      destination.latitude,
      destination.longitude,
    ).round();
    final extraKm = ((distanceMeters / 1000.0) - FareConfig.baseDistanceKm);
    final roundedExtraKm = extraKm <= 0 ? 0.0 : extraKm.ceilToDouble();
    final totalDistanceKm = distanceMeters / 1000.0;

    if (totalDistanceKm > FareConfig.maxServiceDistanceKm) {
      return 0.0;
    }

    return FareConfig.baseFare + (roundedExtraKm * FareConfig.additionalPerKm);
  }

  endTripNow() async {
    // Show initial loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ProgressDialog(message: "Ending trip..."),
    );

    try {
      final rideRequestRef = FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails!.rideRequestId!);

      double totalFareAmount = _computeFixedFareForThisTrip();
      final estimatedFareSnapshot = await rideRequestRef.child("estimatedFare").get();
      if (estimatedFareSnapshot.value != null) {
        totalFareAmount = double.tryParse(estimatedFareSnapshot.value.toString()) ?? totalFareAmount;
      }
      final roundedTotal = totalFareAmount.toStringAsFixed(1);

      // Save fare and end trip (but wait for payment)
      await rideRequestRef.child("fareAmount").set(roundedTotal);
      await rideRequestRef.child("status").set("ended");
      await rideRequestRef.child("paymentCompleted").set(false);

      // Stop live tracking
      streamSubscriptionDriverLivePosition?.cancel();
      _routeUpdateTimer?.cancel();

      // Close the initial loading dialog
      if (mounted) Navigator.pop(context);

      // Show waiting for payment dialog (uses totalFareAmount)
      _showWaitingForPaymentDialog(totalFareAmount);
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);
      Fluttertoast.showToast(msg: "Failed to end trip: $e");
      print("Error ending trip: $e");
    }
  }

  // New method to show waiting dialog and listen for payment

  void _showWaitingForPaymentDialog(double totalFareAmount) {
    // Show the waiting for payment dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => WaitingForPaymentDialog(totalFareAmount: totalFareAmount),
    );

    DatabaseReference rideRequestRef = FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!);

    // Listen for payment completion
    StreamSubscription<DatabaseEvent>? paymentSubscription;

    paymentSubscription = rideRequestRef.child("paymentCompleted").onValue.listen((event) {
      if (event.snapshot.value != null && event.snapshot.value == true) {
        // Payment completed! Close waiting dialog and show collection dialog
        paymentSubscription?.cancel();

        // Close the waiting dialog
        Navigator.pop(context);

        // Show collection dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext c) => FareAmountCollectionDialog(
              totalFareAmount: totalFareAmount,
            ),
          ).then((_) {
            // After collection, complete the process
            _chatSubscription?.cancel();
            saveFareAmountToDriverEarnings(totalFareAmount);

            // Navigate back to home screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
                  (route) => false,
            );
          });
        });
      }
    });

    // Also add a timeout in case payment never comes (optional safety measure)
    Future.delayed(Duration(minutes: 5), () {
      if (paymentSubscription != null) {
        paymentSubscription!.cancel();
        // You can show a timeout message or handle this case
        Navigator.pop(context); // Close waiting dialog
        // Optionally show timeout message
        _showPaymentTimeoutMessage();
      }
    });
  }

  // Optional: Method to handle payment timeout
  void _showPaymentTimeoutMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Payment Timeout"),
        content: Text("Payment was not received. The trip has been ended."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
                    (route) => false,
              );
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // Add this method after the _showPaymentTimeoutMessage() method
  Future<void> _cancelRideAfterAcceptance() async {
    // Show simple confirmation
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cancel Ride?"),
        content: Text("Cancel this ride and notify the commuter?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Direct cancellation without loading dialog
    try {
      print("Direct cancellation attempt...");

      // 1. Update ride status
      await FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(widget.userRideRequestDetails!.rideRequestId!)
          .update({
        "status": "cancelled",
        "cancelled_at": DateTime.now().toIso8601String(),
      });

      // 2. Update driver status
      await FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .child("newRideStatus")
          .set("idle");

      // 3. Cleanup
      streamSubscriptionDriverLivePosition?.cancel();

      // 4. Navigate
      Fluttertoast.showToast(msg: "Ride cancelled");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => MainScreen()),
            (route) => false,
      );

    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(msg: "Error: $e");
    }
  }

// Add this method right after the _cancelRideAfterAcceptance() method
  // In driver's NewTripScreen, ensure the notification method sends FCM:
  Future<void> _sendCancellationNotificationToCommuter() async {
    try {
      print("🚗 [DRIVER] Sending cancellation notification to commuter...");

      // Get commuter's device token
      DatabaseReference userRef = FirebaseDatabase.instance.ref()
          .child("users")
          .child(widget.userRideRequestDetails!.userPhone!)
          .child("token");

      DataSnapshot tokenSnapshot = await userRef.get();

      if (tokenSnapshot.value != null) {
        String deviceToken = tokenSnapshot.value.toString();

        // Get access token for FCM
        final accessToken = await AssistantMethods.getAccessToken();

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
              "body": "Your driver has cancelled the ride. Please request another ride."
            },
            "data": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK",
              "rideRequestId": widget.userRideRequestDetails!.rideRequestId,
              "status": "cancelled",
              "cancelled_by": "driver",  // Important: Indicate who cancelled
              "action": "ride_cancelled",
              "timestamp": DateTime.now().millisecondsSinceEpoch.toString(),
            }
          }
        };

        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          print("✅ [DRIVER] FCM cancellation notification sent to commuter");
        } else {
          print("⚠️ [DRIVER] FCM returned ${response.statusCode}: ${response.body}");
        }
      } else {
        print("⚠️ [DRIVER] No device token found for commuter");
      }
    } catch (error) {
      print("⚠️ [DRIVER] Notification process error: $error");
    }
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Exit Ride?"),
          content: Text("Are you sure you want to exit the ride screen? You can always return by checking your active rides."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Stay"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              },
              child: Text("Exit", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Add this method to listen for ride cancellations
  void _listenForRideCancellation() {
    DatabaseReference rideRequestRef = FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!);

    // Listen for status changes (specifically for "cancelled" status)
    rideRequestRef.child("status").onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        String status = event.snapshot.value.toString();
        print("🚗 [DRIVER] Ride status changed to: $status");

        if (status == "cancelled" && mounted) {
          print("🚗 [DRIVER] Ride cancelled by commuter!");

          // Get cancellation details
          rideRequestRef.child("cancelled_by").once().then((cancelledBySnapshot) {
            String cancelledBy = cancelledBySnapshot.snapshot.value?.toString() ?? "unknown";

            // Show cancellation message to driver
            _showRideCancelledByCommuterDialog(cancelledBy);
          });
        }
      }
    });

    // Also listen for specific cancellation notification flag
    rideRequestRef.child("cancellation_notified").onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value == true && mounted) {
        print("🚗 [DRIVER] Received cancellation notification flag");
        _showRideCancelledByCommuterDialog("commuter");
      }
    });
  }

// Add this dialog method
  void _showRideCancelledByCommuterDialog(String cancelledBy) {
    // Prevent showing multiple dialogs
    if (!mounted) return;

    // Cancel any active subscriptions
    streamSubscriptionDriverLivePosition?.cancel();
    _routeUpdateTimer?.cancel();
    _chatSubscription?.cancel();

    // Show cancellation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Ride Cancelled"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                "The commuter has cancelled the ride.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "You will be redirected to the main screen.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _returnToMainScreenAfterCancellation();
              },
              child: Text("OK", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

// Add this method to return to main screen
  void _returnToMainScreenAfterCancellation() {
    if (!mounted) return;

    // Clean up all subscriptions
    streamSubscriptionDriverLivePosition?.cancel();
    _routeUpdateTimer?.cancel();
    _chatSubscription?.cancel();

    // Update driver status to idle
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("newRideStatus")
        .set("idle");

    // Clean up trips history
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("tripsHistory")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .remove();

    // Show toast message
    Fluttertoast.showToast(
      msg: "Ride cancelled by commuter",
      backgroundColor: Colors.orange,
      textColor: Colors.white,
    );

    // Navigate back to main screen
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
          (route) => false,
    );
  }

  saveFareAmountToDriverEarnings(double totalFareAmount) {
    FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("earnings")
        .once()
        .then((snap) {
      if(snap.snapshot.value != null) {
        double oldEarnings = double.parse(snap.snapshot.value.toString());
        double driverTotalEarnings = totalFareAmount + oldEarnings;

        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(driverTotalEarnings.toString());
      } else {
        FirebaseDatabase.instance.ref()
            .child("drivers")
            .child(currentFirebaseUser!.uid)
            .child("earnings")
            .set(totalFareAmount.toString());
      }
    });
  }

  saveAssignedDriverDetailsToUserRideRequest() {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(widget.userRideRequestDetails!.rideRequestId!);

    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };
    databaseReference.child("driverLocation").set(driverLocationDataMap);

    databaseReference.child("status").set("accepted");
    databaseReference.child("driverId").set(onlineDriverData.id);
    databaseReference.child("name").set(onlineDriverData.name);
    databaseReference.child("phone").set(onlineDriverData.phone);
    databaseReference.child("vehicle_details").set(onlineDriverData.vehicle_color.toString() + " " + onlineDriverData.vehicle_model.toString() + " " + onlineDriverData.plate_number.toString());

    saveRideRequestIdToDriverHistory();
  }

  saveRideRequestIdToDriverHistory() {
    DatabaseReference tripsHistoryRef = FirebaseDatabase.instance.ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("tripsHistory");

    tripsHistoryRef.child(widget.userRideRequestDetails!.rideRequestId!).set(true);
  }
}