import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/profile_image_service.dart';
import '../models/risk_assessment_model.dart';
import 'risk_check_screen.dart';
import 'consultation_list_screen.dart';
import 'glucose_history_screen.dart';
import 'medical_records_screen.dart';
import 'support_menu_screen.dart';
import 'live_chat_screen.dart';
import 'patient_profile_screen.dart';
import 'article_detail_screen.dart';
import 'when_to_see_doctor_screen.dart';
import 'health_calendar_screen.dart';
import 'medication_reminder_screen.dart';
import 'riwayat_risiko_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String patientName;

  const PatientDashboardScreen({super.key, this.patientName = 'Pasien'});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedTabIndex = 0;
  late String _currentPatientName;
  final ScrollController _homeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentPatientName = widget.patientName;
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
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
                Expanded(child: _buildSelectedTabContent()),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (Hanya icon ini yang dapat ditekan)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Sapaan menyesuaikan waktu secara real-time
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return 'Selamat Pagi ✨';
    } else if (hour >= 11 && hour < 15) {
      return 'Selamat Siang ☀️';
    } else if (hour >= 15 && hour < 18) {
      return 'Selamat Sore 🌅';
    } else {
      return 'Selamat Malam 🌙';
    }
  }

  /// Dialog notifikasi pasien
  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFD81B60),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Notifikasi Pasien',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141414),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationItem(
              icon: Icons.check_circle_outline_rounded,
              title: 'Selamat Datang di D-Care',
              desc: 'Gunakan aplikasi untuk memantau kesehatan dan kadar gula darah Anda.',
              time: 'Baru saja',
            ),
            const SizedBox(height: 12),
            _buildNotificationItem(
              icon: Icons.article_outlined,
              title: 'Artikel Edukasi Tersedia',
              desc: 'Tips dan panduan hidup sehat bagi penyandang diabetes.',
              time: 'Tersedia',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD81B60),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required String title,
    required String desc,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD81B60)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF141414),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Top Header Bar (Notifikasi diperbesar, pencarian dihapus, profil & sapaan diperbesar)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Kiri: Hanya Notifikasi (sedikit diperbesar, setara header)
          InkWell(
            onTap: _showNotificationDialog,
            borderRadius: BorderRadius.circular(23),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF8BBD0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 24,
                    color: Color(0xFF333333),
                  ),
                  Positioned(
                    top: 10,
                    right: 11,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD81B60),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Kanan: Sapaan Waktu Real Time, Nama Pasien, & Avatar Profil (Diperbesar setara header)
          InkWell(
            onTap: () => setState(() => _selectedTabIndex = 2),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getTimeBasedGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD81B60),
                        ),
                      ),
                      Text(
                        _currentPatientName,
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF141414),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2.5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: ValueListenableBuilder<String?>(
                            valueListenable:
                                ProfileImageService().profileImagePath,
                            builder: (context, imagePath, _) {
                              final hasCustom =
                                  imagePath != null &&
                                  File(imagePath).existsSync();
                              return hasCustom
                                  ? Image.file(
                                      File(imagePath),
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/doctor_avatar.jpg',
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              color: const Color(0xFFF06292),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            );
                                          },
                                    );
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 10,
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

  /// Banner Interaktif & Komunikasi Hidup
  Widget _buildLiveCommunicativeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF0F5), Color(0xFFFCE4EC)],
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                      MaterialPageRoute(builder: (_) => const LiveChatScreen()),
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
                        const Icon(
                          Icons.chat_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
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
                        builder: (_) => MedicalRecordsScreen(
                          patientName: _currentPatientName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF06292),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.history_edu_rounded,
                          size: 15,
                          color: Color(0xFFD81B60),
                        ),
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
      controller: _homeScrollController,
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

          // 6 Layanan Utama Beranda Pasien (Grid 3x2)
          // Baris 1: Cek Risiko, Konsultasi, Kalender Kesehatan
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  title: 'Kalender\nKesehatan',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HealthCalendarScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Baris 2: Pengingat Obat, Riwayat, Menu Penunjang
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(
                    Icons.alarm_on_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  title: 'Pengingat\nObat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicationReminderScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(
                    Icons.history_edu_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  title: 'Riwayat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalRecordsScreen(
                          patientName: _currentPatientName,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(
                    Icons.medical_services_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
            child: Builder(builder: (context) {
              // Ambil data risiko terbaru secara otomatis
              final latestRisk = dummyRiskAssessments.isNotEmpty
                  ? dummyRiskAssessments.first
                  : null;
              final riskLabel = latestRisk?.level.label ?? 'Belum ada data';
              final riskColor = latestRisk?.level.color ?? const Color(0xFF757575);
              final riskDate = latestRisk?.date ?? '-';
              return Column(
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
                          text: riskLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Berdasarkan hasil pengecekan terakhir',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    riskDate,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF424242),
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 24),

          // 3. Aktivitas Terbaru
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
            width: double.infinity,
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
              children: [
                // 1. Cek Risiko Diabetes
                _buildAktivitasItem(
                  iconWidget: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      color: Color(0xFFE56A6F),
                      size: 21,
                    ),
                  ),
                  title: 'Cek Risiko Diabetes',
                  subtitleWidget: RichText(
                    text: TextSpan(
                      text: 'Hasil terakhir: ',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF757575),
                      ),
                      children: [
                        TextSpan(
                          text: 'Risiko Rendah',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailingIcon: Icons.calendar_today_outlined,
                  trailingText: '20 Mei 2026',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatRisikoScreen(),
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFF2F2F2),
                  indent: 16,
                  endIndent: 16,
                ),

                // 2. Konsultasi Dokter
                _buildAktivitasItem(
                  iconWidget: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: _DoctorOutlineIcon(
                        color: Color(0xFFE56A6F),
                        size: 20,
                      ),
                    ),
                  ),
                  title: 'Konsultasi Dokter',
                  subtitleWidget: Text(
                    'Konsultasi terakhir dengan dr. Koko',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  trailingIcon: Icons.calendar_today_outlined,
                  trailingText: '18 Mei 2026',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationListScreen(),
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 0.8,
                  color: Color(0xFFF2F2F2),
                  indent: 16,
                  endIndent: 16,
                ),

                // 3. Pengingat Obat
                _buildAktivitasItem(
                  iconWidget: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _buildPillCapsuleIcon(),
                    ),
                  ),
                  title: 'Pengingat Obat',
                  subtitleWidget: RichText(
                    text: TextSpan(
                      text: 'Pengingat obat berikutnya: ',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF757575),
                      ),
                      children: [
                        TextSpan(
                          text: '19.00',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF141414),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailingIcon: Icons.access_time_rounded,
                  trailingText: 'Hari ini, 19.00',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicationReminderScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Artikel (langsung ke artikel tanpa judul edukasi)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Artikel',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF141414),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF8BBD0)),
                ),
                child: Text(
                  '${educationalArticles.length} Artikel',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD81B60),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Horizontal List of Educational Articles (Clickable)
          SizedBox(
            height: 245,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: educationalArticles.length,
              itemBuilder: (context, index) {
                final article = educationalArticles[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index == educationalArticles.length - 1 ? 0 : 12,
                  ),
                  child: _buildHomeArticleCard(article),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Kapan Harus Ke Dokter? Card
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WhenToSeeDoctorScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF8BBD0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF06292).withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFCE4EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volunteer_activism_rounded,
                        color: Color(0xFFD81B60),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kapan Harus Ke Dokter?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: const Color(0xFFD81B60),
                            ),
                          ),
                          Text(
                            'Kenali gejala yang perlu penanganan medis segera',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE4EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Pelajari',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFFD81B60),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: Color(0xFFD81B60),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// Article Card di bagian bawah Beranda
  Widget _buildHomeArticleCard(EducationArticle article) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 175,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF8BBD0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 98,
                decoration: BoxDecoration(
                  color: article.imageBgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        article.iconData,
                        color: article.categoryColor.withValues(alpha: 0.5),
                        size: 46,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.readTime,
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF424242),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.category,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: article.categoryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141414),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: const Color(0xFF757575),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Baca artikel',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD81B60),
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: Color(0xFFD81B60),
                        ),
                      ],
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
              colors: [Color(0xFFFF8DA1), Color(0xFFF06292)],
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
              SizedBox(height: 32, child: Center(child: icon)),
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

  /// Aktivitas Terbaru Item
  Widget _buildAktivitasItem({
    required Widget iconWidget,
    required String title,
    required Widget subtitleWidget,
    required IconData trailingIcon,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              iconWidget,
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
                        color: const Color(0xFF141414),
                      ),
                    ),
                    const SizedBox(height: 3),
                    subtitleWidget,
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    trailingIcon,
                    size: 13,
                    color: const Color(0xFF757575),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    trailingText,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF757575),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF141414),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom Pill / Capsule Icon (matching reference screenshot)
  Widget _buildPillCapsuleIcon() {
    return Transform.rotate(
      angle: -0.7,
      child: Container(
        width: 11,
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFE56A6F),
            width: 1.3,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFE56A6F),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(5)),
                ),
              ),
            ),
          ],
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
                    if (value != '-')
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
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected
        ? const Color(0xFFD81B60)
        : const Color(0xFFF48FB1);

    return InkWell(
      onTap: () {
        if (index == 0) {
          if (_selectedTabIndex != 0) {
            setState(() => _selectedTabIndex = 0);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_homeScrollController.hasClients) {
              _homeScrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
              );
            }
          });
        } else if (index == 1) {
          setState(() => _selectedTabIndex = 1);
        } else {
          setState(() => _selectedTabIndex = index);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 26, color: color),
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
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hubungi dokter spesialis untuk evaluasi kondisi diabetes Anda.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF666666),
            ),
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
            builder: (_) =>
                LiveChatScreen(doctorName: name, specialty: speciality),
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
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFFD81B60),
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                  Text(
                    speciality,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFFD81B60),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    hospital,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
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
    bodyPath.cubicTo(
      w * 0.15,
      h * 0.60,
      w * 0.35,
      h * 0.55,
      w * 0.50,
      h * 0.55,
    );
    bodyPath.cubicTo(
      w * 0.65,
      h * 0.55,
      w * 0.85,
      h * 0.60,
      w * 0.85,
      h * 0.90,
    );
    canvas.drawPath(bodyPath, paint);

    // Stethoscope loop around neck
    final stethPath = Path();
    stethPath.moveTo(w * 0.38, h * 0.55);
    stethPath.cubicTo(
      w * 0.38,
      h * 0.72,
      w * 0.62,
      h * 0.72,
      w * 0.62,
      h * 0.55,
    );
    stethPath.moveTo(w * 0.50, h * 0.68);
    stethPath.lineTo(w * 0.50, h * 0.80);
    canvas.drawPath(stethPath, paint..strokeWidth = 1.4);

    // Stethoscope bell
    canvas.drawCircle(
      Offset(w * 0.50, h * 0.82),
      1.8,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
