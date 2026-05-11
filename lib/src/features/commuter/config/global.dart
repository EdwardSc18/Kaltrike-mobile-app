import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/models/direction_details_info.dart';
import 'package:kaltrike_driver_app/src/features/commuter/models/user_model.dart';

final auth.FirebaseAuth fAuth = auth.FirebaseAuth.instance;
auth.User? currentFirebaseUser;
UserModel? userModelCurrentInfo;

// ✅ Database reference for drivers (used in Profile update)
final DatabaseReference driversRef =
FirebaseDatabase.instance.ref().child("users");

List dList = []; // Online or active drivers key list of information
DirectionDetailsInfo? tripDirectionDetailsInfo;
String chosenDriverId = "";
String userDropOffAddress = "";
String driverVehicleDetails = "";
String driverName = "";
String driverPhone = "";
double countRatingStars = 0.0;

TextEditingController additionalController = TextEditingController();

// ✅ NO DISCOUNT ALWAYS (fixed)
String discountTemp = ""; // keep as empty, do not apply any discount

String titleStarsRating = "";
