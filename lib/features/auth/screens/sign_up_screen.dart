import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/auth_service.dart';
import '../widgets/figma_auth_field.dart';
import '../widgets/figma_red_button.dart';
import '../widgets/role_selector.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  DateTime? _selectedDob;
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.pasien; // default role: pasien

  @override
  void dispose() {
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  /// Format DateTime ke "dd MMMM yyyy" bahasa Indonesia
  String _formatDisplay(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  /// Format ke ISO untuk disimpan ke Firestore
  String _formatStorage(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDob ?? DateTime(now.year - 20, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB51419),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF333333),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFB51419),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDob = picked);
    }
  }

  void _handleSignUp() async {
    final username = _usernameController.text.trim();
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final mobile = _mobileController.text.trim();
    final dob = _selectedDob != null ? _formatStorage(_selectedDob!) : '';

    if (username.isEmpty || fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan lengkapi username akun, username profil, email, dan password Anda.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: const Color(0xFFB51419),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Password minimal harus 6 karakter.',
            style: GoogleFonts.poppins(),
          ),
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
        username: username,
        fullName: fullName,
        phoneNumber: mobile,
        dob: dob,
        role: _selectedRole, // kirim role yang dipilih
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pendaftaran akun berhasil! Silakan login.',
            style: GoogleFonts.poppins(),
          ),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xfff06292),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
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
              // ─── Pilih Role ───────────────────────────────────────────
              Text(
                'Daftar sebagai',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB51419), Color(0xFFE53935)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: RoleSelector(
                  selectedRole: _selectedRole,
                  onRoleChanged: (role) => setState(() => _selectedRole = role),
                ),
              ),
              const SizedBox(height: 14),
              // ─────────────────────────────────────────────────────────

              // Username Akun
              FigmaAuthField(
                label: 'Username Akun',
                hintText: 'Masukkan username akun login',
                controller: _usernameController,
              ),
              const SizedBox(height: 14),

              // Username Profil (Nama Lengkap)
              FigmaAuthField(
                label: 'Username Profil',
                hintText: 'Masukkan nama / username profil Anda',
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

              // ─── Tanggal Lahir — Date Picker ───────────────────────
              Text(
                'Tanggal Lahir',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedDob != null
                          ? const Color(0xFFB51419).withValues(alpha: 0.55)
                          : const Color(0xFFE8E8E8),
                      width: 1.3,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 20,
                        color: _selectedDob != null
                            ? const Color(0xFFB51419)
                            : const Color(0xFFBBBBBB),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedDob != null
                              ? _formatDisplay(_selectedDob!)
                              : 'Pilih tanggal lahir Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            color: _selectedDob != null
                                ? const Color(0xFF222222)
                                : const Color(0xFFBBBBBB),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 26,
                        color: _selectedDob != null
                            ? const Color(0xFFB51419)
                            : const Color(0xFFBBBBBB),
                      ),
                    ],
                  ),
                ),
              ),
              // ──────────────────────────────────────────────────────

              const SizedBox(height: 18),

              // Terms & Privacy
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

              // Already have an account?
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
