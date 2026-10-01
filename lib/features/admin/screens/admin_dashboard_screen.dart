import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/landing_screen.dart';
import 'add_doctor_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTabIndex = 0;

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
                // Top Bar (Action icons on left, Profile greeting on right) - Clickable
                _buildHeader(),

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
        return _buildChatTabContent();
      case 2:
        return _buildProfileTabContent();
      case 3:
        return _buildScheduleTabContent();
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

          // Right: "Hi, WelcomeBack" and Avatar (Clickable)
          InkWell(
            onTap: () => _showProfileDialog(context),
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

  /// Main Dashboard Content (Interactive)
  Widget _buildDashboardContent() {
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
                  value: '0',
                  onTap: () => _showTotalPenggunaSheet(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSoftPinkMetricCard(
                  iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                  title: 'Total Dokter',
                  value: '0',
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
                  value: '0',
                  onTap: () => _showKonsultasiSheet(context),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildSoftPinkMetricCard(
                  iconWidget: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  title: 'Cek Risiko AI',
                  value: '0',
                  onTap: () => _showRiskAISheet(context),
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
            subtitle: 'Tambah & kelola akun',
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
            subtitle: '0 pengguna',
            onTap: () => _showKelolaPenggunaSheet(context),
          ),
          const SizedBox(height: 10),
          _buildManagementTile(
            iconWidget: const _ArticlesOutlineIcon(color: Colors.white, size: 18),
            title: 'Kelola Artikel Edukasi',
            subtitle: '3 artikel',
            onTap: () => _showKelolaArtikelSheet(context),
          ),

          const SizedBox(height: 24),

          // 3. Aktivitas Terbaru (Section Title)
          Text(
            'Aktivitas Terbaru',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
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
                _buildActivityItem(
                  iconWidget: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                  title: 'Pengguna baru terdaftar',
                  subtitle: 'User dengan email rina@gmail.com',
                  onTap: () => _showActivityDetailSheet(
                    context,
                    'Pengguna Baru Terdaftar',
                    'Akun pasien rina@gmail.com telah berhasil terdaftar pada sistem.',
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFFCE4EC)),
                ),
                _buildActivityItem(
                  iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 18),
                  title: 'Dokter baru ditambahkan',
                  subtitle: 'dr. Kaka Pratama',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddDoctorScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
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
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
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

  /// Tab 1: Chat / Konsultasi
  Widget _buildChatTabContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pesan & Konsultasi',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Color(0xFFF06292)),
                const SizedBox(height: 12),
                Text(
                  'Belum ada pesan baru',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Semua percakapan konsultasi antara dokter dan pasien akan terpantau di sini.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Profile Admin
  Widget _buildProfileTabContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFFF06292),
                  child: const Icon(Icons.person, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Administrator',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'admin@care.com',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                  label: Text('Keluar dari Akun', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 3: Jadwal / Kalender
  Widget _buildScheduleTabContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalender Kegiatan & Jadwal',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF8BBD0).withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 48, color: Color(0xFFF06292)),
                const SizedBox(height: 12),
                Text(
                  'Jadwal Terpantau Normal',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jadwal praktik dokter dan kontrol pasien terjadwal secara berkala.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757575)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Modal & Dialog Helpers
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
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
            child: const Text('Cari', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD81B60)),
            const SizedBox(width: 8),
            Text('Profil Admin', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Role: Administrator', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Email: admin@care.com', style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF616161))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _confirmLogout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTotalPenggunaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Data Total Pengguna', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Saat ini ada 0 pengguna/pasien aktif terdaftar.', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
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
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konsultasi Hari Ini', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Belum ada sesi konsultasi aktif untuk hari ini.', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiskAISheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cek Risiko AI', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Log analisa skrining risiko diabetes bertenaga AI terpantau real-time.', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showKelolaPenggunaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kelola Pengguna', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Daftar pengguna dan status akun pasien LojinDeker.', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showKelolaArtikelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kelola Artikel Edukasi', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Text('Terdapat 3 artikel aktif: Pola Makan Sehat, Olahraga Aman, dan Monitoring Gula Darah.', style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetailSheet(BuildContext context, String title, String desc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text(desc, style: GoogleFonts.poppins(fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD81B60)),
              child: const Text('Tutup', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      await AuthService.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  /// Bottom Navigation Bar (Interactive)
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFCF8F9), // Seamless soft blush tone
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined),
          _buildNavItem(1, Icons.chat_bubble_outline_rounded),
          _buildNavItem(2, Icons.person_outline_rounded),
          _buildNavItem(3, Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? const Color(0xFFD81B60) : const Color(0xFFBDBDBD);

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 26,
          color: color,
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
