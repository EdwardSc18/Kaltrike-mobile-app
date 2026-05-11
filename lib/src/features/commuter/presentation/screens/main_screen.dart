import 'dart:async';
import 'dart:convert';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:kaltrike_driver_app/src/features/commuter/services/assistant_methods.dart';
import 'package:kaltrike_driver_app/src/features/commuter/auth/presentation/screens/login_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/state/app_info.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/precise_pickup_location.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/rate_driver_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/search_places_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/select_nearest_active_driver_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/feedback_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/tap_destination_screen.dart';
import 'package:kaltrike_driver_app/src/shared/models/direction_details_info.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/my_drawer.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kaltrike_driver_app/src/features/commuter/services/geofire_assistant.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:kaltrike_driver_app/src/features/commuter/app/commuter_app_shell.dart';
import 'package:kaltrike_driver_app/src/features/commuter/models/active_nearby_available_drivers.dart';
import 'package:kaltrike_driver_app/src/shared/models/directions.dart';
import 'package:kaltrike_driver_app/src/shared/models/chat_message.dart'; // Add this import
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/pay_fare_amount_dialog.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/widgets/progress_dialog.dart';
import 'package:number_inc_dec/number_inc_dec.dart';
import 'package:kaltrike_driver_app/src/core/services/noti_service.dart';
import 'package:kaltrike_driver_app/src/core/config/fare_config.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final AppInfo _commuterAppInfo;
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(17.411735, 121.43845),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 400;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoOrdinatesList = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  String userName = "Your name...";
  String userEmail = "Your email...";

  bool openNavigationDrawer = true;
  bool isWaitingForDriverResponse = false;
  bool activeNearbyDriverKeysLoaded = false;
  BitmapDescriptor? activeNearbyIcon;

  List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList = [];

  DatabaseReference? referenceRideRequest;
  String driverRideStatus = "Driver is Coming";
  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubscription;

  StreamSubscription<DatabaseEvent>? _driverLocationStreamSubscription;
  LatLng? _currentDriverPosition;
  BitmapDescriptor? _driverIcon;
  Timer? _driverPositionTimer;

  DateTime? _lastDriverRouteRefreshAt;
  LatLng? _lastDriverRouteRefreshOrigin;

  String userRideRequestStatus = "";
  bool requestPositionInfo = true;

  String _value = "";

  Map<String, dynamic> _allDriversDetails = {};
  Map<String, dynamic> _activeDriversLocations = {};
  List<ActiveNearbyAvailableDrivers> _filteredOnlineDriversList = [];
  StreamSubscription<DatabaseEvent>? _driversDetailsSubscription;

  // NEW: Chat functionality variables
  bool _isChatOpen = false;
  bool _isChatMinimized = false;
  double _chatHeight = 300.0;
  double _chatWidth = 320.0;
  double _minChatHeight = 200.0;
  double _maxChatHeight = 500.0;
  double _minChatWidth = 280.0;
  double _maxChatWidth = 400.0;
  Offset _chatPosition = Offset(16, 100);
  bool _isDragging = false;
  List<ChatMessage> _chatMessages = [];
  TextEditingController _messageController = TextEditingController();
  StreamSubscription<DatabaseEvent>? _chatSubscription;
  final ScrollController _chatScrollController = ScrollController();
  FocusNode _chatFocusNode = FocusNode();

  // Ride sharing variables
  String _rideSharingChoice = "no";
  final TextEditingController _passengerCountController = TextEditingController(text: "1");

  // Refresh functionality
  bool _isRefreshing = false;
  bool _isSubmittingRideRequest = false;

// ===================== FARE REVIEW (NEW) =====================

  double? _baseEstimatedFare;
  double? _estimatedFare;
  bool _fareReviewed = false;
  String _fareDistanceText = "";
  String _fareDurationText = "";
