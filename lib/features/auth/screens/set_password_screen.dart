import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCreateNewPassword() async {
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan masukkan password baru dan konfirmasinya.', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konfirmasi password tidak cocok.', style: GoogleFonts.poppins()),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Password berhasil diperbarui! Silakan masuk.', style: GoogleFonts.poppins()),
        backgroundColor: const Color(0xFF2E7D32),
      ),
    );

    // Pop back to login
    Navigator.of(context).popUntil((route) => route.isFirst);
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
          'Set Password',
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
              Text(
                'Buat Password Baru',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB51419),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Password baru Anda harus berbeda dari password yang digunakan sebelumnya.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Password
              FigmaAuthField(
                label: 'Password',
                hintText: '••••••••••••',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              FigmaAuthField(
                label: 'Confirm Password',
                hintText: '••••••••••••',
                controller: _confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 32),

              // Create New Password Button
              FigmaRedButton(
                text: 'Create New Password',
                isLoading: _isLoading,
                onPressed: _handleCreateNewPassword,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
