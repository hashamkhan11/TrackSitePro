// ignore_for_file: unnecessary_cast

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_site_pro_app/screens/auth/registration_choice_screen.dart';
import 'package:track_site_pro_app/screens/auth/role_redirector.dart';
import 'package:track_site_pro_app/screens/auth/forgot_password_screen.dart';

// ── Shared Design Tokens (mirrors AppColors in dashboard) ────────────────────
class _C {
  static const primaryBlue   = Color(0xFF2563EB);
  static const lightBlue     = Color(0xFFEFF6FF);
  static const mediumBlue    = Color(0xFFBFDBFE);
  static const darkBlue      = Color(0xFF1E40AF);
  static const neutralGray   = Color(0xFF6B7280);
  static const lightGray     = Color(0xFFF9FAFB);
  static const borderGray    = Color(0xFFE5E7EB);
  static const textPrimary   = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFF9CA3AF);
  static const successGreen  = Color(0xFF10B981);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey              = GlobalKey<FormState>();
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  bool  _isLoading            = false;
  bool  _obscurePassword      = true;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Snackbars ──────────────────────────────────────────────────────────────
  void _showSnack(String msg, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  // ── Email Verification ─────────────────────────────────────────────────────
  Future<bool> _checkEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    await user.reload();
    return FirebaseAuth.instance.currentUser?.emailVerified ?? false;
  }

  Future<void> _showVerificationDialog(String email) async {
    if (!mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VerificationDialog(email: email),
    );
  }

  // ── Login Logic ────────────────────────────────────────────────────────────
  Future<void> _onLoginPressed() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = cred.user;
      if (user == null) {
        _showSnack("Login failed. Please try again.", Colors.red);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(user.uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        await FirebaseAuth.instance.signOut();
        _showSnack("Account setup incomplete. Please contact support.", Colors.red);
        return;
      }

      final data = userDoc.data()!;
      final role = data['role']?.toString() ?? '';

      if (role == 'contractor') {
        final status = data['status']?.toString() ?? '';
        if (status != 'approved') {
          await FirebaseAuth.instance.signOut();
          _showSnack(
            "Your contractor account is pending admin approval.\n"
            "You'll be notified via email once approved.",
            Colors.orange,
          );
          return;
        }
      }

      if (role == 'supervisor' && mounted) {
        final supervisorProjects = await FirebaseFirestore.instance
            .collection('projects')
            .where('assignedSupervisor', isEqualTo: _emailController.text.trim())
            .limit(1)
            .get();
        if (supervisorProjects.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('You are not assigned to any projects yet.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ));
        }
      }

      final verified = await _checkEmailVerified();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'emailVerified': verified,
        'lastLogin': Timestamp.now(),
      });

      if (!verified && mounted) {
        await _showVerificationDialog(user.email ?? _emailController.text.trim());
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleRedirector()),
        );
      }
    } on FirebaseAuthException catch (e) {
      final msgs = {
        'user-not-found': "No account found with this email. Please register first.",
        'wrong-password': "Incorrect password. Try again or use 'Forgot Password'.",
        'invalid-email': "Email address is not valid.",
        'user-disabled': "This account has been disabled. Please contact support.",
        'too-many-requests': "Too many login attempts. Please try again shortly.",
        'network-request-failed': "Network error. Check your internet connection.",
      };
      _showSnack(msgs[e.code] ?? "Login failed: ${e.message}", Colors.red);
    } catch (_) {
      _showSnack("Login failed. Please try again.", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.lightGray,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Brand Mark ──
                    _buildBrandMark(),
                    const SizedBox(height: 32),

                    // ── Form Card ──
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _C.borderGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _C.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Sign in to continue to your dashboard',
                              style: TextStyle(
                                fontSize: 14,
                                color: _C.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Email
                            _buildField(
                              controller: _emailController,
                              label: 'Email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  v == null || v.isEmpty || !v.contains('@')
                                      ? 'Enter a valid email address'
                                      : null,
                            ),
                            const SizedBox(height: 16),

                            // Password
                            _buildPasswordField(),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordScreen()),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: _C.primaryBlue,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 8),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Login Button
                            _buildLoginButton(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sign-up link
                    _buildSignUpRow(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Brand Mark ──────────────────────────────────────────────────────────────
  Widget _buildBrandMark() {
    return Column(children: [
      Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: _C.primaryBlue,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _C.primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.construction_rounded, color: Colors.white, size: 32),
      ),
      const SizedBox(height: 14),
      const Text(
        'TrackSitePro',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: _C.textPrimary,
          letterSpacing: -0.8,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Construction project management',
        style: TextStyle(fontSize: 13, color: _C.textTertiary),
      ),
    ]);
  }

  // ── Text Field ──────────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: _C.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14, color: _C.textSecondary),
        filled: true,
        fillColor: _C.lightGray,
        prefixIcon: Icon(icon, size: 20, color: _C.textTertiary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Password Field ──────────────────────────────────────────────────────────
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(fontSize: 15, color: _C.textPrimary),
      validator: (v) =>
          v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: const TextStyle(fontSize: 14, color: _C.textSecondary),
        filled: true,
        fillColor: _C.lightGray,
        prefixIcon:
            const Icon(Icons.lock_outline_rounded, size: 20, color: _C.textTertiary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: _C.textTertiary,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Login Button ────────────────────────────────────────────────────────────
  Widget _buildLoginButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _onLoginPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _C.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: _C.primaryBlue.withOpacity(0.6),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : const Text(
                'Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  // ── Sign-up Row ─────────────────────────────────────────────────────────────
  Widget _buildSignUpRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.borderGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_add_alt_1_outlined,
              size: 16, color: _C.textTertiary),
          const SizedBox(width: 8),
          const Text(
            "Don't have an account?",
            style: TextStyle(fontSize: 14, color: _C.textSecondary),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const RegistrationChoiceScreen()),
            ),
            style: TextButton.styleFrom(
              foregroundColor: _C.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Verification Dialog ───────────────────────────────────────────────────────
class _VerificationDialog extends StatelessWidget {
  final String email;
  const _VerificationDialog({required this.email});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      title: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.mark_email_unread_outlined,
              color: Color(0xFFF59E0B), size: 22),
        ),
        const SizedBox(width: 12),
        const Text(
          'Verify Your Email',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
        ),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your email address is not verified yet. Check your inbox:',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(children: [
              const Icon(Icons.email_outlined,
                  size: 14, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(email,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB))),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
          child: const Text('Skip for now'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await FirebaseAuth.instance.currentUser?.sendEmailVerification();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Verification email sent!'),
                  backgroundColor: const Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            } catch (e) {
              debugPrint('Failed to resend verification email: $e');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text(
                      'Could not send verification email. Please try again.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Resend Email',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}