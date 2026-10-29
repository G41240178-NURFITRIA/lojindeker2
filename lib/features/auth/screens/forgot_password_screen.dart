import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/auth_service.dart';
import '../../../services/user_repository.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';
import 'login_screen.dart';
import 'set_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _contactController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _openEmailApp(String targetEmail) async {
    final Uri mailtoUri = Uri(
      scheme: 'mailto',
      path: targetEmail,
    );
    try {
      if (await canLaunchUrl(mailtoUri)) {
        await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {}

    // Fallback buka Gmail web
    final Uri webGmail = Uri.parse('https://mail.google.com');
    try {
      if (await canLaunchUrl(webGmail)) {
        await launchUrl(webGmail, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  void _showSuccessDialog(String targetEmail, {String? foundUsername}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_rounded,
                  color: Color(0xFF2E7D32),
                  size: 32,
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Text(
                'Permintaan Terkirim!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Tautan & kode pemulihan telah dikirim oleh Google Firebase ke alamat:',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF616161),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 10),

              // Target Email Badge
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.email_outlined, size: 15, color: Color(0xFFB51419)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            targetEmail,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212121),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (foundUsername != null && foundUsername.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Username Akun: @$foundUsername',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Buka Gmail / Email
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openEmailApp(targetEmail),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
                  label: Text(
                    'Buka Aplikasi Gmail / Email',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB51419),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Masukkan Kode Pemulihan
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SetPasswordScreen(email: targetEmail),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFB51419)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Sudah Dapat Kode? Atur Sandi Baru',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB51419),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Tombol Kembali
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _handleBack();
                },
                child: Text(
                  'Kembali ke Halaman Masuk',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSendResetLink() async {
    final rawInput = _contactController.text.trim();
    if (rawInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan alamat email atau username akun Anda.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cleanInput = rawInput.toLowerCase().trim();

      // Cek di loginLookup untuk memastikan akun terdaftar dan mendapatkan email yang benar
      final lookup = await UserRepository.instance.lookupIdentifier(cleanInput);

      String targetEmail;
      String? foundUsername;

      if (lookup != null && lookup.email.isNotEmpty) {
        targetEmail = lookup.email.trim();
      } else {
        // Jika tidak ada di loginLookup:
        if (cleanInput.contains('@')) {
          targetEmail = cleanInput;
        } else {
          throw Exception(
            'Akun dengan username / identitas "$rawInput" tidak ditemukan di database D-Care. Pastikan Anda memasukkan username atau email yang benar.',
          );
        }
      }

      // Kirim email pemulihan langsung via Firebase Auth
      await AuthService.instance.sendPasswordResetEmail(targetEmail);

      if (!mounted) return;

      // Tampilkan dialog informasi sukses
      _showSuccessDialog(targetEmail, foundUsername: foundUsername);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
          duration: const Duration(seconds: 4),
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFF06292),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: _handleBack,
          ),
          centerTitle: true,
          title: Text(
            'Lupa Kata Sandi',
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

                // Heading: Lupa Password
                Text(
                  'Lupa Kata Sandi',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB51419),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Masukkan email atau username yang terhubung dengan akun Anda. Kami akan mengirimkan tautan pemulihan kata sandi ke akun Google/Gmail Anda.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF757575),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // Email Input Field
                FigmaAuthField(
                  label: 'Email Terdaftar atau Username',
                  hintText: 'contoh@gmail.com atau username',
                  controller: _contactController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Helper Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9EAEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF8BBD0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFB51419), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tips: Jika Anda lupa email yang digunakan saat mendaftar, Anda dapat memasukkan Username akun Anda.',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF7B1113),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Send Reset Link Button
                FigmaRedButton(
                  text: 'Kirim Kode Pemulihan',
                  isLoading: _isLoading,
                  onPressed: _handleSendResetLink,
                ),
                const SizedBox(height: 32),

                // Bottom link: Ingat kata sandi? Masuk
                Center(
                  child: GestureDetector(
                    onTap: _handleBack,
                    child: RichText(
                      text: TextSpan(
                        text: 'Ingat kata sandi Anda? ',
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
      ),
    );
  }
}
