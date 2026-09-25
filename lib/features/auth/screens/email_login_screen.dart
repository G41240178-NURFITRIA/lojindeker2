import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../doctor/screens/doctor_dashboard_screen.dart';
import '../../patient/screens/patient_dashboard_screen.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';
import '../widgets/role_selector.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  UserRole _selectedRole = UserRole.pasien;
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
      final user = await AuthService.instance.login(
        identifier: email,
        password: password,
        expectedRole: _selectedRole,
      );

      if (!mounted) return;

      if (_selectedRole == UserRole.pasien) {
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
      } else if (_selectedRole == UserRole.dokter) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DoctorDashboardScreen(
              doctorName: user.fullName.isNotEmpty ? user.fullName : 'Dr. Kaka Pratama',
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
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
                'Pilih peran akun Anda dan masukkan email/password yang terdaftar.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Role Selector Tabs (Pasien, Dokter, Admin)
              _buildRoleSegmentSelector(),
              const SizedBox(height: 22),

              // Email or Mobile Number
              FigmaAuthField(
                label: 'Email or Mobile Number',
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

  /// Segmented Role Selector Widget
  Widget _buildRoleSegmentSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECEE),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildRoleOption(UserRole.pasien, 'Pasien', Icons.person_outline_rounded),
          _buildRoleOption(UserRole.dokter, 'Dokter', Icons.medical_services_outlined),
          _buildRoleOption(UserRole.admin, 'Admin', Icons.shield_outlined),
        ],
      ),
    );
  }

  Widget _buildRoleOption(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB51419) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFB51419).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : const Color(0xFF666666),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
