import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/app_user.dart';
import '../../../core/services/patient_chat_notification_service.dart';
import '../../../core/services/consultation_booking_service.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';
import '../models/consultation_booking_model.dart';
import 'live_chat_screen.dart';
import 'booking_consultation_screen.dart';

class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  /// Daftar booking aktif pasien saat ini (real-time dari Firestore)
  List<ConsultationBookingModel> _activeBookings = [];
  StreamSubscription? _bookingsSub;

  // Warna sesuai tema Soft Pink
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _bgScreen = Color(0xFFF7EEEC);
  static const Color _avatarBg = Color(0xFFFCEAEA);
  static const Color _avatarText = Color(0xFF9E4044);
  static const Color _innerBoxBg = Color(0xFFFAF1F0);
  static const Color _greenOnlineBg = Color(0xFFD4F7E7);
  static const Color _greenText = Color(0xFF00B074);
  static const Color _navIconActive = Color(0xFFE56A6F);
  static const Color _navIconInactive = Color(0xFFEFB3B5);

  // Timer real-time untuk update status jam booking
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _listenPatientBookings();
    // Timer setiap detik untuk update status waktu booking
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _clockTimer?.cancel();
    super.dispose();
  }

  /// Subscribe ke stream booking pasien secara real-time
  void _listenPatientBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    _bookingsSub = ConsultationBookingService.instance
        .streamPatientBookings(uid)
        .listen((bookings) {
      if (mounted) {
        setState(() {
          _activeBookings = bookings;
        });
      }
    });
  }

  /// Mendapatkan booking aktif untuk dokter tertentu (status = 'booked')
  ConsultationBookingModel? _getActiveBookingForDoctor(String doctorId) {
    try {
      return _activeBookings.firstWhere((b) => b.doctorId == doctorId);
    } catch (_) {
      return null;
    }
  }

  /// Cek apakah waktu booking sudah tiba
  bool _isBookingTimeArrived(ConsultationBookingModel booking) {
    try {
      final parts = booking.timeSlot.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(
            parts.length > 1 ? parts[1].replaceAll(RegExp(r'[^0-9]'), '') : '0',
          ) ?? 0;

      // Parse dateKey (YYYY-MM-DD)
      final dateParts = booking.dateKey.split('-');
      final year = int.tryParse(dateParts[0]) ?? DateTime.now().year;
      final month = int.tryParse(dateParts[1]) ?? 1;
      final day = int.tryParse(dateParts[2]) ?? 1;

      final scheduleStart = DateTime(year, month, day, hour, minute);
      final sessionEnd = scheduleStart.add(const Duration(minutes: 55));
      final now = DateTime.now();

      return (now.isAfter(scheduleStart) || now.isAtSameMomentAs(scheduleStart)) &&
          now.isBefore(sessionEnd);
    } catch (_) {
      return false;
    }
  }

  /// Membuat 2 huruf inisial dari nama lengkap
  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'DR';
    if (parts.length == 1) return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: _primaryPink,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: _primaryPink,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 19, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Konsultasi',
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('doctors')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _primaryPink));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat daftar dokter',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          List<AppUser> doctorList = [];
          if (docs.isNotEmpty) {
            doctorList = docs
                .map((d) => AppUser.fromMap(
                      d.data() as Map<String, dynamic>,
                      d.id,
                    ))
                .toList();
          } else {
            // Default dokter terdaftar jika Firestore belum diisi dokter manual
            doctorList = const [
              AppUser(
                uid: 'doctor_yosua',
                fullName: 'dr. Yosua',
                username: 'yosua',
                email: 'yosua@dcare.id',
                phoneNumber: '081234567891',
                dob: '1988-09-12',
                role: AppRole.doctor,
                specialization: 'Sp.A',
                isActive: true,
                schedule: 'Senin – Jumat (09:00 – 17:00)',
              ),
              AppUser(
                uid: 'doctor_kaka',
                fullName: 'Dr. Kaka Pratama',
                username: 'kakapratama',
                email: 'kaka@dcare.id',
                phoneNumber: '081234567892',
                dob: '1985-04-20',
                role: AppRole.doctor,
                specialization: 'Spesialis Penyakit Dalam',
                isActive: true,
                schedule: 'Senin – Jumat (08:30 – 16:30)',
              ),
            ];
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: doctorList.length,
            itemBuilder: (context, index) {
              final doctor = doctorList[index];
              return _buildDoctorCard(context, doctor);
            },
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildDoctorCard(BuildContext context, AppUser doctor) {
    final isOnline = doctor.isActive;
    final specialty = (doctor.specialization != null && doctor.specialization!.isNotEmpty)
        ? doctor.specialization!
        : 'Spesialis Penyakit Dalam';
    final initials = _initials(doctor.fullName.isNotEmpty ? doctor.fullName : doctor.username);
    final displayName = doctor.fullName.isNotEmpty ? doctor.fullName : doctor.username;

    // Cek apakah ada booking aktif untuk dokter ini
    final activeBooking = _getActiveBookingForDoctor(doctor.uid);
    final hasBooking = activeBooking != null;
    final isChatUnlocked = hasBooking && _isBookingTimeArrived(activeBooking);

    return ValueListenableBuilder<Map<String, int>>(
      valueListenable:
          PatientChatNotificationService.instance.unreadDoctorMapNotifier,
      builder: (context, unreadMap, _) {
        final unread = (unreadMap[doctor.uid] ?? 0) +
            (unreadMap[displayName.toLowerCase().trim()] ?? 0);
        final hasUnread = unread > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: hasUnread
                ? Border.all(
                    color: const Color(0xFFE53935),
                    width: 1.5,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil Dokter
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DoctorAvatarWidget(
                        photoUrl: doctor.photoUrl,
                        size: 58,
                        initials: initials,
                        backgroundColor: _avatarBg,
                        iconColor: _avatarText,
                      ),
                      if (hasUnread)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF262626),
                                ),
                              ),
                            ),
                            if (hasUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Pesan Baru',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          specialty,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF8E8E8E),
                          ),
                        ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 17, color: _greenText),
                        const SizedBox(width: 4),
                        Text(
                          '5.0',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF262626),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(Dokter Terdaftar)',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status Ketersediaan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _innerBoxBg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'Tersedia hari ini' : 'Sedang tidak aktif',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF989898),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isOnline ? 'Siap Konsultasi' : '-',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF262626),
                      ),
                    ),
                  ],
                ),
                if (isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _greenOnlineBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _greenText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Aktif',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _greenText,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Nonaktif',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFC4C4C4),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Jadwal Konsultasi Dokter (Real-time dari Firestore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF3D2DF),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBF2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    size: 15,
                    color: Color(0xFFD6336C),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Konsultasi',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF888888),
                        ),
                      ),
                      Text(
                        doctor.schedule?.isNotEmpty == true
                            ? doctor.schedule!
                            : 'Senin - Jumat (09:00 - 17:00)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2E2E),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Aksi: Booking Konsultasi & Chat
          Row(
            children: [
              // Tombol Utama: Booking Konsultasi
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingConsultationScreen(
                          doctor: doctor,
                          doctorId: doctor.uid,
                          doctorName: displayName,
                          specialty: specialty,
                          initials: initials,
                          schedule: doctor.schedule?.isNotEmpty == true
                              ? doctor.schedule!
                              : 'Senin – Jumat (09:00 – 17:00)',
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: Color(0xFF333333),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Booking konsultasi',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Tombol Chat — Terkunci jika belum booking / belum tiba waktunya
              InkWell(
                onTap: () {
                  if (!hasBooking) {
                    // Belum ada booking: tampilkan info bahwa harus booking dulu
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Silakan booking konsultasi terlebih dahulu untuk menggunakan fitur chat.',
                                style: GoogleFonts.poppins(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2C2C2C),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } else if (!isChatUnlocked) {
                    // Sudah booking tapi belum tiba waktunya: beri info jadwal
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Chat Belum Tersedia',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fitur chat akan otomatis terbuka saat jam booking Anda tiba (${activeBooking.timeSlot} WIB, ${activeBooking.date}).',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF2C2C2C),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  } else {
                    // Booking ada & waktu sudah tiba: buka chat!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveChatScreen(
                          doctorName: displayName,
                          specialty: specialty,
                          initials: initials,
                          doctorId: doctor.uid,
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isChatUnlocked ? _avatarBg : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChatUnlocked ? const Color(0xFFF3D2DF) : const Color(0xFFE0E0E0),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isChatUnlocked
                          ? Icons.chat_bubble_outline_rounded
                          : Icons.lock_outline_rounded,
                      size: 20,
                      color: isChatUnlocked ? _avatarText : const Color(0xFFBBBBBB),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  },
);
}

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 64,
      color: _bgScreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 28),
            color: _navIconInactive,
            tooltip: 'Beranda',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
            color: _navIconActive,
            tooltip: 'Konsultasi',
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, size: 28),
            color: _navIconInactive,
            tooltip: 'Profil Pasien',
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
