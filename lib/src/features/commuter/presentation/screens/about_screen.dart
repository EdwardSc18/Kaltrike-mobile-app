import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_surface_card.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _CommuterAboutScreenState();
}

class _CommuterAboutScreenState extends State<AboutScreen> {
  void _showCloseAppDialog() {
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
                  Icons.exit_to_app_rounded,
                  color: Color(0xFFEF4444),
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Close App?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Are you sure you want to close the application?",
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
                    child: KalPrimaryButton(
                      label: 'Close App',
                      onPressed: () {
                        Navigator.pop(context);
                        SystemNavigator.pop();
                      },
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "About App",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF1E293B),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade500.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Kaltrike Commuter",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Smart Commuting App",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Information
            _buildInfoCard(
              icon: Icons.info_rounded,
              title: "App Information",
              content: "Kaltrike Commuter Mobile Application\n\n"
                  "In Partial Fulfillment of the Requirements for the "
                  "Degree Bachelor of Science in Information Technology",
            ),

            const SizedBox(height: 20),

            // Developers Section
            _buildInfoCard(
              icon: Icons.people_rounded,
              title: "Developed By",
              content: "BSIT Students",
              children: [
                _buildTeamMember("Bayongasan, Arkein"),
                _buildTeamMember("Balacang, Shadrock"),
                _buildTeamMember("Caronan, Edward"),
              ],
            ),

            const SizedBox(height: 20),

            // Features Section
            _buildInfoCard(
              icon: Icons.featured_play_list_rounded,
              title: "Commuter Features",
              content: "Smart tools for everyday commuting",
              children: [
                _buildFeatureItem("Real-time ride booking"),
                _buildFeatureItem("Fare estimation & payment"),
                _buildFeatureItem("Driver ratings & reviews"),
                _buildFeatureItem("Route tracking & ETA"),
                _buildFeatureItem("Safe and reliable rides"),
              ],
            ),

            const SizedBox(height: 20),

            // Version & License
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "App Details",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow("Version", "1.0.0"),
                  _buildDetailRow("Platform", "Commuter"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Close App Button
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton.icon(
                onPressed: _showCloseAppDialog,
                icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                label: const Text(
                  "Close Application",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEF2F2),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    List<Widget>? children,
  }) {
    return KalSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          if (children != null) ...[
            const SizedBox(height: 16),
            Column(
              children: children,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF2563EB),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF10B981),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