// =============================================================

  int _dailyCancellationLimit = 3;

  //Location Permission
  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator.requestPermission();
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  // Get the current position
  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

    CameraPosition cameraPosition = CameraPosition(target: latLngPosition, zoom: 16);
    newGoogleMapController!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress = await AssistantMethods.searchAddressForGeographicCoOrdinates(userCurrentPosition!, context);

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();
    AssistantMethods.readTripsKeysForOnlineUser(context);
  }

  // NEW: Refresh online drivers method
  Future<void> refreshOnlineDrivers() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      // Clear current drivers list
      GeoFireAssistant.activeNearbyAvailableDriversList.clear();
      _filteredOnlineDriversList.clear();
      onlineNearByAvailableDriversList.clear();

      // Clear existing driver markers
      markersSet.removeWhere((marker) => marker.markerId.value.startsWith('driver'));

      // Re-initialize GeoFire listener to get fresh data
      initializeGeoFireListener();

      // Force reload of drivers details
      _listenForAllDriversDetails();

      Fluttertoast.showToast(
        msg: "Refreshing available drivers...",
        toastLength: Toast.LENGTH_SHORT,
      );

      // Wait a bit for data to load
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        _isRefreshing = false;
      });


    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      Fluttertoast.showToast(
        msg: "Error refreshing drivers: $e",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  }

  checkConnection() async {
    var connection = await Connectivity().checkConnectivity();
    if (connection == ConnectivityResult.none){
      return AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        width: (MediaQuery.sizeOf(context).width * 0.9)
            .clamp(280.0, 360.0)
            .toDouble(),
        buttonsBorderRadius: const BorderRadius.all(Radius.circular(16)),
        dismissOnTouchOutside: false,
        dismissOnBackKeyPress: false,
        headerAnimationLoop: false,
        animType: AnimType.bottomSlide,
        title: 'No Internet Connection',
        desc: 'Please check your internet connection and try again.',
        btnOkOnPress: () {
          SystemNavigator.pop();
        },
        btnOkText: "Exit App",
        btnOkColor: const Color(0xFF2563EB),
      )..show();
    }
  }


  @override
  void initState() {
    super.initState();
    _commuterAppInfo = AppInfo();
    checkConnection();
    checkIfLocationPermissionAllowed();
    additionalController.text = "0";
    _passengerCountController.text = "1";

    _passengerCountController.addListener(_handleFareOptionChanged);
    additionalController.addListener(_handleFareOptionChanged);

    // FIXED: Listen to focus changes
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final size = MediaQuery.sizeOf(context);
      final topInset = MediaQuery.of(context).padding.top;

      setState(() {
        _chatWidth = (size.width * 0.82).clamp(280.0, 380.0).toDouble();
        _chatHeight = (size.height * 0.34).clamp(220.0, 420.0).toDouble();
        _minChatWidth = (size.width * 0.70).clamp(260.0, 320.0).toDouble();
        _maxChatWidth = (size.width * 0.92).clamp(320.0, 420.0).toDouble();
        _minChatHeight = (size.height * 0.24).clamp(180.0, 260.0).toDouble();
        _maxChatHeight = (size.height * 0.60).clamp(320.0, 520.0).toDouble();
        _chatPosition = Offset(16, topInset + 56);
      });
    });
  }

  int _currentPassengerCount() {
    final parsedValue = int.tryParse(_passengerCountController.text.trim()) ?? 1;
    return parsedValue.clamp(1, 4);
  }

  int _currentBaggageCount() {
    final parsedValue = int.tryParse(additionalController.text.trim()) ?? 0;
    return parsedValue < 0 ? 0 : parsedValue;
  }

  bool _isRideSharingEnabled() {
    return _rideSharingChoice == 'yes';
  }

  double _calculatePassengerFare() {
    return FareConfig.calculatePassengerFare(
      isRideSharing: _isRideSharingEnabled(),
      passengerCount: _currentPassengerCount(),
    );
  }

  double _calculateRideSharingFee() {
    return FareConfig.calculateRideSharingFee(
      isRideSharing: _isRideSharingEnabled(),
      passengerCount: _currentPassengerCount(),
    );
  }

  double _calculateBaggageFee() {
    return FareConfig.calculateBaggageFee(_currentBaggageCount());
  }

  double _calculateOptionSurcharge() {
    return _calculateRideSharingFee() + _calculateBaggageFee();
  }

  void _updateEstimatedFareFromSelections({bool resetFareReview = true}) {
    if (_baseEstimatedFare == null) {
      return;
    }

    final updatedFare = _baseEstimatedFare! + _calculateOptionSurcharge();

    if (!mounted) {
      _estimatedFare = updatedFare;
      if (resetFareReview) {
        _fareReviewed = false;
      }
      return;
    }

    setState(() {
      _estimatedFare = updatedFare;
      if (resetFareReview) {
        _fareReviewed = false;
      }
    });
  }

  void _handleFareOptionChanged() {
    if (_baseEstimatedFare == null) return;
    _updateEstimatedFareFromSelections();
  }

  // NEW: Chat functionality methods
  void _initializeChat() {
    if (referenceRideRequest == null) return;

    String chatRoomId = referenceRideRequest!.key!;

    // Listen for new messages
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

        // Sort messages by timestamp
        loadedMessages.sort((a, b) => (a.timestamp ?? "").compareTo(b.timestamp ?? ""));

        setState(() {
          _chatMessages = loadedMessages;
        });

        // Scroll to bottom
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

    if (referenceRideRequest == null) {
      Fluttertoast.showToast(msg: "Cannot send message - no active ride");
      return;
    }

    String chatRoomId = referenceRideRequest!.key!;
    String messageId = FirebaseDatabase.instance
        .ref()
        .child("chatRooms")
        .child(chatRoomId)
        .child("messages")
        .push()
        .key!;

    ChatMessage newMessage = ChatMessage(
      messageId: messageId,
      senderId: userModelCurrentInfo!.id!,
      senderName: userModelCurrentInfo!.name!,
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

      // Update last message timestamp
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

    if (_isChatOpen && _chatMessages.isEmpty && referenceRideRequest != null) {
      _initializeChat();
    }
  }

  Widget _buildChatInterface() {
    // Only show chat when driver is assigned
    if (assignedDriverInfoContainerHeight == 0) {
      return SizedBox.shrink();
    }

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
                Icons.directions_car_rounded,
                color: Color(0xFF2563EB),
                size: 14,
              ),
              radius: 12,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chat with Driver",
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
                Icons.directions_car_rounded,
                color: Color(0xFF2563EB),
                size: 18,
              ),
              radius: 14,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Chat with Driver",
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
          SizedBox(height: 4),
          Text(
            "Start a conversation with your driver",
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    )
        : ListView.builder(
      controller: _chatScrollController,
      padding: EdgeInsets.all(12),
      itemCount: _chatMessages.length,
      itemBuilder: (context, index) {
        ChatMessage message = _chatMessages[index];
        bool isPassenger = message.senderId == userModelCurrentInfo!.id;

        return Container(
          margin: EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: isPassenger
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isPassenger)
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
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: _chatWidth * 0.7,
                  ),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPassenger
                        ? Color(0xFF2563EB)
                        : Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isPassenger)
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
                          color: isPassenger
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
                          color: isPassenger
                              ? Colors.white70
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isPassenger)
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


  Future<void> saveRideRequestInformation() async {
    if (_isSubmittingRideRequest) return;

    if (_filteredOnlineDriversList.isEmpty) {
      await _showNoAvailableDriversDialog();
      return;
    }

    setState(() {
      _isSubmittingRideRequest = true;
    });

    try {
      referenceRideRequest = FirebaseDatabase.instance
          .ref()
          .child("All Ride Requests")
          .push();

      var originLocation =
          Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
      var destinationLocation =
          Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      Map originLocationMap = {
        "latitude": originLocation!.locationLatitude.toString(),
        "longitude": originLocation!.locationLongitude.toString(),
      };

      Map destinationLocationMap = {
        "latitude": destinationLocation!.locationLatitude.toString(),
        "longitude": destinationLocation!.locationLongitude.toString(),
      };

      var additional = _currentBaggageCount().toString();

      Map userInformationMap = {
        "origin": originLocationMap,
        "destination": destinationLocationMap,
        "time": DateTime.now().toString(),
        "userName": userModelCurrentInfo!.name,
        "userPhone": userModelCurrentInfo!.phone,
        "originAddress": originLocation.locationName,
        "destinationAddress": destinationLocation.locationName,
        "driverId": "waiting",
        "addons": additional,
        "discount": "",
        "estimatedFare": _estimatedFare ?? 0,
        "rideSharingFee": _calculateRideSharingFee(),
        "baggageFee": _calculateBaggageFee(),
        "fareRule": FareConfig.fareRuleName,
        "baseFare": FareConfig.baseFare,
        "baseDistanceKm": FareConfig.baseDistanceKm,
        "additionalPerKm": FareConfig.additionalPerKm,
        "maxServiceDistanceKm": FareConfig.maxServiceDistanceKm,
        "rideSharing": _rideSharingChoice,
        "passengerCount":
        _rideSharingChoice == "yes" ? _passengerCountController.text : "1",
      };

      await referenceRideRequest!.set(userInformationMap);
      _listenForDriverCancellation();

      tripRideRequestInfoStreamSubscription =
          referenceRideRequest!.onValue.listen((eventSnap) async {
            if (eventSnap.snapshot.value == null) {
              return;
            }

            if ((eventSnap.snapshot.value as Map)["vehicle_details"] != null) {
              setState(() {
                driverVehicleDetails =
                    (eventSnap.snapshot.value as Map)["vehicle_details"].toString();
              });
            }

            if ((eventSnap.snapshot.value as Map)["phone"] != null) {
              setState(() {
                driverPhone =
                    (eventSnap.snapshot.value as Map)["phone"].toString();
              });
            }

            if ((eventSnap.snapshot.value as Map)["name"] != null) {
              setState(() {
                driverName =
                    (eventSnap.snapshot.value as Map)["name"].toString();
              });
            }

            if ((eventSnap.snapshot.value as Map)["status"] != null) {
              userRideRequestStatus =
                  (eventSnap.snapshot.value as Map)["status"].toString();
            }

            if ((eventSnap.snapshot.value as Map)["driverLocation"] != null) {
              double driverCurrentPositionLat = double.parse(
                  (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                      .toString());
              double driverCurrentPositionLng = double.parse(
                  (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                      .toString());

              LatLng driverCurrentPositionLatLng =
              LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

              if (userRideRequestStatus == "accepted") {
                updateArrivalTimeToUserPickupLocation(driverCurrentPositionLatLng);
              }

              if (userRideRequestStatus == "arrived") {
                setState(() {
                  driverRideStatus = "Driver has Arrived";
                });
              }

              if (userRideRequestStatus == "ontrip") {
                updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
              }

              if (userRideRequestStatus == "ended") {
                if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
                  double fareAmount = double.parse(
                      (eventSnap.snapshot.value as Map)["fareAmount"].toString());

                  bool paymentCompleted =
                      (eventSnap.snapshot.value as Map)["paymentCompleted"] == true;

                  if (!paymentCompleted) {
                    var response = await showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext c) =>
                          PayFareAmountDialog(fareAmount: fareAmount),
                    );

                    if (response == "cashPayed") {
                      referenceRideRequest!.child("paymentCompleted").set(true);

                      Fluttertoast.showToast(
                        msg: "Payment completed successfully!",
                        toastLength: Toast.LENGTH_SHORT,
                      );

                      if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
                        String assignedDriverId =
                        (eventSnap.snapshot.value as Map)["driverId"].toString();

                        referenceRideRequest!.onDisconnect();
                        tripRideRequestInfoStreamSubscription!.cancel();
                        _chatSubscription?.cancel();

                        resetToMainScreen();

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) =>
                                RateDriverScreen(assignedDriverId: assignedDriverId),
                          ),
                        );
                      }
                    }
                  } else {
                    Fluttertoast.showToast(
                      msg: "Payment was already processed",
                      toastLength: Toast.LENGTH_SHORT,
                    );
                  }
                }
              }
            }
          });

      onlineNearByAvailableDriversList =
          GeoFireAssistant.activeNearbyAvailableDriversList;
      await searchNearestOnlineDrivers();
    } catch (e) {
      if (referenceRideRequest != null) {
        await referenceRideRequest!.remove();
        referenceRideRequest = null;
      }

      Fluttertoast.showToast(
        msg: 'Unable to create the ride request. Please try again.',
        toastLength: Toast.LENGTH_SHORT,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingRideRequest = false;
        });
      }
    }
  }

  updateArrivalTimeToUserPickupLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;

      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userPickUpPosition,
      );

      if (directionDetailsInfo == null) {
        requestPositionInfo = true;
        return;
      }

      setState(() {
        driverRideStatus = "Driver is Coming :: " + directionDetailsInfo.duration_text.toString();
      });

      // Start tracking driver position in real-time using Firebase updates
      _startDriverPositionTracking(driverCurrentPositionLatLng, userPickUpPosition);

      // Initialize chat when driver is assigned
      _initializeChat();

      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation!.locationLongitude!);

      var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userDestinationPosition,
      );

      if (directionDetailsInfo == null) {
        requestPositionInfo = true;
        return;
      }

      setState(() {
        driverRideStatus = "Going towards Destination :: " + directionDetailsInfo.duration_text.toString();
      });

      // Start tracking driver position to destination using Firebase updates
      _startDriverPositionTracking(driverCurrentPositionLatLng, userDestinationPosition);

      requestPositionInfo = true;
    }
  }


  // New method to update the driver's route polyline
  updateDriverRoutePolyline(LatLng origin, LatLng destination) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Updating route...",
      ),
    );

    var directionDetailsInfo =
    await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        origin, destination);

    Navigator.pop(context);

    if (directionDetailsInfo == null) {
      return;
    }

    PolylinePoints pPoints = PolylinePoints(apiKey: '');
    List<PointLatLng> decodedPolyLinePointsResultList =
    PolylinePoints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoOrdinatesList.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoOrdinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue, // Different color for driver's route
        polylineId: PolylineId("DriverRoute"),
        width: 4,
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });
  }

  Future<void> searchNearestOnlineDrivers() async {
    if (_filteredOnlineDriversList.isEmpty) {
      if (referenceRideRequest != null) {
        await referenceRideRequest!.remove();
        referenceRideRequest = null;
      }

      tripRideRequestInfoStreamSubscription?.cancel();
      _chatSubscription?.cancel();

      if (mounted) {
        setState(() {
          isWaitingForDriverResponse = false;
          waitingResponseFromDriverContainerHeight = 0;
          assignedDriverInfoContainerHeight = 0;
          searchLocationContainerHeight = 400;
          openNavigationDrawer = true;
        });
      }

      await _showNoAvailableDriversDialog();
      return;
    }

    await retrieveOnlineDriversInformation(_filteredOnlineDriversList);

    var response = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) =>
            SelectNearestActiveDriversScreen(referenceRideRequest: referenceRideRequest),
      ),
    );

    if (response != "driverChoosed") {
      if (referenceRideRequest != null) {
        await referenceRideRequest!.remove();
        referenceRideRequest = null;
      }

      tripRideRequestInfoStreamSubscription?.cancel();
      _chatSubscription?.cancel();

      if (mounted) {
        setState(() {
          isWaitingForDriverResponse = false;
          waitingResponseFromDriverContainerHeight = 0;
          searchLocationContainerHeight = 400;
          openNavigationDrawer = true;
        });
      }
      return;
    }

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId!)
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        sendNotificationToDriverNow(chosenDriverId!);
        showWaitingResponseFromDriverUI();

        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(chosenDriverId!)
            .child("newRideStatus")
            .onValue
            .listen((eventSnapshot) {
          if (eventSnapshot.snapshot.value == "idle") {
            if (isWaitingForDriverResponse) {
              print("👤 [COMMUTER] Driver cancelled during waiting period");

              if (referenceRideRequest != null) {
                referenceRideRequest!.once().then((rideSnap) {
                  if (rideSnap.snapshot.value != null) {
                    Map<dynamic, dynamic> rideData =
                    rideSnap.snapshot.value as Map<dynamic, dynamic>;
                    String status = rideData["status"]?.toString() ?? "";

                    if (status == "cancelled") {
                      _showRideCancelledByDriverDialog();
                    } else {
                      Fluttertoast.showToast(
                        msg:
                        "The driver has cancelled your request. Please choose another driver.",
                      );
                      resetToMainScreen();
                    }
                  }
                });
              }
            }
          }

          if (eventSnapshot.snapshot.value == "accepted") {
            print("👤 [COMMUTER] Driver accepted the ride");
            showUIForAssignedDriverInfo();
          }
        });
      } else {
        Fluttertoast.showToast(msg: "This driver do not exist. Try again.");
      }
    });
  }

  showUIForAssignedDriverInfo() {
    setState(() {
      waitingResponseFromDriverContainerHeight = 0;
      searchLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 320;
    });
  }

  showWaitingResponseFromDriverUI() {
    setState(() {
      isWaitingForDriverResponse = true;
      searchLocationContainerHeight = 0;
      waitingResponseFromDriverContainerHeight = 250;
    });
  }

  sendNotificationToDriverNow(String chosenDriverId) {
    // assign ride request id to new ride status so that it will not be taken again
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId)
        .child("newRideStatus")
        .set(referenceRideRequest!.key);

    // Automate the push notification...
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId)
        .child("token")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String deviceRegistrationToken = snap.snapshot.value.toString();

        // send Notification Now
        AssistantMethods.sendNotificationToDriverNow(
          deviceRegistrationToken,
          referenceRideRequest!.key.toString(),
          userDropOffAddress, // ✅ correct string
        );

        Fluttertoast.showToast(msg: "Notification sent Successfully.");
      } else {
        Fluttertoast.showToast(msg: "Please choose another driver.");
        return;
      }
    });
  }


