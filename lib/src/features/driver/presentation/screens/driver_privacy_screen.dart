import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_section_header.dart';

class DriverPrivacyScreen extends StatelessWidget {
  const DriverPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Driver Privacy Policy",
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF059669),
                    Color(0xFF10B981),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.privacy_tip_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Driver Privacy Policy",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Last updated: December 2023",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Introduction
            const Text(
              "Kaltrike is committed to protecting the privacy and security of our driver partners' information. This Privacy Policy explains how we collect, use, and safeguard your personal and driving data in compliance with the Data Privacy Act of 2012 and BPLO Tabuk City requirements.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("1. Information We Collect"),
            _buildSubSectionTitle("Personal Information:"),
            _buildBulletPoint("• Full name, address, and contact details"),
            _buildBulletPoint("• Driver's license and professional credentials"),
            _buildBulletPoint("• BPLO business permit information"),
            _buildBulletPoint("• TIN and banking information for payments"),

            _buildSubSectionTitle("Vehicle Information:"),
            _buildBulletPoint("• Vehicle registration and insurance details"),
            _buildBulletPoint("• Vehicle inspection reports"),
            _buildBulletPoint("• Maintenance and safety records"),

            _buildSubSectionTitle("Driving Data:"),
            _buildBulletPoint("• GPS location and route history"),
            _buildBulletPoint("• Trip details and earnings data"),
            _buildBulletPoint("• Driver rating and performance metrics"),
            _buildBulletPoint("• App usage and interaction data"),

            _buildSectionTitle("2. How We Use Your Information"),
            _buildBulletPoint("• Verify driver eligibility and credentials"),
            _buildBulletPoint("• Process payments and tax documentation"),
            _buildBulletPoint("• Provide navigation and ride matching services"),
            _buildBulletPoint("• Ensure safety and compliance with regulations"),
            _buildBulletPoint("• Communicate service updates and opportunities"),
            _buildBulletPoint("• Comply with BPLO Tabuk City reporting requirements"),

            _buildSectionTitle("3. Data Sharing"),
            _buildParagraph("We may share your information with:"),
            _buildBulletPoint("• Passengers for ride fulfillment (name, vehicle details, rating)"),
            _buildBulletPoint("• Payment processors for earnings distribution"),
            _buildBulletPoint("• Insurance providers for coverage verification"),
            _buildBulletPoint("• BPLO Tabuk City for regulatory compliance"),
            _buildBulletPoint("• Law enforcement when required by law"),

            _buildSectionTitle("4. Data Retention"),
            _buildParagraph(
                "We retain driver data for as long as your account is active and for 5 years thereafter to comply with BIR and BPLO requirements. Trip data is maintained for 2 years as required by transportation regulations."),

            _buildSectionTitle("5. Location Data"),
            _buildParagraph(
                "We collect precise location data to provide ride services, optimize routes, and ensure driver and passenger safety. Location sharing can be controlled through app settings but is required for active driving sessions."),

            _buildSectionTitle("6. Driver Rights"),
            _buildBulletPoint("• Access and review your personal information"),
            _buildBulletPoint("• Correct inaccurate data in your profile"),
            _buildBulletPoint("• Request data portability"),
            _buildBulletPoint("• Withdraw consent for non-essential processing"),
            _buildBulletPoint("• File complaints with the National Privacy Commission"),

            _buildSectionTitle("7. Data Security"),
            _buildParagraph(
                "We implement industry-standard security measures including encryption, access controls, and regular security audits. Driver data is stored on secure servers with restricted access."),

            _buildSectionTitle("8. BPLO Compliance"),
            _buildParagraph(
                "As required by BPLO Tabuk City, we maintain records of driver credentials, vehicle information, and business permits. This information is shared with city authorities for regulatory oversight and public safety."),

            _buildSectionTitle("9. Updates to Privacy Policy"),
            _buildParagraph(
                "We may update this policy to reflect changes in regulations or our services. Drivers will be notified of significant changes and continued use of our services constitutes acceptance."),

            _buildSectionTitle("10. Contact Information"),
            _buildParagraph(
                "For privacy concerns or to exercise your rights:\n\nData Protection Officer\nEmail: dpo@kaltrike.com\nPhone: (0917) 123-4567\nAddress: Tabuk City, Kalinga"),

            const SizedBox(height: 32),

            // Compliance Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF0EA5E9),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Regulatory Compliance",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Kaltrike operates in full compliance with the Data Privacy Act of 2012 (RA 10173) and BPLO Tabuk City regulations. Our data processing activities are registered with the National Privacy Commission, and we maintain transparent data practices for all driver partners.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: KalSectionHeader(title: title),
    );
  }

  Widget _buildSubSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF475569),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "• ",
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
