import 'package:flutter/material.dart';
import 'package:kaltrike_driver_app/src/core/utils/responsive.dart';
import 'package:kaltrike_driver_app/src/features/commuter/app/commuter_app_shell.dart';
import 'package:kaltrike_driver_app/src/features/driver/app/driver_app_shell.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_colors.dart';
import 'package:kaltrike_driver_app/src/shared/ui/app_spacing.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_primary_button.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_section_header.dart';
import 'package:kaltrike_driver_app/src/shared/ui/widgets/kal_surface_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final r = context.r;
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final double horizontalPadding = (screenWidth * 0.06).clamp(20.0, 32.0).toDouble();
          final double topSpacing = (screenHeight * 0.06).clamp(28.0, 52.0).toDouble();
          final double logoSize = (screenWidth * 0.28).clamp(96.0, 132.0).toDouble();
          final double titleSize = (screenWidth * 0.085).clamp(26.0, 34.0).toDouble();
          final double subtitleSize = (screenWidth * 0.042).clamp(14.0, 17.0).toDouble();
          final availableHeight = screenHeight - MediaQuery.of(context).padding.vertical - 20;

          return Container(
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, topSpacing, horizontalPadding, r.hp(0.03, min: 20, max: 28)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: availableHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade900.withOpacity(0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Hero(
                            tag: 'app-logo',
                            child: ClipOval(
                              child: Image.asset('images/Logo.png', fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        SizedBox(height: r.hp(0.035, min: 24, max: 36)),
                        Text(
                          'Welcome to Kaltrike',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: r.hp(0.018, min: 12, max: 18)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
                          child: Text(
                            'Your smarter way to book tricycles and ongbak/tuktuk rides — fast, reliable, and built for your community.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: subtitleSize,
                              color: Colors.white.withOpacity(0.92),
                              height: 1.6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const Spacer(),
                        KalSurfaceCard(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const KalSectionHeader(
                                title: 'Choose your role',
                                subtitle: 'Select how you want to use Kaltrike today.',
                              ),
                              SizedBox(height: r.hp(0.02, min: 14, max: 18)),
                              _buildRolePreview(
                                icon: Icons.person_rounded,
                                title: 'Commuter',
                                subtitle: 'Book nearby rides, review fare details, and track your driver.',
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _buildRolePreview(
                                icon: Icons.directions_car_filled_rounded,
                                title: 'Driver',
                                subtitle: 'Manage bookings, trips, and earnings with the driver tools.',
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              KalPrimaryButton(
                                label: 'Get Started',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => _showModeSelector(context),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: r.hp(0.025, min: 16, max: 24)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Powered by Kaltrike',
                            style: TextStyle(
                              fontSize: (screenWidth * 0.036).clamp(12.0, 14.0).toDouble(),
                              color: Colors.white.withOpacity(0.88),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRolePreview({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showModeSelector(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final r = sheetContext.r;
        return SafeArea(
          child: Container(
            margin: EdgeInsets.all(r.wp(0.03, min: 12, max: 18)),
            child: KalSurfaceCard(
              padding: EdgeInsets.fromLTRB(
                r.wp(0.06, min: 20, max: 28),
                r.hp(0.024, min: 18, max: 22),
                r.wp(0.06, min: 20, max: 28),
                r.hp(0.024, min: 18, max: 22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: SizedBox(
                      width: 42,
                      child: Divider(thickness: 4, color: AppColors.border),
                    ),
                  ),
                  SizedBox(height: r.hp(0.018, min: 12, max: 16)),
                  const KalSectionHeader(
                    title: 'Continue with Kaltrike',
                  ),
                  SizedBox(height: r.hp(0.016, min: 12, max: 14)),
                  KalPrimaryButton(
                    label: 'Continue as Driver',
                    icon: Icons.directions_car_filled_rounded,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.of(parentContext).pushReplacement(
                        MaterialPageRoute(builder: (_) => const DriverAppShell()),
                      );
                    },
                  ),
                  SizedBox(height: r.hp(0.02, min: 14, max: 18)),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.of(parentContext).pushReplacement(
                          MaterialPageRoute(builder: (_) => const CommuterAppShell()),
                        );
                      },
                      icon: Icon(Icons.person_rounded, size: r.sp(22)),
                      label: const Text('Continue as Commuter'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Not now'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
