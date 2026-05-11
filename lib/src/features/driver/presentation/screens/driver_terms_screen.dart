import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_section_header.dart';

class DriverTermsScreen extends StatelessWidget {
  const DriverTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Driver Terms of Service",
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
                    "Driver Terms of Service",
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
            _buildSectionTitle("1. Driver Partnership"),
            _buildParagraph(
                "By registering as a Kaltrike driver in Tabuk City, you enter into an independent contractor partnership with Kaltrike. You are not an employee and are responsible for your own taxes, insurance, and business expenses."),

            _buildSectionTitle("2. Driver Eligibility"),
            _buildBulletPoint("• Valid Philippine driver's license (Professional)"),
            _buildBulletPoint("• BPLO Tabuk City business permit"),
            _buildBulletPoint("• Vehicle registration and insurance"),
            _buildBulletPoint("• Clean criminal record"),
            _buildBulletPoint("• Minimum 21 years of age"),
            _buildBulletPoint("• Vehicle meets Kaltrike and LTO standards"),

            _buildSectionTitle("3. Vehicle Requirements"),
            _buildBulletPoint("• Valid LTO registration and inspection"),
            _buildBulletPoint("• Comprehensive insurance coverage"),
            _buildBulletPoint("• Properly functioning safety equipment"),
            _buildBulletPoint("• Clean and well-maintained interior"),
            _buildBulletPoint("• Kaltrike-branded identification displayed"),

            _buildSectionTitle("4. Service Standards"),
            _buildBulletPoint("• Maintain professional appearance and conduct"),
            _buildBulletPoint("• Follow all traffic laws and regulations"),
            _buildBulletPoint("• Provide safe and comfortable rides"),
            _buildBulletPoint("• Use designated pick-up/drop-off points"),
            _buildBulletPoint("• Maintain minimum 4.5 star rating"),

            _buildSectionTitle("5. Fare Structure & Payments"),
            _buildParagraph(
                "Fares are calculated based on the approved matrix by Tabuk City LGU. Drivers receive 80% of the total fare, with 20% covering platform fees, insurance, and operational costs. Weekly payouts are processed every Monday."),

            _buildSectionTitle("6. Cancellation Policy"),
            _buildBulletPoint("• Drivers may cancel rides for safety concerns"),
            _buildBulletPoint("• Excessive cancellations may affect driver rating"),
            _buildBulletPoint("• Valid reasons: passenger misconduct, safety issues"),
            _buildBulletPoint("• Invalid reasons: passenger location, short trips"),

            _buildSectionTitle("7. Safety & Compliance"),
            _buildBulletPoint("• Follow all COVID-19 safety protocols when applicable"),
            _buildBulletPoint("• Report accidents immediately to Kaltrike and authorities"),
            _buildBulletPoint("• Maintain vehicle safety standards"),
            _buildBulletPoint("• Comply with BPLO Tabuk City inspection requirements"),

            _buildSectionTitle("8. Prohibited Activities"),
            _buildBulletPoint("• Discrimination against passengers"),
            _buildBulletPoint("• Accepting rides outside the Kaltrike platform"),
            _buildBulletPoint("• Substance abuse while driving"),
            _buildBulletPoint("• Violating traffic laws"),
            _buildBulletPoint("• Sharing driver account with others"),

            _buildSectionTitle("9. Insurance Coverage"),
            _buildParagraph(
                "Kaltrike provides third-party liability insurance coverage for all rides booked through the platform. Drivers must maintain comprehensive insurance for their vehicles. Additional coverage applies during active trips."),

            _buildSectionTitle("10. Data Privacy"),
            _buildParagraph(
                "Driver data is protected under the Data Privacy Act of 2012. We collect and process driver information for service provision, safety, and regulatory compliance with BPLO Tabuk City."),

            _buildSectionTitle("11. Termination"),
            _buildParagraph(
                "Kaltrike reserves the right to suspend or terminate driver accounts for violations of these terms, safety concerns, or fraudulent activities. Drivers may appeal termination decisions within 7 days."),

            _buildSectionTitle("12. Dispute Resolution"),
            _buildParagraph(
                "Any disputes arising from this agreement shall be settled through mediation in Tabuk City. If mediation fails, disputes shall be resolved in the proper courts of Tabuk City, Kalinga."),

            _buildSectionTitle("13. Governing Law"),
            _buildParagraph(
                "These Terms shall be governed by the laws of the Republic of the Philippines and local ordinances of Tabuk City, Kalinga."),

            _buildSectionTitle("14. Contact Information"),
            _buildParagraph(
                "For driver-related inquiries:\n\nKaltrike Driver Support\nEmail: drivers@kaltrike.com\nPhone: (0917) 123-4567\nAddress: Tabuk City, Kalinga"),

            const SizedBox(height: 40),

            // Compliance Notice
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
                        Icons.gavel_rounded,
                        color: Color(0xFF2563EB),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "BPLO Compliance Notice",
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
                    "All Kaltrike drivers must maintain valid BPLO Tabuk City business permits and comply with local transportation regulations. Regular inspections may be conducted to ensure compliance with city ordinances.",
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
