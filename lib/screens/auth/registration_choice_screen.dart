// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:track_site_pro_app/screens/auth/contractor_registration_screen.dart';
import 'package:track_site_pro_app/screens/auth/supervisor_register_screen.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
class _C {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const lightGray     = Color(0xFFF9FAFB);
  static const borderGray    = Color(0xFFE5E7EB);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const successGreen  = Color(0xFF10B981);
  static const lightGreen    = Color(0xFFECFDF5);
}

class RegistrationChoiceScreen extends StatelessWidget {
  const RegistrationChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightGray,
      body: SafeArea(
        child: Column(children: [
          // ── Top Bar ──
          _buildTopBar(context),

          // ── Scrollable Content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              child: Column(children: [
                // Info Banner
                _buildInfoBanner(),
                const SizedBox(height: 24),

                // Contractor Card
                _RoleCard(
                  title: 'Contractor',
                  subtitle:
                      'For construction companies, contractors, and project owners',
                  icon: Icons.business_center_rounded,
                  accentColor: _C.primaryBlue,
                  accentBg: _C.lightBlue,
                  accentBorder: _C.mediumBlue,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ContractorRegisterScreen()),
                  ),
                ),
                const SizedBox(height: 16),

                // Supervisor Card
                _RoleCard(
                  title: 'Site Supervisor',
                  subtitle:
                      'For site supervisors, engineers, and project managers',
                  icon: Icons.engineering_rounded,
                  accentColor: _C.successGreen,
                  accentBg: _C.lightGreen,
                  accentBorder: const Color(0xFF6EE7B7),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SupervisorRegisterScreen()),
                  ),
                ),

                const SizedBox(height: 32),

                // Already have account
                _buildSignInRow(context),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Top Bar ─────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _C.borderGray, width: 1)),
      ),
      child: Row(children: [
        // Back button
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.lightGray,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _C.borderGray),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 17, color: _C.textSecondary),
          ),
        ),
        const SizedBox(width: 14),
        // Title
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _C.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              Text(
                'Choose your role to get started',
                style: TextStyle(fontSize: 12, color: _C.textTertiary),
              ),
            ],
          ),
        ),
        // Brand icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _C.primaryBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.construction_rounded,
              size: 20, color: Colors.white),
        ),
      ]),
    );
  }

  // ── Info Banner ──────────────────────────────────────────────────────────────
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.lightBlue,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.mediumBlue),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _C.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.info_rounded, color: _C.primaryBlue, size: 16),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Select the role that best describes your position in construction projects.',
            style: TextStyle(
              fontSize: 13,
              color: _C.primaryBlue,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ]),
    );
  }

  // ── Sign In Row ──────────────────────────────────────────────────────────────
  Widget _buildSignInRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.borderGray),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.login_rounded, size: 16, color: _C.textTertiary),
        const SizedBox(width: 8),
        const Text(
          'Already have an account?',
          style: TextStyle(fontSize: 14, color: _C.textSecondary),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: _C.primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Sign In',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}

// ── Role Card ─────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color accentBg;
  final Color accentBorder;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.accentBg,
    required this.accentBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.borderGray),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            // Icon badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentBorder),
              ),
              child: Icon(icon, color: accentColor, size: 28),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _C.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _C.textSecondary,
                    height: 1.4,
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),

            // Arrow
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accentBorder),
              ),
              child: Icon(Icons.arrow_forward_ios_rounded,
                  color: accentColor, size: 14),
            ),
          ]),
        ),
      ),
    );
  }
}