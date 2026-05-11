import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_section_header.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Terms of Service",
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
                    Color(0xFF1E3A8A),
                    Color(0xFF2563EB),
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
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Terms of Service",
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

            // Terms Content
            _buildSectionTitle("1. Acceptance of Terms"),
            _buildParagraph(
                "By accessing and using Kaltrike Commuter services in Tabuk City, Kalinga, you agree to be bound by these Terms of Service and comply with all applicable laws and regulations of the Republic of the Philippines and local ordinances of Tabuk City."),

            _buildSectionTitle("2. Service Description"),
            _buildParagraph(
                "Kaltrike is a ride-hailing platform connecting commuters with registered tricycle drivers in Tabuk City. All drivers are duly licensed and authorized by the City Government of Tabuk through the Business Permits and Licensing Office (BPLO)."),

            _buildSectionTitle("3. User Eligibility"),
            _buildParagraph(
                "To use our services, you must be at least 18 years old and have the legal capacity to enter into binding contracts. By using Kaltrike, you represent and warrant that you meet these eligibility requirements."),

            _buildSectionTitle("4. User Responsibilities"),
            _buildBulletPoint("• Provide accurate and complete information during registration"),
            _buildBulletPoint("• Maintain the confidentiality of your account credentials"),
            _buildBulletPoint("• Use the service in compliance with Tabuk City traffic regulations"),
            _buildBulletPoint("• Treat drivers with respect and follow proper conduct"),
            _buildBulletPoint("• Pay fares promptly through approved payment methods"),

            _buildSectionTitle("5. Fare Structure"),
            _buildParagraph(
                "All fares are calculated based on distance and time, following the approved fare matrix by the City Government of Tabuk. Additional charges may apply for special requests, waiting time, or multiple stops."),

            _buildSectionTitle("6. Payments"),
            _buildParagraph(
                "Kaltrike accepts cash only payments for now. All transactions are recorded and comply with BIR regulations. Receipts are available upon request for all paid rides."),

            _buildSectionTitle("7. Cancellation Policy"),
            _buildBulletPoint("• Users may cancel rides without charge within 2 minutes of booking"),
            _buildBulletPoint("• Repeated cancellations may result in temporary suspension"),
            _buildBulletPoint("• Drivers may cancel due to safety concerns or vehicle issues"),

            _buildSectionTitle("8. Safety Guidelines"),
            _buildBulletPoint("• Do not distract the driver during the ride"),
            _buildBulletPoint("• Report any safety concerns immediately"),

            _buildSectionTitle("9. Prohibited Activities"),
            _buildBulletPoint("• Smoking or consuming alcohol during rides"),
            _buildBulletPoint("• Carrying illegal substances or weapons"),
            _buildBulletPoint("• Damaging vehicle property"),
            _buildBulletPoint("• Harassing drivers or other passengers"),

            _buildSectionTitle("10. Intellectual Property"),
            _buildParagraph(
                "All content, trademarks, and intellectual property associated with Kaltrike are owned by the company. Users may not reproduce, distribute, or create derivative works without explicit permission."),

            _buildSectionTitle("11. Limitation of Liability"),
            _buildParagraph(
                "Kaltrike acts as an intermediary platform and is not liable for direct, indirect, incidental, or consequential damages arising from the use of our services, except as required by Philippine law."),

            _buildSectionTitle("12. Termination"),
            _buildParagraph(
                "We reserve the right to suspend or terminate accounts that violate these terms, engage in fraudulent activities, or pose safety risks to our community."),

            _buildSectionTitle("13. Governing Law"),
            _buildParagraph(
                "These Terms shall be governed by and construed in accordance with the laws of the Republic of the Philippines. Any disputes shall be settled in the proper courts of Tabuk City, Kalinga."),

            _buildSectionTitle("14. Changes to Terms"),
            _buildParagraph(
                "We may modify these Terms at any time. Continued use of our services after changes constitutes acceptance of the modified Terms."),

            _buildSectionTitle("15. Contact Information"),
            _buildParagraph(
                "For questions about these Terms, please contact:\n\nKaltrike Support\nEmail: kaltrike@gmail.com\nPhone: (+63) 9567720160\nAddress: Tabuk City, Kalinga, Philippines"),

            const SizedBox(height: 40),

            // Acceptance Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Important Notice",
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
                    "By using Kaltrike services, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and all applicable laws and regulations of Tabuk City, Kalinga.",
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
