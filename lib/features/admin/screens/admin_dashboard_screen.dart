import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_repository.dart';
import '../../auth/screens/login_screen.dart';
import '../../patient/screens/article_detail_screen.dart';
import '../../patient/screens/patient_profile_screen.dart';
import '../../patient/screens/risk_check_screen.dart';
import '../../patient/screens/riwayat_risiko_screen.dart';
import 'add_doctor_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTabIndex = 0;
  String _adminDisplayName = 'Administrator';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  void _loadAdminData() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      final appUser = await UserRepository.instance.findByUid(user.uid);
      if (appUser != null && mounted) {
        setState(() {
          _adminDisplayName = appUser.username.isNotEmpty
              ? appUser.username
              : (appUser.fullName.isNotEmpty ? appUser.fullName : 'Administrator');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F9), // Soft pink blush background
      body: Stack(
        children: [
          // Decorative soft curved organic shape at top right
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8BBD0).withValues(alpha: 0.35),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Bar hanya muncul di tab 0 (Dashboard Home)
                if (_selectedTabIndex == 0) _buildHeader(),

                // Content area
                Expanded(
                  child: _buildCurrentTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (Interaktif)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return PatientProfileScreen(
          patientName: _adminDisplayName,
          onBackToHome: () => setState(() => _selectedTabIndex = 0),
          onProfileUpdated: (newName) {
            setState(() => _adminDisplayName = newName);
          },
          onLogout: () => _confirmLogout(context),
          isTab: true,
        );
      default:
        return _buildDashboardContent();
    }
  }

  /// Top Header Bar (Action buttons on left, profile on right)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: 3 circular white action icons (Clickable)
          Row(
            children: [
              _buildCircleButton(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notifikasi',
                onTap: () => _showNotificationSheet(context),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.settings_outlined,
                tooltip: 'Pengaturan',
                onTap: () => _showSettingsSheet(context),
              ),
              const SizedBox(width: 8),
              _buildCircleButton(
                icon: Icons.search_rounded,
                tooltip: 'Pencarian',
                onTap: () => _showSearchDialog(context),
              ),
            ],
          ),

          // Right: "Hi, WelcomeBack" and Avatar (Clickable: buka tab profil)
          InkWell(
            onTap: () => setState(() => _selectedTabIndex = 1),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Text(
                    'Hi, WelcomeBack',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD81B60).withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/doctor_avatar.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFFF06292),
                                child: const Icon(Icons.person, color: Colors.white, size: 24),
                              );
                            },
                          ),
                        ),
                      ),
                      // Small circular badge on bottom-right of avatar
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            size: 10,
                            color: Color(0xFFD81B60),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Circular Header Icon Widget (Clickable)
  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF8BBD0), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD81B60).withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: const Color(0xFFD81B60),
          ),
        ),
      ),
    );
  }

  /// Main Dashboard Content (Interactive with Live Data)
  Widget _buildDashboardContent() {
    return StreamBuilder<List<AppUser>>(
      stream: UserRepository.instance.streamPatients(),
      builder: (context, patientSnapshot) {
        final patients = patientSnapshot.data ?? [];
        final patientCount = patients.length;

        return StreamBuilder<List<AppUser>>(
          stream: UserRepository.instance.streamDoctors(),
          builder: (context, doctorSnapshot) {
            final doctors = doctorSnapshot.data ?? [];
            final doctorCount = doctors.length;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Manajemen User (Section Title)
                  Text(
                    'Manajemen User',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2x2 Grid of Soft Pink Metric Cards (Clickable)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSoftPinkMetricCard(
                          iconWidget: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
                          title: 'Total Pengguna',
                          value: '$patientCount',
                          onTap: () => _showKelolaPenggunaSheet(context),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSoftPinkMetricCard(
                          iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                          title: 'Total Dokter',
                          value: '$doctorCount',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSoftPinkMetricCard(
                          iconWidget: const _StethoscopeOutlineIcon(color: Colors.white, size: 28),
                          title: 'Konsultasi Hari ini',
                          value: '2',
                          onTap: () => _showKonsultasiSheet(context),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSoftPinkMetricCard(
                          iconWidget: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                          title: 'Cek Risiko',
                          value: '5',
                          onTap: () => _showRiskCheckSheet(context),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 2. Kelola Sistem (Section Title)
                  Text(
                    'Kelola Sistem',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildManagementTile(
                    iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 18),
                    title: 'Kelola Dokter',
                    subtitle: doctorCount > 0 ? '$doctorCount dokter aktif' : 'Tambah & kelola akun',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildManagementTile(
                    iconWidget: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                    title: 'Kelola Pengguna',
                    subtitle: '$patientCount pengguna terdaftar',
                    onTap: () => _showKelolaPenggunaSheet(context),
                  ),
                  const SizedBox(height: 10),
                  _buildManagementTile(
                    iconWidget: const _ArticlesOutlineIcon(color: Colors.white, size: 18),
                    title: 'Kelola Artikel Edukasi',
                    subtitle: '${educationalArticles.length} artikel aktif',
                    onTap: () => _showKelolaArtikelSheet(context),
                  ),

                  const SizedBox(height: 24),

                  // 3. Aktivitas Terbaru (Section Title)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Aktivitas Terbaru',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF141414),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showAllActivitiesSheet(context, patients, doctors),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            'Lihat Semua',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD81B60),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.5), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD81B60).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Activity 1: Patient registration
                        _buildActivityItem(
                          iconWidget: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 18),
                          title: patients.isNotEmpty
                              ? 'Pasien terdaftar: ${patients.first.fullName}'
                              : 'Pengguna baru terdaftar',
                          subtitle: patients.isNotEmpty
                              ? patients.first.email
                              : 'User dengan email rina@gmail.com',
                          timeAgo: 'Baru saja',
                          onTap: () => _showKelolaPenggunaSheet(context),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFFCE4EC)),
                        ),
                        // Activity 2: Doctor added
                        _buildActivityItem(
                          iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 18),
                          title: doctors.isNotEmpty
                              ? 'Dokter aktif: ${doctors.first.fullName}'
                              : 'Dokter baru ditambahkan',
                          subtitle: doctors.isNotEmpty
                              ? (doctors.first.specialization ?? 'Spesialis Penyakit Dalam')
                              : 'dr. Kaka Pratama - Spesialis',
                          timeAgo: '1 jam lalu',
                          onTap: () {
                            if (doctors.isNotEmpty) {
                              _showDoctorDetailSheet(context, doctors.first);
                            } else {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const AddDoctorScreen(initialIndex: 1)),
                              );
                            }
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFFCE4EC)),
                        ),
                        // Activity 3: Cek Risiko
                        _buildActivityItem(
                          iconWidget: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 18),
                          title: 'Cek Risiko',
                          subtitle: 'Evaluasi mandiri risiko pasien selesai',
                          timeAgo: '3 jam lalu',
                          onTap: () => _showRiskCheckSheet(context),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1, color: Color(0xFFFCE4EC)),
                        ),
                        // Activity 4: Educational Article Published
                        _buildActivityItem(
                          iconWidget: const _ArticlesOutlineIcon(color: Colors.white, size: 18),
                          title: 'Artikel Edukasi Diperbarui',
                          subtitle: '3 materi edukasi aktif & siap diakses pasien',
                          timeAgo: 'Hari ini',
                          onTap: () => _showKelolaArtikelSheet(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 2x2 Soft Pink Metric Card (Interactive)
  Widget _buildSoftPinkMetricCard({
    required Widget iconWidget,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 116,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF06292), // Soft pink
                Color(0xFFD81B60), // Rich rose pink
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD81B60).withValues(alpha: 0.28),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 28,
                child: Center(child: iconWidget),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// System Management List Tile (Interactive)
  Widget _buildManagementTile({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD81B60).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF06292),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF888888),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD81B60),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Activity List Item (Interactive)
  Widget _buildActivityItem({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    String? timeAgo,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF06292),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF757575),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (timeAgo != null) ...[
                const SizedBox(width: 6),
                Text(
                  timeAgo,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFFB0BEC5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD81B60),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// =========================================================================
  /// MODALS DENGAN ISI LENGKAP MENYESUAIKAN FITUR (KELOLA PENGGUNA, ARTIKEL, AKTIVITAS)
  /// =========================================================================

  /// 1. KELOLA PENGGUNA (Lengkap dengan data pasien real, status, search, toggle status, reset password)
  void _showKelolaPenggunaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _KelolaPenggunaModalContent(),
    );
  }

  /// 2. KELOLA ARTIKEL EDUKASI (Lengkap dengan 3 artikel edukasi, cover image, navigasi ke detail)
  void _showKelolaArtikelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _KelolaArtikelModalContent(),
    );
  }

  /// 3. AKTIVITAS TERBARU (Lengkap dengan riwayat log sistem dan navigasi cepat)
  void _showAllActivitiesSheet(BuildContext context, List<AppUser> patients, List<AppUser> doctors) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AktivitasTerbaruModalContent(
        patients: patients,
        doctors: doctors,
        onOpenPengguna: () {
          Navigator.pop(ctx);
          _showKelolaPenggunaSheet(context);
        },
        onOpenDokter: () {
          Navigator.pop(ctx);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddDoctorScreen(initialIndex: 1)));
        },
        onOpenArtikel: () {
          Navigator.pop(ctx);
          _showKelolaArtikelSheet(context);
        },
        onOpenRiskAI: () {
          Navigator.pop(ctx);
          _showRiskCheckSheet(context);
        },
      ),
    );
  }

  /// Detail Profil Dokter dari Aktivitas Terbaru
  void _showDoctorDetailSheet(BuildContext context, AppUser doctor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFFCE4EC),
                  child: Icon(
                    Icons.person,
                    color: doctor.isActive ? const Color(0xFFD81B60) : Colors.grey,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.fullName,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        doctor.specialization ?? 'Dokter Spesialis',
                        style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFFD81B60), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: doctor.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    doctor.isActive ? 'Aktif' : 'Nonaktif',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: doctor.isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFFCE4EC)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Color(0xFFD81B60)),
                const SizedBox(width: 8),
                Text('Email: ${doctor.email}', style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF424242))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Color(0xFFD81B60)),
                const SizedBox(width: 8),
                Text('WhatsApp: ${doctor.phoneNumber}', style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF424242))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.alternate_email, size: 16, color: Color(0xFFD81B60)),
                const SizedBox(width: 8),
                Text('Username: @${doctor.username}', style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF424242))),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF8BBD0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Tutup', style: GoogleFonts.poppins(color: const Color(0xFF757575))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddDoctorScreen(initialIndex: 1)),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Daftar Dokter', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showKonsultasiSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: Color(0xFFD81B60), size: 22),
                ),
                const SizedBox(width: 12),
                Text('Konsultasi Hari Ini', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Terdapat 2 sesi konsultasi dokter aktif yang sedang berlangsung hari ini via chat telemedis.',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF424242)),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD81B60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Tutup', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiskCheckSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFD81B60), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cek Risiko', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text('Deteksi dini faktor risiko diabetes pasien', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF757575))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Fitur Cek Risiko memfasilitasi skrining mandiri faktor risiko diabetes (IMT, riwayat keluarga, hipertensi, merokok, dll) untuk tindakan preventif dan pemantauan kesehatan.',
              style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF424242)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RiskCheckScreen()),
                      );
                    },
                    icon: const Icon(Icons.play_circle_outline_rounded, size: 16, color: Color(0xFFD81B60)),
                    label: Text('Mulai Cek', style: GoogleFonts.poppins(color: const Color(0xFFD81B60), fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFF8BBD0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RiwayatRisikoScreen()),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 16, color: Colors.white),
                    label: Text('Riwayat Risiko', style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD81B60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFFD81B60)),
                const SizedBox(width: 8),
                Text('Pemberitahuan Admin', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFFCE4EC), child: Icon(Icons.check, color: Color(0xFFD81B60))),
              title: Text('Sistem LojinDeker Normal', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              subtitle: Text('Semua layanan berjalan lancar.', style: GoogleFonts.poppins(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengaturan Administrator', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFFD81B60)),
              title: Text('Ubah Kata Sandi', style: GoogleFonts.poppins(fontSize: 13)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur ubah kata sandi admin siap digunakan.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: Text('Keluar', style: GoogleFonts.poppins(fontSize: 13, color: Colors.red, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pencarian Data', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Cari nama dokter, pasien...',
            hintStyle: GoogleFonts.poppins(fontSize: 12),
            prefixIcon: const Icon(Icons.search, color: Color(0xFFD81B60)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD81B60)),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showKelolaPenggunaSheet(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
            child: const Text('Cari Pasien', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }



  Future<void> _confirmLogout(BuildContext context) async {
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konfirmasi Keluar', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.signOut();
      if (!mounted) return;
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Bottom Navigation Bar (Interactive - Home dan Profil)
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFCF8F9), // Seamless soft blush tone
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, Icons.home_rounded),
          _buildNavItem(1, Icons.person_outline_rounded, Icons.person_rounded),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData inactiveIcon, [IconData? activeIcon]) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? const Color(0xFFD81B60) : const Color(0xFFB0BEC5);

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Icon(
          isSelected ? (activeIcon ?? inactiveIcon) : inactiveIcon,
          size: 28,
          color: color,
        ),
      ),
    );
  }
}

