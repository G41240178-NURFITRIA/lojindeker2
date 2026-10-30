import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/article_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/patient_activity_service.dart';
import '../../../core/services/profile_image_service.dart';
import '../../../core/services/patient_chat_notification_service.dart';
import 'risk_check_screen.dart';
import 'consultation_list_screen.dart';
import 'medical_records_screen.dart';
import 'nearest_facility_screen.dart';
import 'live_chat_screen.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';
import 'patient_profile_screen.dart';
import 'article_detail_screen.dart';
import 'when_to_see_doctor_screen.dart';
import 'health_calendar_screen.dart';
import 'medication_reminder_screen.dart';
import 'riwayat_risiko_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/consultation_booking_model.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String patientName;
  final int initialTabIndex;

  const PatientDashboardScreen({
    super.key,
    this.patientName = 'Pasien',
    this.initialTabIndex = 0,
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late int _selectedTabIndex;
  late String _currentPatientName;
  final ScrollController _homeScrollController = ScrollController();

  // Artikel admin dari Firestore (real-time)
  List<AdminArticleModel> _adminArticles = [];
  StreamSubscription<List<AdminArticleModel>>? _articleSub;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex;
    _currentPatientName = widget.patientName;
    _loadCurrentProfile();
    _subscribeToAdminArticles();
  }

  void _subscribeToAdminArticles() {
    _articleSub = ArticleService.instance.streamArticles().listen(
      (articles) {
        if (mounted) setState(() => _adminArticles = articles);
      },
      onError: (e) {
        debugPrint('⚠️ [PatientDashboard] Gagal memuat artikel admin: $e');
      },
    );
  }

  void _loadCurrentProfile() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      PatientActivityService.instance.loadUserDataFromFirestore();
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && mounted) {
          final data = doc.data()!;
          final profileName = (data['fullName'] ?? data['profileName'] ?? data['name'])?.toString();
          if (profileName != null && profileName.trim().isNotEmpty) {
            setState(() {
              _currentPatientName = profileName.trim();
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading current profile in dashboard: $e');
      }
    }
  }

  @override
  void dispose() {
    _articleSub?.cancel();
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
                    child: ValueListenableBuilder<String?>(
                      valueListenable: ProfileImageService().profileImagePath,
                      builder: (context, imagePath, _) {
                        return DoctorAvatarWidget(
                          photoUrl: imagePath,
                          size: 50,
                          initials: _currentPatientName.isNotEmpty ? _currentPatientName[0] : null,
                          backgroundColor: const Color(0xFFF06292),
                          iconColor: Colors.white,
                        );
                      },
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
                child: ValueListenableBuilder<int>(
                  valueListenable:
                      PatientChatNotificationService.instance.unreadTotalNotifier,
                  builder: (context, unreadCount, _) {
                    return _buildServiceCard(
                      icon: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                      title: 'Konsultasi',
                      showBadge: unreadCount > 0,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConsultationListScreen(),
                          ),
                        );
                      },
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
                    Icons.place_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  title: 'Faskes\nTerdekat',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NearestFacilityScreen(),
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
            child: ValueListenableBuilder<PatientRiskRecord?>(
              valueListenable: PatientActivityService.instance.latestRiskNotifier,
              builder: (context, latestRisk, _) {
                if (latestRisk == null) {
                  // Empty state — belum pernah cek risiko
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RiskCheckScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.health_and_safety_outlined,
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
                                  'Belum ada data risiko',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF141414),
                                  ),
                                ),
                                Text(
                                  'Lakukan cek risiko pertama Anda sekarang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD81B60),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Cek Sekarang',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                // Ada data — tampilkan status risiko
                final riskLabel = latestRisk.status;
                final riskColor = latestRisk.statusColor;
                final riskDate = latestRisk.date;
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
              },
            ),
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

          ValueListenableBuilder<List<PatientRiskRecord>>(
            valueListenable: PatientActivityService.instance.riskHistoryNotifier,
            builder: (context, riskHistory, _) {
              return ValueListenableBuilder<PatientConsultationActivity?>(
                valueListenable: PatientActivityService.instance.latestConsultationNotifier,
                builder: (context, latestConsultation, _) {
                  return ValueListenableBuilder<List<MedicationReminder>>(
                    valueListenable: PatientActivityService.instance.remindersNotifier,
                    builder: (context, reminders, _) {
                      final nextReminder = PatientActivityService.instance.getNextReminderInfo();
                      final hasRisk = riskHistory.isNotEmpty;
                      final hasConsultation = latestConsultation != null;
                      final hasReminder = reminders.isNotEmpty;

                      // Jika semua kosong — tampilkan empty state yang informatif
                      if (!hasRisk && !hasConsultation && !hasReminder) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
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
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF0F5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.history_edu_rounded,
                                  color: Color(0xFFD81B60),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada aktivitas',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF141414),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Mulai gunakan layanan untuk melihat aktivitas Anda di sini',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF757575),
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
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
                            if (hasRisk) ..._buildCekRisikoItem(riskHistory.first),

                            if (hasRisk && (hasConsultation || hasReminder))
                              const Divider(
                                height: 1,
                                thickness: 0.8,
                                color: Color(0xFFF2F2F2),
                                indent: 16,
                                endIndent: 16,
                              ),

                            // 2. Konsultasi Dokter
                            if (hasConsultation)
                              ..._buildKonsultasiItem(latestConsultation),

                            if (hasConsultation && hasReminder)
                              const Divider(
                                height: 1,
                                thickness: 0.8,
                                color: Color(0xFFF2F2F2),
                                indent: 16,
                                endIndent: 16,
                              ),

                            // 3. Pengingat Obat
                            if (hasReminder) ..._buildPengingatItem(nextReminder),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),

          const SizedBox(height: 26),

          // Artikel (langsung ke artikel tanpa judul edukasi) - Real-time StreamBuilder
          StreamBuilder<List<AdminArticleModel>>(
            stream: ArticleService.instance.streamArticles(),
            builder: (context, snapshot) {
              final adminArticles = snapshot.data ?? _adminArticles;
              final totalCount = educationalArticles.length + adminArticles.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                          '$totalCount Artikel',
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

                  // Horizontal List: Artikel admin (Firestore real-time) + artikel bawaan
                  SizedBox(
                    height: 295,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: totalCount,
                      itemBuilder: (context, index) {
                        final isAdminArticle = index < adminArticles.length;
                        final isLast = index == totalCount - 1;
                        if (isAdminArticle) {
                          final article = adminArticles[index];
                          return Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 12),
                            child: _buildAdminArticleCard(article),
                          );
                        } else {
                          final article = educationalArticles[index - adminArticles.length];
                          return Padding(
                            padding: EdgeInsets.only(right: isLast ? 0 : 12),
                            child: _buildHomeArticleCard(article),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
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
                height: 145,
                decoration: BoxDecoration(
                  color: article.imageBgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  children: [
                    if (article.imagePath != null)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.asset(
                            article.imagePath!,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            errorBuilder: (_, _, _) => Center(
                              child: Icon(
                                article.iconData,
                                color: article.categoryColor.withValues(alpha: 0.5),
                                size: 46,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Icon(
                          article.iconData,
                          color: article.categoryColor.withValues(alpha: 0.5),
                          size: 46,
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: article.categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: article.categoryColor,
                        ),
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

  /// Card artikel dari admin (Firestore real-time) - dengan bottom sheet detail real-time
  Widget _buildAdminArticleCard(AdminArticleModel article) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showAdminArticleDetailSheet(context, article),
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
                height: 145,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFD81B60), Color(0xFFF06292)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.article_rounded,
                        size: 48,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          'Baru',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD81B60),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD81B60).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD81B60),
                        ),
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
                      article.subtitle.isNotEmpty ? article.subtitle : article.content,
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
    bool showBadge = false,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
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
              if (showBadge)
                Positioned(
                  top: -2,
                  right: 2,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.8,
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

  /// Helper: Item Cek Risiko Diabetes
  List<Widget> _buildCekRisikoItem(PatientRiskRecord risk) {
    return [
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
            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
            children: [
              TextSpan(
                text: 'Risiko ${risk.status}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: risk.statusColor,
                ),
              ),
            ],
          ),
        ),
        trailingIcon: Icons.calendar_today_outlined,
        trailingText: risk.date,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RiwayatRisikoScreen()),
          );
        },
      ),
    ];
  }

  /// Helper: Item Konsultasi Dokter
  List<Widget> _buildKonsultasiItem(PatientConsultationActivity consultation) {
    return [
      _buildAktivitasItem(
        iconWidget: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: _DoctorOutlineIcon(color: Color(0xFFE56A6F), size: 20),
          ),
        ),
        title: 'Konsultasi Dokter',
        subtitleWidget: Text(
          'Terakhir dengan ${consultation.doctorName}',
          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
        ),
        trailingIcon: Icons.calendar_today_outlined,
        trailingText: consultation.date,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ConsultationListScreen()),
          );
        },
      ),
    ];
  }

  /// Helper: Item Pengingat Obat
  List<Widget> _buildPengingatItem(NextReminderInfo nextReminder) {
    return [
      _buildAktivitasItem(
        iconWidget: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: _buildPillCapsuleIcon()),
        ),
        title: 'Pengingat Obat',
        subtitleWidget: Text(
          nextReminder.subtitleText,
          style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
        ),
        trailingIcon: Icons.access_time_rounded,
        trailingText: nextReminder.labelText,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
          );
        },
      ),
    ];
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
          _buildNavItem(1, Icons.calendar_month_outlined),
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

    Widget iconWidget = Icon(icon, size: 26, color: color);

    // Titik merah (red dot) pada tab Chat sudah dipindah, index 1 = Riwayat Booking
    if (index == 99) {  // disabled
      iconWidget = ValueListenableBuilder<int>(
        valueListenable:
            PatientChatNotificationService.instance.unreadTotalNotifier,
        builder: (context, unreadCount, child) {
          if (unreadCount <= 0) return child!;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child!,
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: iconWidget,
      );
    }

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
        child: iconWidget,
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

  // ── RIWAYAT BOOKING TAB ────────────────────────────────────────────────
  Widget _buildConsultationTab() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('consultation_bookings')
          .where('patientId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final bookings = snapshot.hasData
            ? (snapshot.data!.docs
                .map((d) => ConsultationBookingModel.fromFirestore(d))
                .toList()
              ..sort((a, b) {
                final dateA = a.createdAt ?? DateTime(2000);
                final dateB = b.createdAt ?? DateTime(2000);
                return dateB.compareTo(dateA);
              }))
            : <ConsultationBookingModel>[];

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Booking',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141414),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Semua jadwal konsultasi yang telah kamu buat.',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            if (snapshot.connectionState == ConnectionState.waiting)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD81B60)),
                ),
              )
            else if (bookings.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada booking',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Booking konsultasi dokter terlebih dahulu\ndari menu Beranda.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _BookingHistoryCardItem(booking: bookings[i]),
                    ),
                    childCount: bookings.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBookingCard(ConsultationBookingModel b) {
    return _BookingHistoryCardItem(booking: b);
  }

  Widget _buildProfileTab() {
    return PatientProfileScreen(
      patientName: _currentPatientName,
      onBackToHome: () => setState(() => _selectedTabIndex = 0),
      onProfileUpdated: (newName) {
        setState(() {
          _currentPatientName = newName;
        });
      },
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

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET KARTU RIWAYAT BOOKING DENGAN COUNTDOWN TIMER & MODE UJI COBA
// ─────────────────────────────────────────────────────────────────────────────
class _BookingHistoryCardItem extends StatefulWidget {
  final ConsultationBookingModel booking;

  const _BookingHistoryCardItem({required this.booking});

  @override
  State<_BookingHistoryCardItem> createState() => _BookingHistoryCardItemState();
}

class _BookingHistoryCardItemState extends State<_BookingHistoryCardItem> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

  @override
  void didUpdateWidget(covariant _BookingHistoryCardItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.booking.timeSlot != widget.booking.timeSlot ||
        oldWidget.booking.dateKey != widget.booking.dateKey ||
        oldWidget.booking.status != widget.booking.status) {
      _startTimerIfNeeded();
    }
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (widget.booking.status == 'booked') {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _parseBookingDateTime(ConsultationBookingModel b) {
    try {
      int hour = 9;
      int minute = 0;
      if (b.timeSlot.isNotEmpty) {
        final cleaned = b.timeSlot.split('-').first.trim();
        final parts = cleaned.split(':');
        if (parts.isNotEmpty) {
          hour = int.tryParse(parts[0].replaceAll(RegExp(r'[^0-9]'), '')) ?? 9;
        }
        if (parts.length > 1) {
          minute = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        }
      }

      int year = DateTime.now().year;
      int month = 1;
      int day = 1;

      if (b.dateKey.contains('-')) {
        final dateParts = b.dateKey.split('-');
        if (dateParts.length >= 3) {
          final y = int.tryParse(dateParts[0]);
          final m = int.tryParse(dateParts[1]);
          final d = int.tryParse(dateParts[2]);
          if (y != null && m != null && d != null) {
            return DateTime(y, m, d, hour, minute);
          }
        }
      }

      if (b.date.isNotEmpty) {
        const bulanMap = {
          'januari': 1, 'februari': 2, 'maret': 3, 'april': 4,
          'mei': 5, 'juni': 6, 'juli': 7, 'agustus': 8,
          'september': 9, 'oktober': 10, 'november': 11, 'desember': 12,
        };
        final tokens = b.date.toLowerCase().replaceAll(',', '').split(RegExp(r'\s+'));
        int? foundDay;
        int? foundMonth;
        int? foundYear;
        for (int i = 0; i < tokens.length; i++) {
          final t = tokens[i];
          if (bulanMap.containsKey(t)) {
            foundMonth = bulanMap[t];
            if (i > 0 && foundDay == null) {
              foundDay = int.tryParse(tokens[i - 1]);
            }
            if (i + 1 < tokens.length && foundYear == null) {
              foundYear = int.tryParse(tokens[i + 1]);
            }
          }
        }
        if (foundDay != null && foundMonth != null) {
          foundYear ??= DateTime.now().year;
          return DateTime(foundYear, foundMonth, foundDay, hour, minute);
        }
      }

      if (b.createdAt != null) {
        return DateTime(b.createdAt!.year, b.createdAt!.month, b.createdAt!.day, hour, minute);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _openLiveChat({required bool forceActive, bool isTrial = false}) {
    if (isTrial) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.science_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🧪 Membuka chat dokter dalam Mode Uji Coba (sebelum jadwal tiba).',
                  style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFC2185B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveChatScreen(
          doctorName: widget.booking.doctorName,
          specialty: widget.booking.doctorSpecialty,
          doctorId: widget.booking.doctorId,
          forceActiveSession: forceActive,
        ),
      ),
    );
  }

  void _showLockedInfoDialog(BuildContext context, String countdownText) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF3E0),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFE65100), size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Jadwal Belum Tiba',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal konsultasi Anda bersama ${widget.booking.doctorName} dijadwalkan pada:\n'
              '📅 ${widget.booking.date.isNotEmpty ? widget.booking.date : widget.booking.dateKey}\n'
              '⏰ Jam ${widget.booking.timeSlot} WIB',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF333333), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sisa waktu: $countdownText',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFBF360C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Sebenarnya fitur chat akan otomatis terbuka saat waktu booking tiba. Namun, Anda dapat membuka chat sekarang menggunakan opsi Uji Coba.',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF777777)),
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
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _openLiveChat(forceActive: true, isTrial: true);
            },
            icon: const Icon(Icons.science_rounded, size: 16),
            label: Text(
              '🧪 Uji Coba Buka Chat',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: const Color(0xFFAAAAAA)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF555555),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;

    // Status badge
    final (statusLabel, statusBg, statusFg) = switch (b.status) {
      'completed' => ('Selesai', const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
      'cancelled' => ('Dibatalkan', const Color(0xFFFBE9E7), const Color(0xFFBF360C)),
      _ => ('Menunggu', const Color(0xFFFFF8E1), const Color(0xFFF57F17)),
    };

    final bool isBooked = b.status == 'booked';
    final scheduleStart = _parseBookingDateTime(b);
    final now = DateTime.now();

    bool isBeforeSchedule = false;
    bool isSessionActive = false;
    bool isSessionPast = false;
    String countdownText = '';

    if (scheduleStart != null && isBooked) {
      final sessionEnd = scheduleStart.add(const Duration(minutes: 60));
      if (now.isBefore(scheduleStart)) {
        isBeforeSchedule = true;
        final diff = scheduleStart.difference(now);
        final days = diff.inDays;
        final hours = diff.inHours % 24;
        final minutes = diff.inMinutes % 60;
        final seconds = diff.inSeconds % 60;

        if (days > 0) {
          countdownText = '$days hari ${hours.toString().padLeft(2, '0')}j ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}d';
        } else {
          countdownText = '${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}';
        }
      } else if (now.isBefore(sessionEnd)) {
        isSessionActive = true;
      } else {
        isSessionPast = true;
      }
    } else if (isBooked) {
      isSessionActive = true;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8BBD0), Color(0xFFF48FB1)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_rounded,
                    size: 18, color: Color(0xFF880E4F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.doctorName,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4A0012),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: statusFg,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.doctorSpecialty,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFFD81B60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _bookingInfoRow(
                    Icons.calendar_month_rounded, b.date.isNotEmpty ? b.date : b.dateKey),
                const SizedBox(height: 5),
                _bookingInfoRow(
                    Icons.access_time_rounded, 'Jam ${b.timeSlot}'),
                if (b.complaint.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  _bookingInfoRow(
                      Icons.notes_rounded, b.complaint, maxLines: 2),
                ],
                if (b.paymentMethod != null) ...[
                  const SizedBox(height: 5),
                  _bookingInfoRow(
                      Icons.payment_rounded,
                      '${b.paymentMethod} • Rp ${(b.totalAmount ?? 0).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'),
                ],

                // ── Kotak Info Waktu / Countdown Timer ──
                if (isBooked && isBeforeSchedule) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECB3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFE65100)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hitung Mundur Waktu Booking:',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                countdownText,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFBF360C),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isBooked && isSessionActive) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Waktu Konsultasi Telah Tiba!',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B5E20),
                                ),
                              ),
                              Text(
                                'Ruang chat dokter sudah dibuka dan dapat diakses.',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isBooked && isSessionPast) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18, color: Color(0xFF757575)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Jadwal sesi konsultasi telah lewat.',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF616161),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // ── Tombol Aksi ───────────────────────────────────
                if (isBooked) ...[
                  const SizedBox(height: 14),
                  if (isBeforeSchedule) ...[
                    // Tombol Terkunci (Belum Tiba Waktunya)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLockedInfoDialog(context, countdownText),
                        icon: const Icon(Icons.lock_rounded, size: 16),
                        label: Text(
                          'Chat Dokter (Terkunci)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tombol Uji Coba (Buka Chat Sebelum Waktu Tiba)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openLiveChat(forceActive: true, isTrial: true),
                        icon: const Icon(Icons.science_rounded, size: 16, color: Color(0xFFD81B60)),
                        label: Text(
                          '🧪 Uji Coba Buka Chat Sekarang',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFD81B60),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFF0F5),
                          side: const BorderSide(color: Color(0xFFF48FB1), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Waktu Konsultasi Tiba (Buka Chat Normal)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openLiveChat(forceActive: true),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                        label: Text(
                          'Chat Dokter',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD81B60),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ] else if (b.status == 'completed') ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openLiveChat(forceActive: false),
                      icon: const Icon(Icons.history_rounded, size: 16, color: Color(0xFF2E7D32)),
                      label: Text(
                        'Lihat Riwayat Chat',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8F5E9),
                        side: const BorderSide(color: Color(0xFFA5D6A7), width: 1),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}