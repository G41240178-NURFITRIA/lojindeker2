import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';

class SetPasswordScreen extends StatefulWidget {
  final String? email;
  final String? initialCode;

  const SetPasswordScreen({
    super.key,
    this.email,
    this.initialCode,
  });

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  late final TextEditingController _codeController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleCreateNewPassword() async {
    final code = _codeController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan kode pemulihan yang dikirim ke email Anda.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    if (pass.isEmpty || confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan kata sandi baru dan konfirmasinya.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    if (pass.length < 8 ||
        !pass.contains(RegExp(r'[a-zA-Z]')) ||
        !pass.contains(RegExp(r'[0-9]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kata sandi minimal 8 karakter dan harus mengandung huruf serta angka.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    if (pass != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konfirmasi kata sandi tidak cocok.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.confirmPasswordReset(
        code: code,
        newPassword: pass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kata sandi berhasil diperbarui! Silakan masuk dengan kata sandi baru Anda.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 4),
        ),
      );

      // Pop kembali ke halaman login
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    final displayEmail = widget.email?.trim() ?? '';

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
          'Atur Kata Sandi',
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
                'Buat Kata Sandi Baru',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB51419),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayEmail.isNotEmpty
                    ? 'Masukkan kode pemulihan yang dikirim ke $displayEmail beserta kata sandi baru Anda.'
                    : 'Masukkan kode pemulihan dari email beserta kata sandi baru Anda.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Kode Pemulihan
              FigmaAuthField(
                label: 'Kode Pemulihan',
                hintText: 'Tempel kode dari email atau tautan',
                controller: _codeController,
              ),
              const SizedBox(height: 16),

              // Password
              FigmaAuthField(
                label: 'Kata Sandi Baru',
                hintText: 'Minimal 8 karakter (huruf & angka)',
                controller: _passwordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              FigmaAuthField(
                label: 'Konfirmasi Kata Sandi Baru',
                hintText: 'Ulangi kata sandi baru',
                controller: _confirmPasswordController,
                isPassword: true,
              ),
              const SizedBox(height: 16),

              // Info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD0D7DE)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF0969DA), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tips: Anda juga dapat langsung mengeklik tautan pemulihan di email Google Anda untuk mereset kata sandi melalui peramban.',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF333333), height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Create New Password Button
              FigmaRedButton(
                text: 'Simpan Kata Sandi Baru',
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