/// =========================================================================
/// 1. KOMPONEN KELOLA PENGGUNA DENGAN ISI REAL & INTERAKTIF
/// =========================================================================
class _KelolaPenggunaModalContent extends StatefulWidget {
  const _KelolaPenggunaModalContent();

  @override
  State<_KelolaPenggunaModalContent> createState() => _KelolaPenggunaModalContentState();
}

class _KelolaPenggunaModalContentState extends State<_KelolaPenggunaModalContent> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.people_alt_rounded, color: Color(0xFFD81B60), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            'Daftar akun pasien & status keanggotaan',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, username...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD81B60), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFFCF8F9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFF8BBD0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFFCE4EC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFD81B60), width: 1.5),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF8BBD0)),

              // Stream Patients
              Expanded(
                child: StreamBuilder<List<AppUser>>(
                  stream: UserRepository.instance.streamPatients(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFD81B60)),
                      );
                    }

                    final allPatients = snapshot.data ?? [];
                    final filtered = allPatients.where((p) {
                      if (_searchQuery.isEmpty) return true;
                      return p.fullName.toLowerCase().contains(_searchQuery) ||
                          p.email.toLowerCase().contains(_searchQuery) ||
                          p.username.toLowerCase().contains(_searchQuery) ||
                          p.phoneNumber.contains(_searchQuery);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFCE4EC),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.people_outline_rounded, size: 42, color: Color(0xFFD81B60)),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty ? 'Belum ada data pasien terdaftar' : 'Pasien tidak ditemukan',
                                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Pasien yang mendaftar melalui aplikasi akan muncul secara otomatis di sini.'
                                    : 'Coba periksa kembali kata kunci pencarian Anda.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757575)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final patient = filtered[index];
                        return _buildPatientCard(context, patient);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPatientCard(BuildContext context, AppUser patient) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: patient.isActive
              ? const Color(0xFFF8BBD0).withValues(alpha: 0.6)
              : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD81B60).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: patient.isActive ? const Color(0xFFFCE4EC) : Colors.grey.shade200,
                child: Text(
                  patient.fullName.isNotEmpty ? patient.fullName[0].toUpperCase() : 'P',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: patient.isActive ? const Color(0xFFD81B60) : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            patient.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: patient.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            patient.isActive ? 'Aktif' : 'Nonaktif',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: patient.isActive ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${patient.username} • ${patient.email}',
                      style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (patient.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF9E9E9E)),
                          const SizedBox(width: 4),
                          Text(
                            patient.phoneNumber,
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFFCE4EC)),
          const SizedBox(height: 8),

          // Action buttons for each patient
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Reset Password Button
              TextButton.icon(
                onPressed: () async {
                  try {
                    await AuthService.instance.sendPasswordResetEmail(patient.email);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: const Color(0xFFD81B60),
                          content: Text('Link reset password dikirim ke ${patient.email}'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal mengirim link: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.lock_reset_rounded, size: 16, color: Color(0xFFD81B60)),
                label: Text(
                  'Reset Sandi',
                  style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFD81B60)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
              const SizedBox(width: 6),

              // Toggle Active/Inactive Button
              OutlinedButton.icon(
                onPressed: () async {
                  final newStatus = !patient.isActive;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text(
                        newStatus ? 'Aktifkan Pasien?' : 'Nonaktifkan Pasien?',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                      ),
                      content: Text(
                        newStatus
                            ? 'Akun ${patient.fullName} akan dapat masuk dan menggunakan layanan LojinDeker kembali.'
                            : 'Akun ${patient.fullName} akan dinonaktifkan sementara dari sistem.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: newStatus ? const Color(0xFF2E7D32) : const Color(0xFFD81B60),
                          ),
                          child: Text(newStatus ? 'Aktifkan' : 'Nonaktifkan', style: const TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await UserRepository.instance.setPatientActive(patient.uid, isActive: newStatus);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: newStatus ? const Color(0xFF2E7D32) : const Color(0xFFD81B60),
                          content: Text('Status akun ${patient.fullName} berhasil diperbarui.'),
                        ),
                      );
                    }
                  }
                },
                icon: Icon(
                  patient.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                  size: 15,
                  color: patient.isActive ? Colors.red.shade700 : const Color(0xFF2E7D32),
                ),
                label: Text(
                  patient.isActive ? 'Nonaktifkan' : 'Aktifkan',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: patient.isActive ? Colors.red.shade700 : const Color(0xFF2E7D32),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: patient.isActive ? Colors.red.shade200 : Colors.green.shade200,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// =========================================================================
/// 2. KOMPONEN KELOLA ARTIKEL EDUKASI DENGAN ISI REAL & INTERAKTIF
/// =========================================================================
class _KelolaArtikelModalContent extends StatelessWidget {
  const _KelolaArtikelModalContent();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const _ArticlesOutlineIcon(color: Color(0xFFD81B60), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kelola Artikel Edukasi',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            '${educationalArticles.length} materi edukasi pasien diabetes terbit',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF8BBD0)),

              // List of Articles
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  itemCount: educationalArticles.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final article = educationalArticles[index];
                    return _buildArticleItemCard(context, article);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArticleItemCard(BuildContext context, EducationArticle article) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD81B60).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Banner
          if (article.imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              child: Image.asset(
                article.imagePath!,
                width: double.infinity,
                height: 130,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  height: 100,
                  color: const Color(0xFFFCE4EC),
                  child: const Center(
                    child: Icon(Icons.image_rounded, size: 36, color: Color(0xFFD81B60)),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Capsule & Read Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: article.categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: article.categoryColor,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 4),
                        Text(
                          article.readTime,
                          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Title
                Text(
                  article.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  article.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF616161),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),

                // Reviewer Doctor Info & Button
                Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Reviewer: ${article.reviewer}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF424242),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ArticleDetailScreen(article: article),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 14, color: Colors.white),
                      label: Text(
                        'Buka Detail',
                        style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD81B60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =========================================================================
/// 3. KOMPONEN AKTIVITAS TERBARU DENGAN ISI REAL & INTERAKTIF
/// =========================================================================
class _AktivitasTerbaruModalContent extends StatelessWidget {
  final List<AppUser> patients;
  final List<AppUser> doctors;
  final VoidCallback onOpenPengguna;
  final VoidCallback onOpenDokter;
  final VoidCallback onOpenArtikel;
  final VoidCallback onOpenRiskAI;

  const _AktivitasTerbaruModalContent({
    required this.patients,
    required this.doctors,
    required this.onOpenPengguna,
    required this.onOpenDokter,
    required this.onOpenArtikel,
    required this.onOpenRiskAI,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFFD81B60), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Semua Aktivitas Terbaru',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1F1F1F),
                            ),
                          ),
                          Text(
                            'Log kegiatan sistem & interaksi pengguna',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF8BBD0)),

              // Activity Feed List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    _buildFullActivityCard(
                      icon: Icons.person_add_alt_1_rounded,
                      title: patients.isNotEmpty
                          ? 'Pendaftaran Pasien: ${patients.first.fullName}'
                          : 'Pasien baru mendaftar di sistem',
                      subtitle: patients.isNotEmpty
                          ? 'Email: ${patients.first.email} • Status akun aktif'
                          : 'User dengan email rina@gmail.com telah terdaftar',
                      time: '5 Menit yang lalu',
                      actionLabel: 'Kelola Pengguna',
                      onTap: onOpenPengguna,
                    ),
                    const SizedBox(height: 12),
                    _buildFullActivityCard(
                      icon: Icons.medical_services_rounded,
                      title: doctors.isNotEmpty
                          ? 'Dokter Aktif: ${doctors.first.fullName}'
                          : 'Akun Dokter Baru Ditambahkan',
                      subtitle: doctors.isNotEmpty
                          ? '${doctors.first.specialization ?? 'Spesialis'} • Siap melayani konsultasi'
                          : 'dr. Kaka Pratama - Spesialis Penyakit Dalam',
                      time: '1 Jam yang lalu',
                      actionLabel: 'Kelola Dokter',
                      onTap: onOpenDokter,
                    ),
                    const SizedBox(height: 12),
                    _buildFullActivityCard(
                      icon: Icons.health_and_safety_rounded,
                      title: 'Cek Risiko Selesai',
                      subtitle: 'Pasien menyelesaikan evaluasi mandiri faktor risiko diabetes.',
                      time: '3 Jam yang lalu',
                      actionLabel: 'Buka Cek Risiko',
                      onTap: onOpenRiskAI,
                    ),
                    const SizedBox(height: 12),
                    _buildFullActivityCard(
                      icon: Icons.article_rounded,
                      title: 'Pembaruan Artikel Edukasi',
                      subtitle: 'Materi edukasi "Pola Makan Sehat", "Aktivitas Fisik", & "Monitoring" aktif.',
                      time: 'Hari ini, 09:00',
                      actionLabel: 'Buka Artikel',
                      onTap: onOpenArtikel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFullActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD81B60).withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFD81B60), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F1F1F),
                          ),
                        ),
                      ),
                      Text(
                        time,
                        style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF616161)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        actionLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD81B60),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFD81B60)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom Doctor Outline Icon
