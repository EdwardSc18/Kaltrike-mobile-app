import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/core/utils/responsive.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/profile_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/settings_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/config/global.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/about_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/trips_history_screen.dart';
import 'package:kaltrike_driver_app/src/features/commuter/presentation/screens/splash_screen.dart';

class MyDrawer extends StatefulWidget {
  final String? name;
  final String? email;

  const MyDrawer({this.name, this.email});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
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
                "Sign Out?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to sign out?",
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
                          MaterialPageRoute(builder: (c) => const MySplashScreen()),
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
                      child: const Text("Sign Out"),
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
  Widget build(BuildContext context) {
    return Drawer(
      width: context.r.wp(0.8, min: 260, max: 320),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          right: Radius.circular(0),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            // Modern Header with Gradient
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: context.r.hp(0.075, min: 48, max: 60), bottom: context.r.hp(0.038, min: 24, max: 32), left: context.r.wp(0.06, min: 20, max: 24), right: context.r.wp(0.06, min: 20, max: 24)),
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
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade900.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF2563EB),
                      size: (36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.name ?? "Commuter",
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.email ?? "user@email.com",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Kaltrike Commuter",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Drawer Menu Items
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    // Main Navigation Items
                    _buildDrawerSection(
                      title: "Navigation",
                      items: [
                        _buildDrawerItem(
                          icon: Icons.history_rounded,
                          text: "Trip History",
                          color: Color(0xFF8B5CF6),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => TripsHistoryScreen()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.person_rounded,
                          text: "My Profile",
                          color: Color(0xFF2563EB),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => ProfileScreen()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.settings_rounded,
                          text: "Settings",
                          color: Color(0xFFF59E0B),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => SettingsScreen()),
                            );
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.info_rounded,
                          text: "About App",
                          color: Color(0xFF10B981),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (c) => AboutScreen()),
                            );
                          },
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Footer Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const Divider(
                            height: 1,
                            color: Color(0xFFE2E8F0),
                          ),
                          const SizedBox(height: 20),
                          _buildDrawerItem(
                            icon: Icons.logout_rounded,
                            text: "Sign Out",
                            color: Color(0xFFEF4444),
                            onTap: _showLogoutDialog,
                            isSignOut: true,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  "images/Logo.png",
                                  width: 20,
                                  height: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Kaltrike",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
    bool isSignOut = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSignOut ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isSignOut ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}