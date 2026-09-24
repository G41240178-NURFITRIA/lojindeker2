import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final mobile = _mobileController.text.trim();
    final dob = _dobController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan lengkapi nama, email, dan password Anda.', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password minimal harus 6 karakter.', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: mobile,
        dob: dob,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran akun berhasil! Silakan login.', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFF2E7D32),
        ),
      );

      Navigator.of(context).pop();
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB51419),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Daftar Akun',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full Name
              FigmaAuthField(
                label: 'Nama Lengkap',
                hintText: 'Masukkan nama lengkap Anda',
                controller: _fullNameController,
              ),
              const SizedBox(height: 14),

              // Password
              FigmaAuthField(
                label: 'Password',
                hintText: '••••••••••••',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 14),

              // Email
              FigmaAuthField(
                label: 'Email',
                hintText: 'example@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),

              // Mobile Number
              FigmaAuthField(
                label: 'Nomor Telepon',
                hintText: '0812xxxxxxxx',
                controller: _mobileController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Date Of Birth
              FigmaAuthField(
                label: 'Tanggal Lahir',
                hintText: 'DD / MM / YYYY',
                controller: _dobController,
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 18),

              // Terms & Privacy text
              Text(
                'Dengan mendaftar, Anda menyetujui Syarat Layanan & Kebijakan Privasi kami.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF888888),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              // Sign Up Button
              FigmaRedButton(
                text: 'Daftar',
                isLoading: _isLoading,
                onPressed: _handleSignUp,
              ),
              const SizedBox(height: 24),

              // Bottom link: Already have an account? Log In
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      text: 'Sudah punya akun? ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF666666),
                      ),
                      children: [
                        TextSpan(
                          text: 'Masuk',
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