class _DoctorOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _DoctorOutlineIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoctorOutlinePainter(color: color),
    );
  }
}

class _DoctorOutlinePainter extends CustomPainter {
  final Color color;

  _DoctorOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Doctor head
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.20, paint);

    // Doctor shoulders/torso
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.15, h * 0.90);
    bodyPath.cubicTo(w * 0.15, h * 0.60, w * 0.35, h * 0.55, w * 0.50, h * 0.55);
    bodyPath.cubicTo(w * 0.65, h * 0.55, w * 0.85, h * 0.60, w * 0.85, h * 0.90);
    canvas.drawPath(bodyPath, paint);

    // Stethoscope loop around neck
    final stethPath = Path();
    stethPath.moveTo(w * 0.38, h * 0.55);
    stethPath.cubicTo(w * 0.38, h * 0.72, w * 0.62, h * 0.72, w * 0.62, h * 0.55);
    stethPath.moveTo(w * 0.50, h * 0.68);
    stethPath.lineTo(w * 0.50, h * 0.80);
    canvas.drawPath(stethPath, paint..strokeWidth = 1.4);

    // Stethoscope bell
    canvas.drawCircle(Offset(w * 0.50, h * 0.82), 1.8, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Stethoscope Outline Icon
class _StethoscopeOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _StethoscopeOutlineIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StethoscopeOutlinePainter(color: color),
    );
  }
}