// filter the list of online nearest drivers
// we will going to use this in the future to brodcast message in notes to a driver
  retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");
    dList.clear(); // Clear the list first to avoid duplicates

    for (int i = 0; i < onlineNearestDriversList.length; i++) {
      await ref
          .child(onlineNearestDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        final driverKeyInfo = dataSnapshot.snapshot.value;
        if (driverKeyInfo != null && driverKeyInfo is Map) {
          dList.add({
            "id": onlineNearestDriversList[i].driverId,
            ...Map<dynamic, dynamic>.from(driverKeyInfo)
          });
        }
      });
    }
  }

  @override

  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();

    final mediaSize = MediaQuery.sizeOf(context);
    final mediaPadding = MediaQuery.of(context).padding;
    final controlSize = mediaSize.width < 380 ? 46.0 : 52.0;
    final double sideInset =
    (mediaSize.width * 0.045).clamp(14.0, 20.0).toDouble();
    final topInset = mediaPadding.top + 12;
    final double zoomTop = (mediaSize.height * 0.30).clamp(
      topInset + (controlSize * 2.4),
      mediaSize.height - 220.0,
    ).toDouble();
    final bool hasActiveRide = assignedDriverInfoContainerHeight > 0 ||
        waitingResponseFromDriverContainerHeight > 0;
    final double activeBottomSheetHeight = <double>[
      searchLocationContainerHeight,
      waitingResponseFromDriverContainerHeight,
      assignedDriverInfoContainerHeight,
    ].fold<double>(0, (previous, current) {
      return current > previous ? current : previous;
    });

    return ChangeNotifierProvider<AppInfo>.value(
      value: _commuterAppInfo,
      child: Scaffold(
        key: sKey,
        drawer: SizedBox(
          width: 280,
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: Colors.white,
            ),
            child: MyDrawer(
              name: userName,
              email: userEmail,
            ),
          ),
        ),
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            GoogleMap(
              padding: EdgeInsets.only(bottom: activeBottomSheetHeight),
              mapType: MapType.normal,
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              initialCameraPosition: _kGooglePlex,
              polylines: polyLineSet,
              markers: markersSet,
              circles: circlesSet,
              onMapCreated: (GoogleMapController controller) {
                _controllerGoogleMap.complete(controller);
                newGoogleMapController = controller;

                setState(() {
                  bottomPaddingOfMap = activeBottomSheetHeight;
                });

                locateUserPosition();
              },
            ),
            Positioned(
              top: topInset,
              right: sideInset,
              child: _buildFloatingMapButton(
                onTap: () {
                  locateUserPosition();
                  Fluttertoast.showToast(msg: "Locating your position...");
                },
                shadowTint: const Color(0xFFBFDBFE),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
            ),
            Positioned(
              top: topInset + controlSize + 12,
              right: sideInset,
              child: _buildFloatingMapButton(
                onTap: refreshOnlineDrivers,
                shadowTint: const Color(0xFFA7F3D0),
                child: _isRefreshing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  ),
                )
                    : const Icon(
                  Icons.refresh_rounded,
                  color: Color(0xFF10B981),
                  size: 24,
                ),
              ),
            ),
            Positioned(
              right: sideInset,
              top: zoomTop,
              child: _buildZoomControls(controlSize: controlSize),
            ),
            if (waitingResponseFromDriverContainerHeight == 0)
              Positioned(
                top: topInset,
                left: sideInset,
                child: _buildFloatingMapButton(
                  onTap: () {
                    if (openNavigationDrawer) {
                      sKey.currentState!.openDrawer();
                    } else {
                      if (hasActiveRide) {
                        _showCancelOrExitDialog();
                      } else {
                        _showBackToHomeDialog();
                      }
                    }
                  },
                  shadowTint: const Color(0xFFBFDBFE),
                  child: Icon(
                    openNavigationDrawer
                        ? Icons.menu_rounded
                        : Icons.close_rounded,
                    color: const Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
              ),
            _buildChatInterface(),
            if (searchLocationContainerHeight > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedSize(
                  curve: Curves.easeInOut,
                  duration: const Duration(milliseconds: 180),
                  child: _buildBookingBottomSheet(mediaPadding),
                ),
              ),
            if (waitingResponseFromDriverContainerHeight > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildWaitingDriverBottomSheet(mediaPadding),
              ),
            if (assignedDriverInfoContainerHeight > 0)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildAssignedDriverBottomSheet(mediaPadding),
              ),
          ],
        ),
      ),
    );
  }

  // ===================== FARE REVIEW DIALOG (NEW) =====================

  Future<void> _showFareReviewDialog() async {
    if (_estimatedFare == null) return;

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Review your fare",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Please confirm the trip summary before booking.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Estimated Fare",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "₱${_estimatedFare!.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 28,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_fareDistanceText.isNotEmpty)
                          _buildDialogInfoChip(
                            icon: Icons.route_rounded,
                            label: _fareDistanceText,
                          ),
                        if (_fareDurationText.isNotEmpty)
                          _buildDialogInfoChip(
                            icon: Icons.schedule_rounded,
                            label: _fareDurationText,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFareRuleRow(
                      label: "Passenger fare",
                      value:
                      "₱${FareConfig.baseFare.toStringAsFixed(0)} x ${_isRideSharingEnabled() ? _currentPassengerCount() : 1} passenger(s) = ₱${_calculatePassengerFare().toStringAsFixed(0)} for first ${FareConfig.baseDistanceKm.toStringAsFixed(0)} km",
                    ),
                    const SizedBox(height: 10),
                    _buildFareRuleRow(
                      label: "Additional fee",
                      value:
                      "₱${FareConfig.additionalPerKm.toStringAsFixed(0)} per km after ${FareConfig.baseDistanceKm.toStringAsFixed(0)} km",
                    ),
                    const SizedBox(height: 10),
                    _buildFareRuleRow(
                      label: "Service range",
                      value:
                      "Up to ${FareConfig.maxServiceDistanceKm.toStringAsFixed(0)} km",
                    ),
                    if (_rideSharingChoice == 'yes') ...[
                      const SizedBox(height: 10),
                      _buildFareRuleRow(
                        label: 'Ride sharing add-on',
                        value:
                        '₱${FareConfig.rideSharingAdditionalPassengerFare.toStringAsFixed(0)} x ${(_currentPassengerCount() - 1).clamp(0, 3)} extra passenger(s) = ₱${_calculateRideSharingFee().toStringAsFixed(0)}',
                      ),
                    ],
                    if (_currentBaggageCount() > 0) ...[
                      const SizedBox(height: 10),
                      _buildFareRuleRow(
                        label: 'Baggage fee',
                        value:
                        '₱${FareConfig.baggageFare.toStringAsFixed(0)} x ${_currentBaggageCount()} bag(s) = ₱${_calculateBaggageFee().toStringAsFixed(0)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, "cancel"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Change"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, "confirm"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Confirm Fare"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    setState(() {
      _fareReviewed = (result == "confirm");
    });
  }

  // =============================================================

  Future<void> _handleBookRideRequest() async {
    final dropOffLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    if (_isSubmittingRideRequest) return;

    if (dropOffLocation == null) {
      Fluttertoast.showToast(msg: 'Please select where to go.');
      return;
    }

    if (!_fareReviewed) {
      Fluttertoast.showToast(
        msg: 'Please review and confirm the fare first.',
      );
      _showFareReviewDialog();
      return;
    }

    if (_isRefreshing) {
      Fluttertoast.showToast(
        msg: 'Still checking nearby drivers. Please wait a moment.',
      );
      return;
    }

    if (_filteredOnlineDriversList.isEmpty) {
      await _showNoAvailableDriversDialog();
      return;
    }

    await saveRideRequestInformation();
  }

  Future<void> _showNoAvailableDriversDialog() async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_taxi_outlined,
                  color: Color(0xFFEA580C),
                  size: 32,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No drivers available right now',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'There are no online Ongbak drivers nearby at the moment. You can refresh the driver list and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF2563EB),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_filteredOnlineDriversList.length} online drivers detected right now.',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        await refreshOnlineDrivers();

                        if (!mounted) return;

                        Fluttertoast.showToast(
                          msg: _filteredOnlineDriversList.isEmpty
                              ? 'Still no online drivers nearby.'
                              : 'Nearby drivers refreshed. You can book now.',
                          toastLength: Toast.LENGTH_SHORT,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text(
                        'Refresh',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required String buttonText,
    required VoidCallback onPressed,
    bool isDestination = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: isDestination
                      ? () async {
                    var responseFromSearchScreen = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (c) => SearchPlacesScreen()),
                    );
                    if (responseFromSearchScreen == "obtainedDropoff") {
                      setState(() {
                        openNavigationDrawer = false;
                      });
                      await drawPolyLineFromOriginToDestination();
                    }
                  }
                      : null,
                  child: Text(
                    address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (isDestination) ...[
                  const SizedBox(height: 6),
                  const Text(
                    "Tap the address or use the action button to update it.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              backgroundColor: const Color(0xFFEFF6FF),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              buttonText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0x00CBD5E1), Color(0xFFCBD5E1), Color(0x00CBD5E1)],
        ),
      ),
    );
  }

  Widget _buildFloatingMapButton({
    required Widget child,
    required VoidCallback onTap,
    Color shadowTint = const Color(0xFFBFDBFE),
  }) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: shadowTint.withOpacity(0.40),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildZoomControls({required double controlSize}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFBFDBFE).withOpacity(0.40),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
              onTap: () {
                newGoogleMapController?.animateCamera(CameraUpdate.zoomIn());
              },
              child: SizedBox(
                width: controlSize,
                height: controlSize,
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
            ),
          ),
          Container(width: 32, height: 1, color: const Color(0xFFE2E8F0)),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              onTap: () {
                newGoogleMapController?.animateCamera(CameraUpdate.zoomOut());
              },
              child: SizedBox(
                width: controlSize,
                height: controlSize,
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
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foregroundColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetContainer({
    required double height,
    required Widget child,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingBottomSheet(EdgeInsets mediaPadding) {
    return _buildSheetContainer(
      height: searchLocationContainerHeight,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            mediaPadding.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 18),
              _buildSectionHeader(
                title: 'Book your ride',
                subtitle:
                'Keep the process simple: confirm your pickup, set your destination, then review the fare.',
              ),
              const SizedBox(height: 18),
              _buildLocationRow(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Pickup',
                address: Provider.of<AppInfo>(context)
                    .userPickUpLocation
                    ?.locationName ??
                    'Getting current address...',
                buttonText: 'Change Pickup',
                onPressed: () async {
                  var response = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => PrecisePickupScreen()),
                  );
                  if (response == 'locationSelected') {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 14),
              _buildLocationRow(
                icon: Icons.flag_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Destination',
                address: Provider.of<AppInfo>(context)
                    .userDropOffLocation
                    ?.locationName ??
                    'Search destination',
                buttonText: 'Tap onMap',
                onPressed: () async {
                  var responseFromMapTap = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => TapDestinationScreen()),
                  );
                  if (responseFromMapTap == 'destinationSelected') {
                    setState(() {
                      openNavigationDrawer = false;
                    });
                    await drawPolyLineFromOriginToDestination();
                  }
                },
                isDestination: true,
              ),
              if (_estimatedFare != null) ...[
                const SizedBox(height: 16),
                _buildFarePreviewCard(),
              ],
              const SizedBox(height: 18),
              _buildDivider(),
              const SizedBox(height: 18),
              _buildSectionHeader(
                title: 'Ride options',
                subtitle:
                'Choose the options that match your trip before you send the request.',
              ),
              const SizedBox(height: 12),
              _buildRideOptionsSection(),
              const SizedBox(height: 18),
              _buildBookingHintBanner(),
              const SizedBox(height: 18),
              _buildBookingActionButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarePreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimated fare',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_estimatedFare!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (_fareReviewed)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF15803D),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Confirmed',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_fareDistanceText.isNotEmpty)
                _buildInfoPill(
                  icon: Icons.route_rounded,
                  label: _fareDistanceText,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
              if (_fareDurationText.isNotEmpty)
                _buildInfoPill(
                  icon: Icons.schedule_rounded,
                  label: _fareDurationText,
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
              if (_rideSharingChoice == 'yes')
                _buildInfoPill(
                  icon: Icons.people_alt_rounded,
                  label: 'Passenger ₱${_calculatePassengerFare().toStringAsFixed(0)}',
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
              if (_currentBaggageCount() > 0)
                _buildInfoPill(
                  icon: Icons.luggage_rounded,
                  label: '+₱${_calculateBaggageFee().toStringAsFixed(0)} baggage',
                  backgroundColor: Colors.white.withOpacity(0.12),
                  foregroundColor: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showFareReviewDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.30)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: Icon(
                _fareReviewed
                    ? Icons.visibility_rounded
                    : Icons.receipt_long_rounded,
                size: 18,
              ),
              label: Text(
                _fareReviewed
                    ? 'Review fare again'
                    : 'Review fare breakdown',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingHintBanner() {
    final dropOffLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    IconData icon;
    Color backgroundColor;
    Color foregroundColor;
    String title;
    String message;

    if (dropOffLocation == null) {
      icon = Icons.info_outline_rounded;
      backgroundColor = const Color(0xFFFFFBEB);
      foregroundColor = const Color(0xFFB45309);
      title = 'Destination needed';
      message = 'Choose where to go before you can review the fare or book.';
    } else if (!_fareReviewed) {
      icon = Icons.receipt_long_rounded;
      backgroundColor = const Color(0xFFEFF6FF);
      foregroundColor = const Color(0xFF1D4ED8);
      title = 'Review fare first';
      message = 'Confirm the estimate after adding ride-sharing passengers or baggage fees.';
    } else if (_filteredOnlineDriversList.isEmpty) {
      icon = Icons.local_taxi_outlined;
      backgroundColor = const Color(0xFFFFF7ED);
      foregroundColor = const Color(0xFFEA580C);
      title = 'No drivers online right now';
      message = 'Refresh the nearby driver list or try again after a moment.';
    } else {
      icon = Icons.check_circle_rounded;
      backgroundColor = const Color(0xFFECFDF5);
      foregroundColor = const Color(0xFF047857);
      title = 'Ready to book';
      message = 'Your trip details are complete. You can send the request now.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foregroundColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: foregroundColor.withOpacity(0.92),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingActionButton() {
    final dropOffLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
    final bool hasDrivers = _filteredOnlineDriversList.isNotEmpty;

    String label;
    IconData icon;

    if (dropOffLocation == null) {
      label = 'Complete Trip Details';
      icon = Icons.checklist_rounded;
    } else if (!_fareReviewed) {
      label = 'Review Fare First';
      icon = Icons.receipt_long_rounded;
    } else if (!hasDrivers) {
      label = 'No Drivers Available';
      icon = Icons.local_taxi_outlined;
    } else {
      label = 'Book Ride Now';
      icon = Icons.local_taxi_rounded;
    }

    return SizedBox(
      width: double.infinity,
      child: KalPrimaryButton(
        label: label,
        icon: icon,
        isLoading: _isSubmittingRideRequest,
        onPressed: _handleBookRideRequest,
      ),
    );
  }

  Widget _buildWaitingDriverBottomSheet(EdgeInsets mediaPadding) {
    return _buildSheetContainer(
      height: waitingResponseFromDriverContainerHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 14, 24, mediaPadding.bottom + 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 18),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: Color(0xFF2563EB),
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Looking for a nearby Ongbak',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'We are notifying the nearest available driver for your trip.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildInfoPill(
                  icon: Icons.local_taxi_rounded,
                  label: '${_filteredOnlineDriversList.length} online drivers',
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF0F172A),
                ),
                if (_estimatedFare != null)
                  _buildInfoPill(
                    icon: Icons.payments_rounded,
                    label: '₱${_estimatedFare!.toStringAsFixed(0)} est.',
                    backgroundColor: const Color(0xFFECFDF5),
                    foregroundColor: const Color(0xFF047857),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelRideAsCommuter,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.close_rounded),
                label: const Text(
                  'Cancel Request',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedDriverBottomSheet(EdgeInsets mediaPadding) {
    return _buildSheetContainer(
      height: assignedDriverInfoContainerHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, mediaPadding.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSheetHandle(),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Driver assigned',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          driverRideStatus,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDriverInfoItem('Vehicle', driverVehicleDetails),
                    const SizedBox(height: 10),
                    _buildDriverInfoItem('Driver', driverName),
                    const SizedBox(height: 10),
                    _buildDriverInfoItem('Contact', driverPhone),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF2563EB),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can call the driver now. The in-app chat button will also appear while the ride is active.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D4ED8),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String number = driverPhone;
                    await launch('tel:$number');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.phone_rounded, size: 20),
                  label: const Text(
                    'Call Driver',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _cancelRideAsCommuter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  label: const Text(
                    'Cancel Ride',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogInfoChip({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRuleRow({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }




  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRideOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOptionCard(
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xFF10B981),
          title: 'Ride Sharing',
          subtitle: 'Let the driver know if you are sharing the trip.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _buildRideSharingOption('No', 'no')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildRideSharingOption('Yes', 'yes')),
                ],
              ),
              if (_rideSharingChoice == 'yes') ...[
                const SizedBox(height: 14),
                Text(
                  'Number of passengers (₱${FareConfig.baseFare.toStringAsFixed(0)} per passenger)',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                NumberInputWithIncrementDecrement(
                  controller: _passengerCountController,
                  min: 1,
                  max: 4,
                  numberFieldDecoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    labelText: 'Passengers',
                    labelStyle: TextStyle(color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  widgetContainerDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  incIconDecoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  decIconDecoration: BoxDecoration(
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  incIcon: Icons.add_rounded,
                  decIcon: Icons.remove_rounded,
                  incIconColor: Colors.white,
                  decIconColor: Colors.white,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildOptionCard(
          icon: Icons.luggage_rounded,
          iconColor: const Color(0xFF2563EB),
          title: 'Additional Baggage',
          subtitle: 'Add extra bags so the driver can prepare enough space. Each bag adds ₱${FareConfig.baggageFare.toStringAsFixed(0)}.',
          child: NumberInputWithIncrementDecrement(
            controller: additionalController,
            min: 0,
            max: 10,
            numberFieldDecoration: const InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              labelText: 'Number of bags',
              labelStyle: TextStyle(color: Color(0xFF64748B)),
              filled: true,
              fillColor: Colors.white,
            ),
            widgetContainerDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            incIconDecoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            decIconDecoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            incIcon: Icons.add_rounded,
            decIcon: Icons.remove_rounded,
            incIconColor: Colors.white,
            decIconColor: Colors.white,
          ),
        ),
      ],
    );
  }



  Widget _buildRideSharingOption(String text, String value) {
    final bool isSelected = _rideSharingChoice == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _rideSharingChoice = value;
          _fareReviewed = false;
          if (value != 'yes') {
            _passengerCountController.text = '1';
          }
        });
        _updateEstimatedFareFromSelections();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildDriverInfoItem(String label, String value) {
    IconData icon;
    switch (label.toLowerCase()) {
      case 'vehicle':
        icon = Icons.directions_car_rounded;
        break;
      case 'driver':
        icon = Icons.person_rounded;
        break;
      case 'contact':
        icon = Icons.phone_rounded;
        break;
      default:
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  void _showBackToHomeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: Color(0xFF2563EB),
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Back to main booking screen?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'This clears your current destination and returns you to the default commuter view.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Stay here'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        resetToMainScreen();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Go back'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }


  // Add this method after _showBackToHomeDialog() method

  void _showCancelOrExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'You still have an active ride',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'For a smoother rider experience, cancel the ride only if you are sure you no longer need it.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _cancelRideAsCommuter();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel ride'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Keep current ride',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildDriverCountIndicator() {
    return Positioned(
      top: 170,
      right: 20,
      child: _buildInfoPill(
        icon: Icons.local_taxi_rounded,
        label: 'Drivers: ${_filteredOnlineDriversList.length}',
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
      ),
    );
  }


  //Visual poly line
  Future<void> drawPolyLineFromOriginToDestination() async {
    var originPosition =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Please wait...",
      ),
    );

    var directionDetailsInfo =
    await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        originLatLng, destinationLatLng);

    setState(() {
      tripDirectionDetailsInfo = directionDetailsInfo;
      _fareDistanceText = directionDetailsInfo?.distance_text ?? "";
      _fareDurationText = directionDetailsInfo?.duration_text ?? "";

      if (directionDetailsInfo != null) {
        final fareBreakdown = AssistantMethods.calculateFareBreakdown(
          distanceInMeters: directionDetailsInfo.distance_value ?? 0,
        );

        _baseEstimatedFare =
        fareBreakdown.isOutOfRange ? null : fareBreakdown.totalFare;
        _estimatedFare = fareBreakdown.isOutOfRange
            ? null
            : _baseEstimatedFare! + _calculateOptionSurcharge();
        _fareReviewed = false;

        if (fareBreakdown.isOutOfRange && mounted) {
          Fluttertoast.showToast(
            msg: fareBreakdown.explanation,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        _baseEstimatedFare = null;
        _estimatedFare = null;
        _fareReviewed = false;
      }
    });

    Navigator.pop(context);

    // ===== NEW: show fare review AFTER plotting polyline =====
    if (directionDetailsInfo != null && _estimatedFare != null) {
      await _showFareReviewDialog();
    }
//this value  to be taken and use for the polly lines
    print("These are points = ");
    print(directionDetailsInfo!.e_points);

    PolylinePoints pPoints = PolylinePoints(apiKey: '');
    List<PointLatLng> decodedPolyLinePointsResultList =
    PolylinePoints.decodePolyline(directionDetailsInfo!.e_points!);

    pLineCoOrdinatesList.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoOrdinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    polyLineSet.clear();
//poly line design
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: const PolylineId("PolylineID"),
        width: 4,
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });

//To animate the full screen view from picup to drop
    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

//Markers or icon showing the point of pic up to destination.
    Marker originMarker = Marker(
      markerId: const MarkerId("originID"),
      infoWindow:
      InfoWindow(title: originPosition.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId("destinationID"),
      infoWindow: InfoWindow(
          title: destinationPosition.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      markersSet.add(originMarker);
      markersSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId("originID"),
      fillColor: Colors.blue,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId("destinationID"),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
  }

//Query of the driver location
  void initializeGeoFireListener() {
    Geofire.initialize("activeDrivers");

    // First, listen to all drivers to get their details
    _listenForAllDriversDetails();

    Geofire.queryAtLocation(
        userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        switch (callBack) {
          case Geofire.onKeyEntered:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
            ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeoFireAssistant.activeNearbyAvailableDriversList
                .add(activeNearbyAvailableDriver);
            _updateFilteredOnlineDrivers();
            if (activeNearbyDriverKeysLoaded == true) {
              displayActiveDriversOnUsersMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map['key']);
            _updateFilteredOnlineDrivers();
            displayActiveDriversOnUsersMap();
            break;

          case Geofire.onKeyMoved:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
            ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeoFireAssistant.updateActiveNearbyAvailableDriverLocation(
                activeNearbyAvailableDriver);
            _updateFilteredOnlineDrivers();
            displayActiveDriversOnUsersMap();
            break;

          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            _updateFilteredOnlineDrivers();
            displayActiveDriversOnUsersMap();
            break;
        }
      }

      setState(() {});
    });
  }

// Add this method to listen for all drivers details
  void _listenForAllDriversDetails() {
    DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers");

    _driversDetailsSubscription = driversRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> driversMap = event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          _allDriversDetails = Map<String, dynamic>.from(driversMap);
          _updateFilteredOnlineDrivers();
        });
      }
    });
  }

// Add this method to filter only online available drivers
  void _updateFilteredOnlineDrivers() {
    if (_allDriversDetails.isEmpty) return;

    _filteredOnlineDriversList = GeoFireAssistant.activeNearbyAvailableDriversList.where((driver) {
      // Check if driver exists in the drivers details
      if (_allDriversDetails.containsKey(driver.driverId)) {
        final driverDetails = _allDriversDetails[driver.driverId!];

        // Check if driver details is actually a Map
        if (driverDetails is! Map) return false;

        final driverDetailsMap = Map<dynamic, dynamic>.from(driverDetails);

        // Check if driver is online - adjust based on your actual field names
        final isOnline = driverDetailsMap["is_online"] == true ||
            driverDetailsMap["online"] == true ||
            driverDetailsMap["newRideStatus"] == "idle" ||
            driverDetailsMap["status"] == "online";

        return isOnline;
      }
      return false;
    }).toList();

    setState(() {
      onlineNearByAvailableDriversList = _filteredOnlineDriversList;
    });

    // Force refresh of markers after updating the list
    displayActiveDriversOnUsersMap();
  }


  displayActiveDriversOnUsersMap() {
    setState(() {
      markersSet.removeWhere((marker) => marker.markerId.value.startsWith('driver'));

      Set<Marker> driversMarkerSet = Set<Marker>();

      // Use onlineNearByAvailableDriversList which should contain the filtered drivers
      for (ActiveNearbyAvailableDrivers eachDriver in onlineNearByAvailableDriversList) {
        // Add null check for driver position
        if (eachDriver.locationLatitude == null || eachDriver.locationLongitude == null) {
          continue; // Skip drivers with null positions
        }

        LatLng eachDriverActivePosition =
        LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        // Only add marker if we have the icon loaded
        if (activeNearbyIcon != null) {
          Marker marker = Marker(
            markerId: MarkerId("driver" + eachDriver.driverId!),
            position: eachDriverActivePosition,
            icon: activeNearbyIcon!,
          );

          driversMarkerSet.add(marker);
        }
      }

      markersSet.addAll(driversMarkerSet);
    });
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
      createLocalImageConfiguration(context, size: const Size(4, 4));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
  }
  void resetToMainScreen() {
    setState(() {
      isWaitingForDriverResponse = false;
      // Reset all UI states to initial values
      searchLocationContainerHeight = 400;
      waitingResponseFromDriverContainerHeight = 0;
      assignedDriverInfoContainerHeight = 0;
      driverRideStatus = "Driver is Coming";
      userRideRequestStatus = "";

      // Clear map elements
      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoOrdinatesList.clear();

      // Clear driver tracking
      _currentDriverPosition = null;
      _driverPositionTimer?.cancel();
      _driverLocationStreamSubscription?.cancel();

      // Reset ride sharing choices
      _rideSharingChoice = "no";
      _passengerCountController.text = "1";
      additionalController.text = "0";
      discountTemp = "";
      _value = "";

      // Clear chat
      _isChatOpen = false;
      _chatMessages.clear();
      _messageController.clear();
      _chatSubscription?.cancel();

      // Clear provider data
      Provider.of<AppInfo>(context, listen: false).userDropOffLocation = null;

      // Reset drawer state
      openNavigationDrawer = true;
      _isSubmittingRideRequest = false;

      // Cancel Firebase subscriptions
      referenceRideRequest = null;
      tripRideRequestInfoStreamSubscription?.cancel();

      // Relocate user position
      locateUserPosition();
    });

    // Show a message that trip was completed
    Fluttertoast.showToast(
      msg: "Trip completed successfully!",
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Future<int> _getTodayCancellationCount() async {
    if (currentFirebaseUser == null) return 0;

    final snapshot = await FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentFirebaseUser!.uid)
        .child("cancellationMeta")
        .get();

    if (snapshot.value == null) return 0;

    final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
    final dateKey = DateTime.now().toIso8601String().split('T').first;
    final savedDate = data['date']?.toString();
    if (savedDate != dateKey) return 0;

    return int.tryParse(data['count']?.toString() ?? '0') ?? 0;
  }

  Future<void> _incrementTodayCancellationCount() async {
    if (currentFirebaseUser == null) return;

    final count = await _getTodayCancellationCount();
    final dateKey = DateTime.now().toIso8601String().split('T').first;

    await FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(currentFirebaseUser!.uid)
        .child("cancellationMeta")
        .set({
      'date': dateKey,
      'count': count + 1,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<void> _openCancellationFeedbackScreen() async {
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackScreen()),
    );
  }

  // Add this method after resetToMainScreen() method
  Future<void> _cancelRideAsCommuter() async {
    if (referenceRideRequest == null) {
      Fluttertoast.showToast(msg: "No active ride to cancel");
      return;
    }

    final todayCancellationCount = await _getTodayCancellationCount();
    if (todayCancellationCount >= _dailyCancellationLimit) {
      Fluttertoast.showToast(
        msg: "Daily cancellation limit reached. Please contact support if needed.",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cancel Ride?"),
        content: Text("Are you sure you want to cancel this ride? You have ${_dailyCancellationLimit} allowed cancellations per day, and feedback is required after cancellation."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => ProgressDialog(message: "Cancelling ride..."),
    );

    try {
      print("🚗 Commuter cancelling ride...");

      // Get ride request ID
      String rideRequestId = referenceRideRequest!.key!;

      // 1. Update ride status to cancelled
      await FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(rideRequestId)
          .update({
        "status": "cancelled",
        "cancelled_by": "commuter",
        "cancelled_at": ServerValue.timestamp,
        "cancellation_reason": "Commuter cancelled the ride",
        "feedbackRequired": true,
        "dailyCancellationCountAfterThis": todayCancellationCount + 1,
      });

      // 2. Clean up subscriptions
      tripRideRequestInfoStreamSubscription?.cancel();
      _driverLocationStreamSubscription?.cancel();
      _driverPositionTimer?.cancel();
      _chatSubscription?.cancel();

      // 3. Send notification to driver (fire and forget - don't wait)
      _sendCancellationNotificationToDriver(rideRequestId);
      await _incrementTodayCancellationCount();

      // 4. Close loading dialog if still mounted
      if (mounted) {
        Navigator.pop(context);
      }

      // 5. Show success message
      Fluttertoast.showToast(
        msg: "Ride cancelled successfully",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // 6. Reset to main screen
      resetToMainScreen();
      await _openCancellationFeedbackScreen();

    } catch (error) {
      // Close loading dialog if still mounted
      if (mounted) {
        Navigator.pop(context);
      }

      print("❌ Error cancelling ride: $error");
      Fluttertoast.showToast(
        msg: "Failed to cancel ride",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

// Add this method right after _cancelRideAsCommuter()
  Future<void> _sendCancellationNotificationToDriver(String rideRequestId) async {
    try {
      print("📱 [COMMUTER] Sending cancellation notification to driver...");

      // Get ride request data
      DatabaseReference rideRequestRef = FirebaseDatabase.instance.ref()
          .child("All Ride Requests")
          .child(rideRequestId);

      DataSnapshot rideSnapshot = await rideRequestRef.get();

      if (rideSnapshot.value != null) {
        Map<dynamic, dynamic> rideData = rideSnapshot.value as Map<dynamic, dynamic>;

        String? driverId = rideData['driverId']?.toString();
        String? driverName = rideData['driverName']?.toString();

        print("📱 [COMMUTER] Driver ID: $driverId, Driver Name: $driverName");

        if (driverId != null && driverId != "waiting") {
          // 1. Update driver's newRideStatus to "idle" FIRST
          print("📱 [COMMUTER] Updating driver status to idle...");
          await FirebaseDatabase.instance.ref()
              .child("drivers")
              .child(driverId)
              .child("newRideStatus")
              .set("idle");

          // 2. Get driver's device token
          print("📱 [COMMUTER] Getting driver token...");
          DatabaseReference driverTokenRef = FirebaseDatabase.instance.ref()
              .child("drivers")
              .child(driverId)
              .child("token");

          DataSnapshot tokenSnapshot = await driverTokenRef.get();

          if (tokenSnapshot.value != null) {
            String deviceToken = tokenSnapshot.value.toString();
            print("📱 [COMMUTER] Driver token found: ${deviceToken.substring(0, 20)}...");

            // 3. Send FCM notification
            try {
              print("📱 [COMMUTER] Getting FCM access token...");
              final accessToken = await AssistantMethods.getAccessToken();

              if (accessToken.isNotEmpty) {
                print("📱 [COMMUTER] Sending FCM request...");
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
                      "body": "The commuter has cancelled the ride."
                    },
                    "data": {
                      "click_action": "FLUTTER_NOTIFICATION_CLICK",
                      "rideRequestId": rideRequestId,
                      "status": "cancelled",
                      "cancelled_by": "commuter",
                      "action": "ride_cancelled", // Add this for driver app to handle
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
                  print("✅ [COMMUTER] FCM notification sent successfully to driver");
                } else {
                  print("⚠️ [COMMUTER] FCM returned ${response.statusCode}: ${response.body}");
                }
              } else {
                print("⚠️ [COMMUTER] Failed to get FCM access token");
              }
            } catch (fcmError) {
              print("⚠️ [COMMUTER] FCM error: $fcmError");
            }
          } else {
            print("⚠️ [COMMUTER] No device token found for driver");
          }

          // 4. Also update the ride request with cancellation details
          print("📱 [COMMUTER] Updating ride request with cancellation details...");
          await rideRequestRef.update({
            "status": "cancelled",
            "cancelled_by": "commuter",
            "cancelled_at": ServerValue.timestamp,
            "cancellation_reason": "Commuter cancelled the ride",
            "cancellation_notified": true,
          });

          print("✅ [COMMUTER] Driver notification process completed");
        } else {
          print("⚠️ [COMMUTER] No valid driver ID found or driver not assigned yet");
        }
      } else {
        print("⚠️ [COMMUTER] Ride request not found");
      }
    } catch (error) {
      print("❌ [COMMUTER] Error in cancellation notification: $error");
      print("❌ [COMMUTER] Stack trace: ${StackTrace.current}");
    }
  }

  // Add this method to listen for driver cancellations
  void _listenForDriverCancellation() {
    if (referenceRideRequest == null) return;

    String rideRequestId = referenceRideRequest!.key!;

    DatabaseReference rideRequestRef = FirebaseDatabase.instance.ref()
        .child("All Ride Requests")
        .child(rideRequestId);

    // Listen for status changes (specifically for "cancelled" status)
    rideRequestRef.child("status").onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null && mounted) {
        String status = event.snapshot.value.toString();
        print("👤 [COMMUTER] Ride status changed to: $status");

        if (status == "cancelled") {
          print("👤 [COMMUTER] Ride cancelled by driver!");

          // Get cancellation details
          rideRequestRef.child("cancelled_by").once().then((cancelledBySnapshot) {
            String cancelledBy = cancelledBySnapshot.snapshot.value?.toString() ?? "unknown";

            // Only show if cancelled by driver (not by commuter themselves)
            if (cancelledBy == "driver") {
              _showRideCancelledByDriverDialog();
            }
          });
        }
      }
    });

    // Also listen for specific cancellation notification flag
    rideRequestRef.child("cancellation_notified").onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null && event.snapshot.value == true && mounted) {
        print("👤 [COMMUTER] Received cancellation notification flag");

        // Check who cancelled
        rideRequestRef.child("cancelled_by").once().then((cancelledBySnapshot) {
          String cancelledBy = cancelledBySnapshot.snapshot.value?.toString() ?? "unknown";

          if (cancelledBy == "driver") {
            _showRideCancelledByDriverDialog();
          }
        });
      }
    });
  }

// Add this dialog method for driver cancellation
  void _showRideCancelledByDriverDialog() {
    // Prevent showing multiple dialogs
    if (!mounted) return;

    // Cancel any active subscriptions
    tripRideRequestInfoStreamSubscription?.cancel();
    _driverLocationStreamSubscription?.cancel();
    _driverPositionTimer?.cancel();
    _chatSubscription?.cancel();

    // Show a snackbar instead of dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Driver has declined the ride request"),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    // Return to main screen after a short delay
    Future.delayed(Duration(milliseconds: 2000), () {
      if (mounted) {
        _returnToMainScreenAfterDriverCancellation();
      }
    });
  }

// Add this method to return to main screen after driver cancellation
  void _returnToMainScreenAfterDriverCancellation() {
    if (!mounted) return;

    // Clean up all subscriptions
    tripRideRequestInfoStreamSubscription?.cancel();
    _driverLocationStreamSubscription?.cancel();
    _driverPositionTimer?.cancel();
    _chatSubscription?.cancel();

    // Reset all UI states
    setState(() {
      isWaitingForDriverResponse = false;
      searchLocationContainerHeight = 400;
      waitingResponseFromDriverContainerHeight = 0;
      assignedDriverInfoContainerHeight = 0;
      driverRideStatus = "Driver is Coming";
      userRideRequestStatus = "";

      // Clear map elements
      polyLineSet.clear();
      markersSet.clear();
      circlesSet.clear();
      pLineCoOrdinatesList.clear();

      // Clear chat
      _isChatOpen = false;
      _chatMessages.clear();
      _messageController.clear();

      // Reset drawer state
      openNavigationDrawer = true;
    });

    // Show toast message
    Fluttertoast.showToast(
      msg: "Ride cancelled by driver. Please book another ride.",
      backgroundColor: Colors.blue,
      textColor: Colors.white,
    );

    // No need to navigate since we're already on MainScreen
    // Just reset the UI state
  }

  void _initializeDriverIcon() {
    if (_driverIcon == null) {
      ImageConfiguration imageConfiguration = createLocalImageConfiguration(context, size: const Size(4, 4));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png").then((value) {
        setState(() {
          _driverIcon = value;
        });
      });
    }
  }

  void _startDriverPositionTracking(LatLng driverStartPosition, LatLng destination) async {
    // First, draw the initial route
    await _updateDriverRoutePolyline(driverStartPosition, destination);

    // Set current driver position
    setState(() {
      _currentDriverPosition = driverStartPosition;
    });

    // Initialize driver icon
    _initializeDriverIcon();

    // Start tracking real driver location from Firebase
    _startRealTimeDriverTracking();
  }

  bool _shouldRefreshDriverRoute(LatLng current) {
    final now = DateTime.now();

    if (_lastDriverRouteRefreshAt == null || _lastDriverRouteRefreshOrigin == null) {
      _lastDriverRouteRefreshAt = now;
      _lastDriverRouteRefreshOrigin = current;
      return true;
    }

    final movedMeters = Geolocator.distanceBetween(
      _lastDriverRouteRefreshOrigin!.latitude,
      _lastDriverRouteRefreshOrigin!.longitude,
      current.latitude,
      current.longitude,
    );

    final secondsPassed = now.difference(_lastDriverRouteRefreshAt!).inSeconds;

    if (movedMeters >= 80 || secondsPassed >= 10) {
      _lastDriverRouteRefreshAt = now;
      _lastDriverRouteRefreshOrigin = current;
      return true;
    }

    return false;
  }

  void _startRealTimeDriverTracking() {
    _driverLocationStreamSubscription?.cancel();

    if (referenceRideRequest != null) {
      _driverLocationStreamSubscription = referenceRideRequest!
          .child("driverLocation")
          .onValue
          .listen((event) {
        if (event.snapshot.value == null) return;

        final driverLocationData =
        Map<String, dynamic>.from(event.snapshot.value as Map);

        final driverLat =
        double.parse(driverLocationData["latitude"].toString());
        final driverLng =
        double.parse(driverLocationData["longitude"].toString());

        final newDriverPosition = LatLng(driverLat, driverLng);

        setState(() {
          _currentDriverPosition = newDriverPosition;
        });

        _updateDriverMarker(newDriverPosition);

        if (_shouldRefreshDriverRoute(newDriverPosition)) {
          _updateDriverRouteBasedOnCurrentPosition(newDriverPosition);
        }
      });
    }
  }

  void _updateDriverRouteBasedOnCurrentPosition(LatLng driverPosition) {
    if (userRideRequestStatus == "accepted") {
      // Driver is coming to pick up location
      LatLng userPickUpPosition = LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      _updateDriverRoutePolyline(driverPosition, userPickUpPosition);
    } else if (userRideRequestStatus == "ontrip") {
      // Driver is going to destination
      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
      if (dropOffLocation != null) {
        LatLng userDestinationPosition = LatLng(
            dropOffLocation.locationLatitude!,
            dropOffLocation.locationLongitude!
        );
        _updateDriverRoutePolyline(driverPosition, userDestinationPosition);
      }
    }
  }

  Future<void> _updateDriverRoutePolyline(LatLng origin, LatLng destination) async {
    var directionDetailsInfo = await AssistantMethods.obtainOriginToDestinationDirectionDetails(origin, destination);

    if (directionDetailsInfo == null) {
      return;
    }

    PolylinePoints pPoints = PolylinePoints(apiKey: '');
    List<PointLatLng> decodedPolyLinePointsResultList = PolylinePoints.decodePolyline(directionDetailsInfo.e_points!);

    pLineCoOrdinatesList.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        pLineCoOrdinatesList.add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }

    setState(() {
      polyLineSet.removeWhere((polyline) => polyline.polylineId.value == "DriverRoute");

      Polyline polyline = Polyline(
        color: Colors.green, // Different color for driver's route
        polylineId: PolylineId("DriverRoute"),
        width: 5,
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
    });
  }


// NEW METHOD: Simulate driver movement (replace with real Firebase updates in production)
  void _startDriverMovementSimulation(LatLng startPosition, LatLng endPosition) {
    // Clear any existing timer
    _driverPositionTimer?.cancel();

    // This simulates driver movement - in real app, you'd get this from Firebase
    int step = 0;
    final totalSteps = pLineCoOrdinatesList.length;

    _driverPositionTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (step < totalSteps) {
        setState(() {
          _currentDriverPosition = pLineCoOrdinatesList[step];

          // Update driver marker
          _updateDriverMarker(_currentDriverPosition!);
        });
        step++;
      } else {
        timer.cancel();
      }
    });
  }

