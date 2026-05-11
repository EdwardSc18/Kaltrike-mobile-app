import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController =
  TextEditingController(text: userModelCurrentInfo!.name!);
  final TextEditingController _phoneController =
  TextEditingController(text: userModelCurrentInfo!.phone!);
  final TextEditingController _emailController =
  TextEditingController(text: userModelCurrentInfo!.email!);

  bool _isLoading = false;

  // Blue color palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkBlue = Color(0xFF1E40AF);
  static const Color lightBlue = Color(0xFF60A5FA);
  static const Color paleBlue = Color(0xFFDBEAFE);
  static const Color backgroundBlue = Color(0xFFF0F7FF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textLight = Color(0xFF6B7280);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  void _showEditDialog() {
    final TextEditingController _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [darkBlue, primaryBlue],
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Edit Profile",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Update your personal information",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // Dialog Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildEditField(
                        controller: _nameController,
                        label: "Full Name",
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      _buildEditField(
                        controller: _phoneController,
                        label: "Phone Number",
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textLight,
                                backgroundColor: Colors.transparent,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _updateProfile(_passwordController),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                shadowColor: primaryBlue.withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_rounded, size: 20),
                                  SizedBox(width: 8),
                                  Text("Save"),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontSize: 16,
        color: textDark,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: textLight,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryBlue,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: paleBlue.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 2,
          ),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 16, right: 12),
          child: Icon(
            icon,
            color: primaryBlue,
            size: 22,
          ),
        ),
        suffixIcon: controller.text.isNotEmpty
            ? Icon(
          Icons.check_circle_rounded,
          color: successGreen,
        )
            : null,
      ),
    );
  }

  Future<void> _updateProfile(TextEditingController passwordController) async {
    setState(() {
      _isLoading = true;
    });

    try {
      setState(() {
        userModelCurrentInfo!.name = _nameController.text.trim();
        userModelCurrentInfo!.phone = _phoneController.text.trim();
      });

      final auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Re-authenticate if password is provided
        if (passwordController.text.isNotEmpty) {
          final cred = auth.EmailAuthProvider.credential(
            email: currentUser.email!,
            password: passwordController.text.trim(),
          );
          await currentUser.reauthenticateWithCredential(cred);
        }

        // Update Firebase Authentication display name
        await currentUser.updateDisplayName(userModelCurrentInfo!.name!);

        // Update Realtime Database
        await driversRef.child(currentUser.uid).update({
          "name": userModelCurrentInfo!.name,
          "phone": userModelCurrentInfo!.phone,
          "email": userModelCurrentInfo!.email,
        });
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Profile updated successfully!",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } on auth.FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text("Update failed: ${e.message}")),
            ],
          ),
          backgroundColor: errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCloseAppDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: cardWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning Header
              Container(
                decoration: BoxDecoration(
                  color: errorRed,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),

              // Dialog Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "Are you sure you want to exit Kaltrike Commuter?",
                      style: TextStyle(
                        fontSize: 15,
                        color: textLight,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textLight,
                              backgroundColor: Colors.transparent,
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              SystemNavigator.pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: errorRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.exit_to_app_rounded, size: 20),
                                SizedBox(width: 8),
                                Text("Close"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              decoration: BoxDecoration(
                color: cardWhite,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: paleBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Text(
                      "My Profile",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: paleBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_rounded,
                          color: primaryBlue,
                          size: 20,
                        ),
                      ),
                      onPressed: _showEditDialog,
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Column(
                  children: [
                    // Profile Card
                    Container(
                      decoration: BoxDecoration(
                        color: cardWhite,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Avatar
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [primaryBlue, darkBlue],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: cardWhite,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: primaryBlue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // User Info
                          Text(
                            userModelCurrentInfo!.name!,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textDark,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: paleBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Kaltrike Commuter",
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Contact Info Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Contact Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          _buildInfoItem(
                            icon: Icons.phone_rounded,
                            title: "Phone Number",
                            value: userModelCurrentInfo!.phone!,
                            color: successGreen,
                          ),

                          const SizedBox(height: 16),

                          _buildInfoItem(
                            icon: Icons.email_rounded,
                            title: "Email Address",
                            value: userModelCurrentInfo!.email!,
                            color: primaryBlue,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paleBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: primaryBlue,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: textLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}