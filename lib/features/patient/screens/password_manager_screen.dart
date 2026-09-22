import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../auth/screens/forgot_password_screen.dart';

class PasswordManagerScreen extends StatefulWidget {
  const PasswordManagerScreen({super.key});

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Theme colors consistent with the app's Soft Pink palette
  static const Color _bgScreen = Color(0xFFFFF0F5);
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _darkRose = Color(0xFFD81B60);
  static const Color _inputFill = Color(0xFFFCE4EC);
  static const Color _inputBorder = Color(0xFFF8BBD0);

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleChangePassword() {
    final current = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon isi semua bidang kata sandi',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: _darkRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (newPass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konfirmasi kata sandi tidak cocok',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: _darkRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Kata sandi berhasil diperbarui!',
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _darkRose,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Password Manager',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _darkRose,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Current Password
              _buildFieldLabel('Current Password'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _currentPasswordController,
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              ),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _darkRose,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // New Password
              _buildFieldLabel('New Password'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const SizedBox(height: 18),

              // Confirm New Password
              _buildFieldLabel('Confirm New Password'),
              const SizedBox(height: 6),
              _buildPasswordField(
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const SizedBox(height: 36),

              // Change Password Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: _primaryPink.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Change Password',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _inputBorder, width: 1.0),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF222222)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: '••••••••••••',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF999999)),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF777777),
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
