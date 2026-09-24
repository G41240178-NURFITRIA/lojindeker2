import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';
import 'set_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _contactController = TextEditingController(text: 'admin@dcare.com');
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _handleSendResetLink() async {
    final contact = _contactController.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan email atau no handphone Anda.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Tautan pemulihan kata sandi berhasil dikirimkan ke $contact',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    // Navigate to Set Password screen (04 - D)
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SetPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Forgot Password',
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

              // Heading: Forgot Password
              Text(
                'Forgot Password',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB51419),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Masukkan email atau no telepon yang terdaftar untuk menerima tautan pemulihan kata sandi Anda.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Email or Mobile Number
              FigmaAuthField(
                label: 'Email or Mobile Number',
                hintText: 'example@example.com',
                controller: _contactController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),

              // Send Reset Link Button
              FigmaRedButton(
                text: 'Send Reset Link',
                isLoading: _isLoading,
                onPressed: _handleSendResetLink,
              ),
              const SizedBox(height: 32),

              // Bottom link: Remember your password? Log In
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: RichText(
                    text: TextSpan(
                      text: "Remember your password? ",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF666666),
                      ),
                      children: [
                        TextSpan(
                          text: 'Log In',
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
