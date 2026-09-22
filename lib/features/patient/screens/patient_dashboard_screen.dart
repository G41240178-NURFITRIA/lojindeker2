import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'risk_check_screen.dart';
import 'consultation_list_screen.dart';
import 'glucose_history_screen.dart';
import 'medical_records_screen.dart';
import 'support_menu_screen.dart';
import 'live_chat_screen.dart';
import 'patient_profile_screen.dart';
import 'account_settings_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String patientName;

  const PatientDashboardScreen({
    super.key,
    this.patientName = 'Muhammad Nizam',
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedTabIndex = 0;
  late String _currentPatientName;

  @override
  void initState() {
    super.initState();
    _currentPatientName = widget.patientName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Soft blush pink background
      body: Stack(
        children: [
          // Decorative soft curved organic shape at top right (only on dashboard home)
          if (_selectedTabIndex == 0)
            Positioned(
              top: -70,
              right: -70,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF8BBD0).withValues(alpha: 0.5),
                ),
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                // Top Header hanya tampil di tab Home utama (Dashboard)
                if (_selectedTabIndex == 0) _buildHeader(),

                // Scrollable Content
                Expanded(
                  child: _buildSelectedTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (Hanya icon ini yang dapat ditekan)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Top Header Bar (Hanya tampilan / Static view)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: 3 circular action icons
          Row(
            children: [
              _buildCircleIcon(Icons.notifications_none_rounded),
              const SizedBox(width: 8),
              _buildCircleIcon(
                Icons.settings_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildCircleIcon(Icons.search_rounded),
            ],
          ),

          // Right: "Halo, Selamat Pagi", Patient Name, and Avatar (Bisa ditekan untuk membuka Profil)
          InkWell(
            onTap: () => setState(() => _selectedTabIndex = 2),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Halo, Selamat Pagi ✨',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD81B60),
                        ),
                      ),
                      Text(
                        _currentPatientName,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF141414),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
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
                              color: Colors.black.withValues(alpha: 0.08),
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
                            Icons.camera_alt_rounded,
                            size: 9,
                            color: Color(0xFFF06292),
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

  Widget _buildCircleIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
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
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF333333),
        ),
      ),
    );
  }

  /// Banner Interaktif & Komunikasi Hidup
  Widget _buildLiveCommunicativeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF0F5),
            Color(0xFFFCE4EC),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF8BBD0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF06292).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFF06292),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Asisten Sehat D-Care',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFD81B60),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E7D32),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Live',
                                style: GoogleFonts.poppins(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Siap berkomunikasi & mendampingi kesehatanmu',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCE4EC)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_rounded,
                  size: 18,
                  color: Color(0xFFF06292),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Halo $_currentPatientName! 🌸 Kondisi gula darahmu terpantau stabil. Tetap jaga pola makan, minum cukup air, dan jangan ragu berkonsultasi jika ada keluhan.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF333333),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Tombol aksi interaktif & komunikasi
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LiveChatScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF8DA1), Color(0xFFF06292)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Tanya Dokter',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalRecordsScreen(patientName: widget.patientName),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF06292), width: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.history_edu_rounded, size: 15, color: Color(0xFFD81B60)),
                        const SizedBox(width: 6),
                        Text(
                          'Lihat Riwayat',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD81B60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dashboard Content 
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Komunikasi Interaktif & Asisten Hidup
          _buildLiveCommunicativeCard(),
          const SizedBox(height: 18),

          // 1. Layanan Utama
          Text(
            'Layanan Utama',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 14),

          // (Cek Risiko, Konsultasi, Kalender Kesehatan)
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  title: 'Cek Risiko',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiskCheckScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                  title: 'Konsultasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationListScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 28),
                  title: 'Kalender\nKesehatan',
                  onTap: () => setState(() => _selectedTabIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // (Riwayat, Menu Penunjang)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 125,
                child: _buildServiceCard(
                  icon: const Icon(Icons.history_edu_rounded, color: Colors.white, size: 28),
                  title: 'Riwayat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalRecordsScreen(patientName: widget.patientName),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 125,
                child: _buildServiceCard(
                  icon: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                  title: 'Menu\nPenunjang',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupportMenuScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Status Kesehatan Anda
          Text(
            'Status Kesehatan Anda',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Resiko Diabetes : ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                    children: [
                      TextSpan(
                        text: 'Rendah',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32), // Green
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Berdasarkan pemeriksaan terakhir',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '20 Mei 2026',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. History
          Text(
            'History',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 12),

          _buildHistoryTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFD32F2F),
            label: 'Highest Glucose',
            value: '165',
            valueColor: const Color(0xFFD32F2F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHistoryTile(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF616161),
            label: 'Average Glucose',
            value: '128',
            valueColor: const Color(0xFF141414),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHistoryTile(
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Lowest Glucose',
            value: '78',
            valueColor: const Color(0xFF2E7D32),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
              );
            },
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// Service Card 
  Widget _buildServiceCard({
    required Widget icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 106,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFF8DA1),
                Color(0xFFF06292),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF06292).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 32,
                child: Center(child: icon),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// History Tile 
  Widget _buildHistoryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF424242),
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  children: [
                    TextSpan(
                      text: ' mg/dL',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom Navigation Bar 
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFAF1F1),
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
    final color = isSelected ? const Color(0xFFD81B60) : const Color(0xFFF48FB1);

    return InkWell(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ConsultationListScreen(),
            ),
          );
        } else {
          setState(() => _selectedTabIndex = index);
        }
      },
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

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildConsultationTab();
      case 2:
        return _buildProfileTab();
      case 3:
        return _buildCalendarTab();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildConsultationTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konsultasi Dokter',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
          ),
          const SizedBox(height: 6),
          Text(
            'Hubungi dokter spesialis untuk evaluasi kondisi diabetes Anda.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          _buildDoctorCard(
            name: 'Dr. Kaka',
            speciality: 'Spesialis Penyakit Dalam',
            hospital: 'RS D-Care Sejahtera',
            status: 'Online',
            statusColor: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 12),
          _buildDoctorCard(
            name: 'Dr. Ika',
            speciality: 'Spesialis Penyakit Dalam',
            hospital: 'RS D-Care Sejahtera',
            status: 'Offline',
            statusColor: const Color(0xFF757575),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String speciality,
    required String hospital,
    required String status,
    required Color statusColor,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveChatScreen(
              doctorName: name,
              specialty: speciality,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded, color: Color(0xFFD81B60), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
                  ),
                  Text(
                    speciality,
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFD81B60), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    hospital,
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return PatientProfileScreen(
      patientName: _currentPatientName,
      onBackToHome: () => setState(() => _selectedTabIndex = 0),
      isTab: true,
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalender Kesehatan',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
          ),
          const SizedBox(height: 6),
          Text(
            'Jadwal kontrol rutin dan pengingat konsumsi obat harian.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.event_available_rounded, color: Color(0xFFD81B60), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kontrol Rutin Dokter', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text('20 Juni 2026 • 09:00 WIB', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFD81B60), fontWeight: FontWeight.w600)),
                          Text('Poli Penyakit Dalam - dr. Afieta Putri, Sp.PD', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFCE4EC), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFFD81B60), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Minum Metformin HCl 500 mg', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text('Setiap Hari (07:00 & 19:00) • Sesudah Makan', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF666666))),
                        ],
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
