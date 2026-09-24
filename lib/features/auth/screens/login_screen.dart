import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../patient/screens/patient_dashboard_screen.dart';
import '../widgets/app_logo_badge.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/glossy_login_button.dart';
import '../widgets/role_selector.dart';
import '../widgets/stethoscope_watermark.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.pasien;
  bool _isLoading = false;

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final username = _userController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan email / username dan password Anda.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await AuthService.instance.login(
        identifier: username,
        password: password,
        expectedRole: _selectedRole,
      );

      if (!mounted) return;

      if (_selectedRole == UserRole.pasien) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => PatientDashboardScreen(
              patientName: user.fullName.isNotEmpty ? user.fullName : 'Pasien',
            ),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.bgGradientTop,
              AppColors.bgGradientMid,
              AppColors.bgGradientBottom,
            ],
            stops: [0.0, 0.48, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // 1. Watermark Stethoscope at the bottom
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StethoscopeWatermark(height: 290),
            ),

            // Back button to Landing Page
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),

            // 2. Main Scrollable Form Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        // 3D Emblem, Title & Subtitle
                        const AppLogoBadge(size: 140),
                        const SizedBox(height: 32),

                        // Role Selector Pills (Pasien, Dokter, Admin)
                        RoleSelector(
                          selectedRole: _selectedRole,
                          onRoleChanged: (role) {
                            setState(() {
                              _selectedRole = role;
                            });
                          },
                        ),
                        const SizedBox(height: 22),

                        // Username Input Field
                        CustomTextField(
                          controller: _userController,
                          hintText: 'User',
                          prefixIcon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Password Input Field
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),
                        const SizedBox(height: 28),

                        // Glossy Cyan Log In Button
                        GlossyLoginButton(
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 18),

                        // Forgot Password Link (opens 04 - B Forgot Password)
                        Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                'Lupa password?',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Link Daftar Akun → langsung ke SignUpScreen
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SignUpScreen()),
                              );
                            },
                            child: RichText(
                              text: TextSpan(
                                text: 'Belum punya akun? ',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Daftar Sekarang',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFFCEAEA),
                                      decoration: TextDecoration.underline,
                                      decorationColor: const Color(0xFFFCEAEA),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
