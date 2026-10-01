import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_repository.dart';

class AddDoctorScreen extends StatefulWidget {
  const AddDoctorScreen({super.key});

  @override
  State<AddDoctorScreen> createState() => _AddDoctorScreenState();
}

class _AddDoctorScreenState extends State<AddDoctorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _specializationController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _specializationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD81B60),
              onPrimary: Colors.white,
              onSurface: Color(0xFF222222),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dobController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitAddDoctor() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.createDoctorAsAdmin(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim().toLowerCase(),
        email: _emailController.text.trim().toLowerCase(),
        phoneNumber: _phoneController.text.trim(),
        dob: _dobController.text.trim(),
        specialization: _specializationController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dokter berhasil ditambahkan!'),
          backgroundColor: Color(0xFF2E7D32),
        ),
      );

      // Reset form & pindah ke tab daftar dokter
      _fullNameController.clear();
      _usernameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _dobController.clear();
      _specializationController.clear();
      _passwordController.clear();

      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFFD81B60),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleDoctorStatus(AppUser doctor) async {
    final nextStatus = !doctor.isActive;
    try {
      await UserRepository.instance.setDoctorActive(doctor.uid, isActive: nextStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextStatus
                ? 'Akun ${doctor.fullName} diaktifkan.'
                : 'Akun ${doctor.fullName} dinonaktifkan.',
          ),
          backgroundColor: nextStatus ? const Color(0xFF2E7D32) : const Color(0xFFD81B60),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah status: $e'),
          backgroundColor: const Color(0xFFD81B60),
        ),
      );
    }
  }

  Future<void> _confirmResetPassword(AppUser doctor) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Kirim Reset Password?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Email instruksi reset password akan dikirim ke ${doctor.email}. Lanjutkan?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey[700])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Kirim', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService.instance.sendPasswordResetEmail(doctor.email);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email reset password terkirim ke ${doctor.email}'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim email: $e'),
            backgroundColor: const Color(0xFFD81B60),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F9), // Soft pink blush background
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF06292), // Soft pink
                Color(0xFFD81B60), // Rich rose pink
              ],
            ),
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kelola Dokter',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Tambah Dokter'),
            Tab(icon: Icon(Icons.medical_services_rounded), text: 'Daftar Dokter'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddDoctorForm(),
          _buildDoctorList(),
        ],
      ),
    );
  }

  Widget _buildAddDoctorForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD81B60).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Formulir Akun Dokter',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Akun dokter hanya dapat dibuat oleh Admin. Akun akan langsung aktif.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Nama Lengkap
                  _buildInputField(
                    controller: _fullNameController,
                    label: 'Nama Lengkap & Gelar',
                    hint: 'dr. Siti Rahma, Sp.PD',
                    icon: Icons.badge_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nama dokter wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Username
                  _buildInputField(
                    controller: _usernameController,
                    label: 'Username Akun',
                    hint: 'drsiti_rahma',
                    icon: Icons.alternate_email_rounded,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Username wajib diisi';
                      }
                      final trimmed = val.trim();
                      if (trimmed.length < 4 || trimmed.length > 20) {
                        return 'Username harus 4-20 karakter';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                        return 'Hanya huruf, angka, dan underscore (_)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email
                  _buildInputField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'dokter@dcare.id',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email wajib diisi';
                      }
                      final trimmed = val.trim();
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(trimmed)) {
                        return 'Format email tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Nomor HP
                  _buildInputField(
                    controller: _phoneController,
                    label: 'Nomor WhatsApp / HP',
                    hint: '081234567890',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Nomor HP wajib diisi';
                      }
                      final trimmed = val.trim();
                      if (!trimmed.startsWith('08')) {
                        return 'Nomor HP harus diawali 08';
                      }
                      if (trimmed.length < 10 || trimmed.length > 14) {
                        return 'Nomor HP harus 10-14 digit';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(trimmed)) {
                        return 'Hanya angka yang diperbolehkan';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Tanggal Lahir
                  InkWell(
                    onTap: _pickDob,
                    child: IgnorePointer(
                      child: _buildInputField(
                        controller: _dobController,
                        label: 'Tanggal Lahir',
                        hint: 'YYYY-MM-DD',
                        icon: Icons.cake_outlined,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Tanggal lahir wajib diisi';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Spesialisasi
                  _buildInputField(
                    controller: _specializationController,
                    label: 'Spesialisasi',
                    hint: 'Spesialis Penyakit Dalam (Sp.PD)',
                    icon: Icons.medical_information_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Spesialisasi wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Password Awal
                  _buildInputField(
                    controller: _passwordController,
                    label: 'Password Awal Akun',
                    hint: 'Minimal 8 karakter (huruf & angka)',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFFD81B60),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Password awal wajib diisi';
                      }
                      final trimmed = val.trim();
                      if (trimmed.length < 8) {
                        return 'Password minimal 8 karakter';
                      }
                      final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(trimmed);
                      final hasDigit = RegExp(r'[0-9]').hasMatch(trimmed);
                      if (!hasLetter || !hasDigit) {
                        return 'Password harus kombinasi huruf dan angka';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan (Soft Pink Gradient)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF06292), Color(0xFFD81B60)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD81B60).withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isLoading ? null : _submitAddDoctor,
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_add_rounded, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'Buat Akun Dokter',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorList() {
    return StreamBuilder<List<AppUser>>(
      stream: UserRepository.instance.streamDoctors(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD81B60)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Terjadi kesalahan memuat data dokter: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.red[800]),
              ),
            ),
          );
        }

        final doctors = snapshot.data ?? [];

        if (doctors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFCE4EC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.medical_services_outlined, size: 48, color: Color(0xFFD81B60)),
                ),
                const SizedBox(height: 14),
                Text(
                  'Belum ada akun dokter terdaftar.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = doctors[index];
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: doc.isActive ? const Color(0xFFF8BBD0).withValues(alpha: 0.6) : Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD81B60).withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: doc.isActive ? const Color(0xFFFCE4EC) : Colors.grey[300],
                        ),
                        child: Icon(
                          Icons.person,
                          color: doc.isActive ? const Color(0xFFD81B60) : Colors.grey[600],
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc.fullName,
                              style: GoogleFonts.poppins(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: doc.isActive ? const Color(0xFF141414) : Colors.grey[600],
                              ),
                            ),
                            Text(
                              doc.specialization ?? 'Dokter Spesialis',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFD81B60),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: doc.isActive
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          doc.isActive ? 'Aktif' : 'Nonaktif',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: doc.isActive
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, color: Color(0xFFFCE4EC)),
                  _buildDoctorDetailRow(Icons.alternate_email, doc.username),
                  const SizedBox(height: 4),
                  _buildDoctorDetailRow(Icons.email_outlined, doc.email),
                  const SizedBox(height: 4),
                  _buildDoctorDetailRow(Icons.phone_outlined, doc.phoneNumber),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Reset Password button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFD81B60),
                          side: const BorderSide(color: Color(0xFFD81B60)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _confirmResetPassword(doc),
                        icon: const Icon(Icons.lock_reset_rounded, size: 16),
                        label: Text('Reset Password', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      // Toggle Active Switch
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: doc.isActive
                              ? const Color(0xFFD81B60)
                              : const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () => _toggleDoctorStatus(doc),
                        icon: Icon(
                          doc.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: Text(
                          doc.isActive ? 'Nonaktifkan' : 'Aktifkan',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDoctorDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFD81B60)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF4A4A4A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFFD81B60), size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFFCF8F9),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFCE4EC)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFCE4EC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD81B60)),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
