import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_section_header.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
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
                    "Privacy Policy",
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
              "Kaltrike Commuter is committed to protecting your privacy and ensuring the security of your personal information. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our services in Tabuk City, Kalinga.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),

            const SizedBox(height: 24),

            _buildSectionTitle("1. Information We Collect"),
            _buildSubSectionTitle("Personal Information:"),
            _buildBulletPoint("• Full name and contact details"),
            _buildBulletPoint("• Email address and phone number"),
            _buildBulletPoint("• Payment information"),

            _buildSubSectionTitle("Ride Information:"),
            _buildBulletPoint("• Pick-up and drop-off locations"),
            _buildBulletPoint("• Ride history and timestamps"),
            _buildBulletPoint("• Fare calculations and payment records"),
            _buildBulletPoint("• Driver and vehicle details"),

            _buildSubSectionTitle("Device Information:"),
            _buildBulletPoint("• Device type and operating system"),
            _buildBulletPoint("• IP address and mobile network information"),
            _buildBulletPoint("• GPS and location data"),

            _buildSectionTitle("2. How We Use Your Information"),
            _buildBulletPoint("• To provide and maintain our ride-hailing services"),
            _buildBulletPoint("• To process payments and send receipts"),
            _buildBulletPoint("• To ensure safety and security of our services"),
            _buildBulletPoint("• To communicate service updates and promotions"),
            _buildBulletPoint("• To comply with Tabuk City BPLO requirements"),
            _buildBulletPoint("• To improve our services and user experience"),

            _buildSectionTitle("3. Data Sharing and Disclosure"),
            _buildParagraph("We may share your information with:"),
            _buildBulletPoint("• Registered tricycle drivers for ride fulfillment"),
            _buildBulletPoint("• Payment processors for transaction completion"),
            _buildBulletPoint("• Government authorities as required by law"),
            _buildBulletPoint("• BPLO Tabuk City for regulatory compliance"),

            _buildParagraph("We do not sell your personal information to third parties."),

            _buildSectionTitle("4. Data Retention"),
            _buildParagraph(
                "We retain your personal information for as long as necessary to provide our services and comply with legal obligations. Ride records are maintained for 2 years as required by BPLO Tabuk City regulations."),

            _buildSectionTitle("5. Data Security"),
            _buildParagraph(
                "We implement appropriate security measures to protect your personal information, including encryption, access controls, and secure servers. However, no method of transmission over the internet is 100% secure."),

            _buildSectionTitle("6. Your Rights"),
            _buildBulletPoint("• Access and review your personal information"),
            _buildBulletPoint("• Correct inaccurate or incomplete data"),
            _buildBulletPoint("• Request deletion of your account and data"),
            _buildBulletPoint("• Opt-out of marketing communications"),
            _buildBulletPoint("• Withdraw consent for data processing"),

            _buildSectionTitle("7. Location Data"),
            _buildParagraph(
                "We collect location data to provide ride-hailing services, calculate fares, and ensure safety. You can control location permissions through your device settings, but this may affect service functionality."),

            _buildSectionTitle("8. Children's Privacy"),
            _buildParagraph(
                "Our services are not intended for children under 18. We do not knowingly collect information from children. If we become aware of such collection, we will take steps to delete the information."),

            _buildSectionTitle("9. Third-Party Services"),
            _buildParagraph(
                "Our app may contain links to third-party services. This Privacy Policy does not apply to those services. We recommend reviewing their privacy policies before use."),

            _buildSectionTitle("10. Data Breach Notification"),
            _buildParagraph(
                "In the event of a data breach, we will notify affected users and relevant authorities in accordance with the Philippine Data Privacy Act of 2012."),

            _buildSectionTitle("11. Changes to Privacy Policy"),
            _buildParagraph(
                "We may update this Privacy Policy periodically. We will notify users of significant changes through the app or email. Continued use of our services constitutes acceptance of the updated policy."),

            _buildSectionTitle("12. Contact Information"),
            _buildParagraph(
                "For privacy-related inquiries or to exercise your rights, contact our Data Protection Officer:\n\nEmail: kaltrike@gmail.com\nPhone: (+63) 9567720160\nAddress: Tabuk City, Kalinga, Philippines"),

            _buildSectionTitle("13. Governing Law"),
            _buildParagraph(
                "This Privacy Policy is governed by the Data Privacy Act of 2012 (Republic Act No. 10173) and other applicable laws of the Republic of the Philippines."),

            const SizedBox(height: 32),

            // Compliance Notice
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
                        "Compliance Notice",
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
                    "Kaltrike Commuter operates in compliance with Tabuk City BPLO regulations and Philippine data privacy laws. Our data processing activities are registered with the National Privacy Commission as required by law.",
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Consent Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Your Consent",
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
                    "By using Kaltrike Commuter services, you consent to the collection, use, and disclosure of your personal information as described in this Privacy Policy.",
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
