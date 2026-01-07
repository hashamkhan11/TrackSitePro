// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/auth/contractor_registration_screen.dart';
import 'package:track_site_pro_app/screens/auth/supervisor_register_screen.dart';

class RegistrationChoiceScreen extends StatelessWidget {
  const RegistrationChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Enhanced Header with Back Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withOpacity(0.9),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button Row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title Section
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your role to get started with TrackSitePro',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    // Welcome Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 28),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Select the role that best describes your position in construction projects.',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Contractor Card
                    _buildRoleCard(
                      context: context,
                      title: 'Contractor',
                      subtitle: 'For construction companies, contractors, and project owners',
                      icon: Icons.business_center_rounded,
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ContractorRegisterScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Supervisor Card
                    _buildRoleCard(
                      context: context,
                      title: 'Site Supervisor',
                      subtitle: 'For site supervisors, engineers, and project managers',
                      icon: Icons.engineering_rounded,
                      iconColor: Colors.green,
                      backgroundColor: Colors.green.withOpacity(0.1),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SupervisorRegisterScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Already have an account section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
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

  Widget _buildRoleCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        splashColor: iconColor.withOpacity(0.1),
        highlightColor: iconColor.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDarkMode
                  ? colorScheme.outline.withOpacity(0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      backgroundColor.withOpacity(0.8),
                      backgroundColor.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}