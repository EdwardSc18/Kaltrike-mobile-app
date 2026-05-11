import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/core/utils/responsive.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/auth/presentation/screens/login_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/validation_screen.dart';

class CarInfoScreen extends StatefulWidget {
  final String permitNumber;

  const CarInfoScreen({required this.permitNumber});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  TextEditingController plateNumberTextEditingController = TextEditingController();
  TextEditingController vehiclePermitTextEditingController = TextEditingController();

  List<String> carTypeList = ["OngBack", "Tricycle"];
  List<String> vehicleColorList = [
    "Red",
    "Blue",
    "Black",
    "White",
    "Green",
    "Yellow",
  ];
  List<String> vehicleModelList = ["Bajaj", "TVS", "Piaggio"];

  String? selectedCarType;
  String? selectedVehicleColor;
  String? selectedVehicleModel;

  double? get subtitleSize => null;

  saveCarInfo() {
    if (selectedCarType == null) {
      Fluttertoast.showToast(msg: "Please select vehicle type");
      return;
    }

    if (selectedVehicleColor == null) {
      Fluttertoast.showToast(msg: "Please select vehicle color");
      return;
    }

    if (selectedVehicleModel == null) {
      Fluttertoast.showToast(msg: "Please select vehicle model");
      return;
    }

    Map driverCarInfoMap = {
      "vehicle_color": selectedVehicleColor,
      "plate_number": plateNumberTextEditingController.text.trim(),
      "vehicle_model": selectedVehicleModel,
      "vehicle_permit": vehiclePermitTextEditingController.text.trim(),
      "type": selectedCarType,
    };

    DatabaseReference driversRef = FirebaseDatabase.instance.ref().child("drivers");

    driversRef.child(currentFirebaseUser!.uid).update({
      "vechicle_details": driverCarInfoMap,
      "isProfileCompleted": true,
      "updatedAt": DateTime.now().millisecondsSinceEpoch,
    }).then((_) async {
      await FirebaseDatabase.instance.ref()
          .child("drivers")
          .child(currentFirebaseUser!.uid)
          .child("newRideStatus")
          .set("idle");

      await currentFirebaseUser?.reload();
      await Future.delayed(const Duration(milliseconds: 300));
      await FirebaseAuth.instance.signOut();
      currentFirebaseUser = null;

      Fluttertoast.showToast(msg: "Vehicle details saved successfully! Please log in to continue.");

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (c) => ValidationScreen()),
            (route) => false,
      );
    }).catchError((_) {
      Fluttertoast.showToast(msg: "Failed to save vehicle details. Please try again.");
    });
  }

  @override
  Widget build(BuildContext context) {
    final r = context.r;
    final headerHeight = r.hp(0.34, min: 240, max: 300);
    final logoSize = r.wp(0.26, min: 84, max: 110);
    final logoInnerSize = logoSize * 0.6;
    final titleSize = r.sp(32, minFactor: 0.9, maxFactor: 1.08);
    final subtitleSize = r.sp(16, minFactor: 0.9, maxFactor: 1.05);
    final pageGap = r.hp(0.04, min: 28, max: 42);
    final horizontalMargin = r.wp(0.06, min: 18, max: 28);
    final cardPadding = r.wp(0.08, min: 22, max: 32);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// Modern Gradient Header
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A), // Deep navy blue
                    Color(0xFF2563EB), // Vibrant blue
                    Color(0xFF60A5FA), // Light blue
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Logo Container
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade900.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          "images/icon.png",
                          width: logoInnerSize,
                          height: logoInnerSize,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    SizedBox(height: r.hp(0.024, min: 16, max: 22)),
                    Text(
                      "Vehicle Details",
                      style: TextStyle(
                        fontSize: titleSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Complete your driver profile with vehicle information",
                      style: TextStyle(
                        fontSize: subtitleSize,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: pageGap),

            /// Modern Vehicle Form Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.4),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  /// Vehicle Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Vehicle Type",
                      labelStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.directions_car_rounded,
                        color: Colors.grey.shade600,
                        size: r.sp(22),
                      ),
                    ),
                    value: selectedCarType,
                    items: carTypeList.map((car) {
                      return DropdownMenuItem(
                        value: car,
                        child: Text(
                          car,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedCarType = newValue;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                  /// Vehicle Color Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Vehicle Color",
                      labelStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.color_lens_rounded,
                        color: Colors.grey.shade600,
                        size: r.sp(22),
                      ),
                    ),
                    value: selectedVehicleColor,
                    items: vehicleColorList.map((color) {
                      return DropdownMenuItem(
                        value: color,
                        child: Text(
                          color,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedVehicleColor = newValue;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                  /// Plate Number Field
                  _buildTextField(
                    controller: plateNumberTextEditingController,
                    label: "Plate Number",
                    hint: "ABC-1234",
                    icon: Icons.confirmation_number_rounded,
                  ),
                  SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                  /// Vehicle Permit Field
                  _buildTextField(
                    controller: vehiclePermitTextEditingController,
                    label: "Vehicle Permit Number",
                    hint: "Enter permit number",
                    icon: Icons.badge_rounded,
                  ),
                  SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                  /// Vehicle Model Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Vehicle Model",
                      labelStyle: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      floatingLabelStyle: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: EdgeInsets.symmetric(horizontal: r.wp(0.05, min: 18, max: 20), vertical: r.hp(0.022, min: 16, max: 18)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF2563EB),
                          width: 2,
                        ),
                      ),
                      prefixIcon: Icon(
                        Icons.two_wheeler_rounded,
                        color: Colors.grey.shade600,
                        size: r.sp(22),
                      ),
                    ),
                    value: selectedVehicleModel,
                    items: vehicleModelList.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(
                          model,
                          style: TextStyle(
                            fontSize: subtitleSize,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedVehicleModel = newValue;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    dropdownColor: Colors.white,
                    icon: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade600.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          if (selectedVehicleColor != null &&
                              plateNumberTextEditingController.text.isNotEmpty &&
                              selectedVehicleModel != null &&
                              vehiclePermitTextEditingController.text.isNotEmpty &&
                              selectedCarType != null) {
                            saveCarInfo();
                          } else {
                            Fluttertoast.showToast(
                                msg: "Please fill all fields");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "Save Vehicle Details",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: r.hp(0.024, min: 16, max: 22)),

                  /// Progress Indicator
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: 1.0, // Complete progress for this step
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2563EB),
                          ),
                          borderRadius: BorderRadius.circular(10),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Step 2 of 2",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: pageGap),

            /// Footer Note
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Your vehicle information helps us provide better service to commuters",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// Modern Text Field Builder (for text input fields)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontSize: subtitleSize,
        color: const Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF2563EB),
            width: 2,
          ),
        ),
        prefixIcon: Icon(
          icon,
          color: Colors.grey.shade600,
          size: (22),
        ),
      ),
    );
  }
}