// NEW METHOD: Update driver marker on map
  void _updateDriverMarker(LatLng position) {
    // Remove existing driver marker
    markersSet.removeWhere((marker) => marker.markerId.value == "driverCurrentPosition");

    if (_driverIcon != null) {
      Marker driverMarker = Marker(
        markerId: MarkerId("driverCurrentPosition"),
        position: position,
        icon: _driverIcon!,
        infoWindow: InfoWindow(title: "Your Driver", snippet: "Currently $driverRideStatus"),
      );

      setState(() {
        markersSet.add(driverMarker);
      });
    }
  }

// Helper method to calculate driver rotation (optional)
  double _getDriverRotation(LatLng newPosition) {
    // Simple rotation calculation - you can improve this based on direction
    return 0.0;
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
    _driversDetailsSubscription?.cancel();
    tripRideRequestInfoStreamSubscription?.cancel();
    _driverPositionTimer?.cancel();
    _driverLocationStreamSubscription?.cancel();
    _chatSubscription?.cancel();
    _messageController.dispose();
    _chatScrollController.dispose();
    _passengerCountController.removeListener(_handleFareOptionChanged);
    additionalController.removeListener(_handleFareOptionChanged);
    _passengerCountController.dispose();
    _chatFocusNode.dispose(); // FIXED: Dispose focus node
    _commuterAppInfo.dispose();
    super.dispose();
  }
}
