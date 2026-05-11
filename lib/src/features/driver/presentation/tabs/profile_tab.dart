import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/screens/splash_screen.dart';
import 'package:kaltrike_driver_app/src/features/driver/config/global.dart';
import 'package:kaltrike_driver_app/src/features/driver/presentation/widgets/info_design_ui.dart';

class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({Key? key}) : super(key: key);

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleColorController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _nameController.text = onlineDriverData.name ?? '';
    _phoneController.text = onlineDriverData.phone ?? '';
    _vehicleColorController.text = onlineDriverData.vehicle_color ?? '';
    _vehicleModelController.text = onlineDriverData.vehicle_model ?? '';
    _plateNumberController.text = onlineDriverData.plate_number ?? '';
    _emailController.text = onlineDriverData.email ?? '';
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Update in Realtime Database
      DatabaseReference driverRef = FirebaseDatabase.instance.ref().child("drivers").child(currentFirebaseUser!.uid);

      // ONLY update name and phone - ALL vehicle fields are restricted
      Map<String, dynamic> updateData = {
        "name": _nameController.text.trim(),
        "phone": _phoneController.text.trim(),
        // ALL vehicle fields are now restricted and not included in update
      };

      // Update database
      await driverRef.update(updateData);

      // Refresh local data - only update name and phone
      setState(() {
        onlineDriverData.name = _nameController.text.trim();
        onlineDriverData.phone = _phoneController.text.trim();
        // Do not update any vehicle fields as they are restricted
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile updated successfully!"),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      setState(() {
        _isEditing = false;
      });
    } catch (error) {
      String errorMessage = "Error updating profile: $error";

      if (error is FirebaseAuthException) {
        switch (error.code) {
          case 'requires-recent-login':
            errorMessage = "Session expired. Please log out and log in again.";
            break;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers if canceling edit
        _loadUserData();
      }
    });
  }

  Widget _buildEditableField(String label, TextEditingController controller,
      TextInputType keyboardType, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF2563EB),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF2563EB),
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          filled: !_isEditing,
          fillColor: _isEditing ? Colors.transparent : const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  // Updated to use for ALL vehicle fields
  Widget _buildRestrictedField(String label, TextEditingController controller,
      TextInputType keyboardType, IconData icon, String restrictionMessage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: false, // Always disabled
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Color(0xFF64748B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey.shade500,
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: IconButton(
            icon: Icon(Icons.info_outline_rounded, color: Colors.grey.shade500, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(restrictionMessage),
                  backgroundColor: const Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            tooltip: "This field cannot be changed",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Modern Gradient Header
                Container(
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Avatar
                          Container(
                            width: 100,
                            height: 100,
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
                            child: const Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            onlineDriverData.name ?? 'Driver',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$titleStarsRating Driver",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Edit/Save Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (!_isEditing)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade600.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: _toggleEditMode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                            label: const Text(
                              "Edit Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Profile Information Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Personal Information",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildEditableField("Full Name", _nameController,
                            TextInputType.name, Icons.person_rounded),
                        const SizedBox(height: 16),
                        _buildEditableField("Phone Number", _phoneController,
                            TextInputType.phone, Icons.phone_rounded),
                        const SizedBox(height: 16),
                        _buildRestrictedField(
                            "Email Address",
                            _emailController,
                            TextInputType.emailAddress,
                            Icons.email_rounded,
                            "Email address cannot be changed. Please contact support if needed."
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Vehicle Information Card - ALL FIELDS RESTRICTED
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.electric_rickshaw_rounded,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Vehicle Information",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.lock_outline_rounded, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    "Restricted",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "All vehicle information is restricted and cannot be changed.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildRestrictedField(
                            "Vehicle Color",
                            _vehicleColorController,
                            TextInputType.text,
                            Icons.color_lens_rounded,
                            "Vehicle color cannot be changed. Please contact support if needed."
                        ),
                        const SizedBox(height: 16),
                        _buildRestrictedField(
                            "Vehicle Model",
                            _vehicleModelController,
                            TextInputType.text,
                            Icons.electric_rickshaw_rounded,
                            "Vehicle model cannot be changed. Please contact support if needed."
                        ),
                        const SizedBox(height: 16),
                        _buildRestrictedField(
                            "Plate Number",
                            _plateNumberController,
                            TextInputType.text,
                            Icons.confirmation_number_rounded,
                            "Plate number cannot be changed. Please contact support if needed."
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  // Save/Cancel Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _toggleEditMode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF64748B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updateProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Save Changes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => _showLogoutDialog(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: const Color(0xFFEF4444)),
                          const SizedBox(width: 12),
                          const Text(
                            "Log Out",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
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
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Log Out?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to log out?",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF64748B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        fAuth.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const MySplashScreen()),
                              (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Log Out"),
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleColorController.dispose();
    _vehicleModelController.dispose();
    _plateNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}