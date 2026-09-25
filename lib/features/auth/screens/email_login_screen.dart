import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../features/auth/widgets/role_selector.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../doctor/screens/doctor_dashboard_screen.dart';
import '../../patient/screens/patient_dashboard_screen.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan lengkapi email / no HP dan password.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Login tanpa memilih role — role dibaca otomatis dari Firestore
      final user = await AuthService.instance.loginAutoRole(
        identifier: email,
        password: password,
      );

      if (!mounted) return;

      // Routing otomatis berdasarkan role yang tersimpan di database
      switch (user.role) {
        case UserRole.admin:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
          break;
        case UserRole.dokter:
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
          );
          break;
        case UserRole.pasien:
          final displayName = user.fullName.isNotEmpty
              ? user.fullName
              : (email.contains('@') ? email.split('@')[0] : email);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PatientDashboardScreen(
                patientName: displayName.isNotEmpty ? displayName : 'Pasien',
              ),
            ),
          );
          break;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB51419),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        centerTitle: true,
        title: Text(
          'Log In',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Title: Welcome
              Text(
                'Welcome',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB51419),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan email / no HP dan password Anda.\nSistem akan otomatis mengarahkan ke dashboard sesuai peran.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Email or Mobile Number
              FigmaAuthField(
                label: 'Email atau No. HP',
                hintText: 'example@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Password
              FigmaAuthField(
                label: 'Password',
                hintText: '••••••••••••',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 8),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB51419),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Red Log In Button
              FigmaRedButton(
                text: 'Log In',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 32),

              // Bottom link: Don't have an account? Sign Up
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF666666),
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB51419),
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
    );
  }
}