class _StethoscopeOutlinePainter extends CustomPainter {
  final Color color;

  _StethoscopeOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Eartips
    canvas.drawCircle(Offset(w * 0.32, h * 0.18), 1.8, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.68, h * 0.18), 1.8, Paint()..color = color..style = PaintingStyle.fill);

    // Binaural tubes curving to junction
    final path = Path();
    path.moveTo(w * 0.32, h * 0.18);
    path.cubicTo(w * 0.32, h * 0.42, w * 0.50, h * 0.46, w * 0.50, h * 0.56);

    final path2 = Path();
    path2.moveTo(w * 0.68, h * 0.18);
    path2.cubicTo(w * 0.68, h * 0.42, w * 0.50, h * 0.46, w * 0.50, h * 0.56);
    path.addPath(path2, Offset.zero);

    // Loop to chestpiece
    path.cubicTo(w * 0.50, h * 0.76, w * 0.82, h * 0.76, w * 0.82, h * 0.60);
    path.cubicTo(w * 0.82, h * 0.48, w * 0.70, h * 0.48, w * 0.70, h * 0.58);
    canvas.drawPath(path, paint);

    // Chestpiece (diaphragm)
    canvas.drawCircle(Offset(w * 0.70, h * 0.58), 2.5, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Articles / Books Outline Icon
class _ArticlesOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _ArticlesOutlineIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArticlesOutlinePainter(color: color),
    );
  }
}

class _ArticlesOutlinePainter extends CustomPainter {
  final Color color;

  _ArticlesOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Bookshelf line
    canvas.drawLine(Offset(w * 0.10, h * 0.85), Offset(w * 0.90, h * 0.85), paint);

    // Book 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.16, h * 0.63), const Radius.circular(2)),
      paint,
    );

    // Book 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.22, w * 0.16, h * 0.63), const Radius.circular(2)),
      paint,
    );

    // Book 3
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.64, h * 0.22, w * 0.16, h * 0.63), const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
