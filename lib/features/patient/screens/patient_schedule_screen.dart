import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/consultation_booking_service.dart';
import '../../../models/app_user.dart';
import '../models/consultation_booking_model.dart';
import 'live_chat_screen.dart';
import 'consultation_list_screen.dart';

/// Layar Jadwal Saya Pasien (Real-time Status Booking & Kunci Chat Konsultasi)
/// Sesuai referensi gambar:
/// - Jika belum sesuai jadwal booking: tombol terkunci "Mulai konsultasi (menunggu jadwal)"
/// - Jika sudah tiba waktu jadwal booking: tombol otomatis aktif real-time & bisa buka chat konsultasi
class PatientScheduleScreen extends StatefulWidget {
  final String? bookingId;
  final AppUser? doctor;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String initials;
  final DateTime selectedDate;
  final String dateKey;
  final String dateText;
  final String timeSlot;
  final String complaint;
  final String transactionId;
  final int totalAmount;

  const PatientScheduleScreen({
    super.key,
    this.bookingId,
    this.doctor,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.initials,
    required this.selectedDate,
    required this.dateKey,
    required this.dateText,
    required this.timeSlot,
    required this.complaint,
    required this.transactionId,
    this.totalAmount = 52500,
  });

  @override
  State<PatientScheduleScreen> createState() => _PatientScheduleScreenState();
}

class _PatientScheduleScreenState extends State<PatientScheduleScreen> {
  static const Color _headerPink = Color(0xFFE5406C);
  static const Color _bgScreen = Color(0xFFFCEDF2);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _dividerColor = Color(0xFFF1E3E7);

  // Timer real-time untuk memperbarui status waktu setiap detik
  Timer? _realtimeTimer;
  DateTime _currentTime = DateTime.now();

  // Mode simulasi waktu (memudahkan pengujian saat demo apakah jadwal tiba atau belum)
  bool _simulateScheduleArrived = false;

  static const List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des'
  ];

  static const List<String> _dayNames = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    // Timer pengecekan setiap detik secara real-time
    _realtimeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  /// Format jadwal: "Kamis, 25 Sep, 09:00 WIB" persis seperti di gambar
  String _formatScheduleDisplay(DateTime d, String slot) {
    final dayStr = _dayNames[d.weekday - 1];
    final monthStr = _shortMonthNames[d.month - 1];
    return '$dayStr, ${d.day} $monthStr, $slot WIB';
  }

  /// Mengecek apakah waktu sekarang sudah masuk ke dalam sesi jadwal konsultasi
  bool _isScheduleActive() {
    if (_simulateScheduleArrived) return true;

    try {
      final parts = widget.timeSlot.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(
            parts.length > 1
                ? parts[1].replaceAll(RegExp(r'[^0-9]'), '')
                : '0',
          ) ??
          0;

      final scheduleStart = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        hour,
        minute,
      );

      // Durasi sesi konsultasi adalah 25 menit (ditambah toleransi 30 menit)
      final sessionEnd = scheduleStart.add(const Duration(minutes: 55));

      // Jika tanggal sama dan jam sudah tiba / lewat sedikit
      final isSameDate = _currentTime.year == scheduleStart.year &&
          _currentTime.month == scheduleStart.month &&
          _currentTime.day == scheduleStart.day;

      if (isSameDate) {
        return (_currentTime.isAfter(scheduleStart) ||
                _currentTime.isAtSameMomentAs(scheduleStart)) &&
            _currentTime.isBefore(sessionEnd);
      } else if (_currentTime.isAfter(scheduleStart) &&
          _currentTime.isBefore(sessionEnd)) {
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  /// Waktu hitung mundur menuju jadwal konsultasi
  String _getRemainingCountdown() {
    try {
      final parts = widget.timeSlot.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(
            parts.length > 1
                ? parts[1].replaceAll(RegExp(r'[^0-9]'), '')
                : '0',
          ) ??
          0;

      final scheduleStart = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        hour,
        minute,
      );

      final diff = scheduleStart.difference(_currentTime);
      if (diff.isNegative) return 'Sesi sedang berlangsung';

      if (diff.inDays > 0) {
        return '${diff.inDays} hari lagi';
      } else if (diff.inHours > 0) {
        return '${diff.inHours} jam ${diff.inMinutes % 60} menit lagi';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes} menit ${diff.inSeconds % 60} detik lagi';
      } else {
        return '${diff.inSeconds} detik lagi';
      }
    } catch (_) {
      return 'Menunggu jadwal';
    }
  }

  /// Mendapatkan durasi sisa waktu hingga jadwal tiba
  Duration _getRemainingDuration() {
    try {
      final parts = widget.timeSlot.split(':');
      final hour = int.tryParse(parts[0]) ?? 9;
      final minute = int.tryParse(
            parts.length > 1
                ? parts[1].replaceAll(RegExp(r'[^0-9]'), '')
                : '0',
          ) ??
          0;

      final scheduleStart = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        hour,
        minute,
      );

      final diff = scheduleStart.difference(_currentTime);
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return Duration.zero;
    }
  }

  void _handleOpenConsultation() {
    final active = _isScheduleActive();

    if (!active) {
      // Konsultasi belum tiba, beri info real-time & opsi simulasi uji coba
      final scheduleText = _formatScheduleDisplay(widget.selectedDate, widget.timeSlot);
      final countdown = _getRemainingCountdown();

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
                    'Jadwal Belum Tiba',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Sesi konsultasi Anda: $scheduleText ($countdown). Tombol akan otomatis aktif saat jam booking tiba.',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Uji Buka',
            textColor: const Color(0xFFFFD54F),
            onPressed: () {
              setState(() {
                _simulateScheduleArrived = true;
              });
            },
          ),
          backgroundColor: const Color(0xFF2C2C2C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Jika sudah masuk jadwal, buka ruang chat konsultasi real-time dengan sesi aktif 25 menit!
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveChatScreen(
          doctorName: widget.doctorName,
          specialty: widget.specialty,
          initials: widget.initials,
          doctorId: widget.doctorId,
          forceActiveSession: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduleDisplay = _formatScheduleDisplay(widget.selectedDate, widget.timeSlot);
    final isUnlocked = _isScheduleActive();

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: AppBar(
          backgroundColor: _headerPink,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: _headerPink,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  // Back button lingkaran putih transparan
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const ConsultationListScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0x33FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Jadwal saya',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  // Tombol bantuan simulasi pengujian (toggle)
                  if (!_simulateScheduleArrived)
                    IconButton(
                      tooltip: 'Simulasi Jam Tiba',
                      icon: const Icon(
                        Icons.more_time_rounded,
                        color: Colors.white70,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _simulateScheduleArrived = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Mode simulasi: Jam booking tiba diaktifkan.',
                              style: GoogleFonts.poppins(fontSize: 12.5),
                            ),
                            backgroundColor: const Color(0xFF00B074),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                  else
                    IconButton(
                      tooltip: 'Reset Simulasi',
                      icon: const Icon(
                        Icons.lock_reset_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          _simulateScheduleArrived = false;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),

              // ─── Kartu Utama Jadwal Saya ──────────────────────────────────
              StreamBuilder<ConsultationBookingModel?>(
                stream: widget.bookingId != null
                    ? ConsultationBookingService.instance
                        .streamBookingById(widget.bookingId!)
                    : null,
                builder: (context, snapshot) {
                  final liveBooking = snapshot.data;
                  final doctorStatusText = liveBooking != null &&
                          liveBooking.status == 'in_progress'
                      ? 'Dokter siap'
                      : (isUnlocked ? 'Sesi aktif' : 'Menunggu dokter');

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris 1: Info Dokter + Badge "Menunggu dokter"
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar Dokter Bulat Pink
                            Container(
                              width: 50,
                              height: 50,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCE7EE),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  widget.initials,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFB82855),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.doctorName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.specialty,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _textGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Badge Status Dokter (Kuning Amber)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isUnlocked
                                    ? const Color(0xFFD4F7E7)
                                    : const Color(0xFFFFF3D6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isUnlocked
                                        ? Icons.check_circle_rounded
                                        : Icons.access_time_rounded,
                                    size: 13,
                                    color: isUnlocked
                                        ? const Color(0xFF00875A)
                                        : const Color(0xFFB5701B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    doctorStatusText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isUnlocked
                                        ? const Color(0xFF00875A)
                                        : const Color(0xFFB5701B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                            color: _dividerColor,
                            height: 1,
                            thickness: 1,
                          ),
                        ),

                        // Baris 2: Jadwal "Kamis, 25 Sep, 09:00 WIB"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Jadwal',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _textGrey,
                              ),
                            ),
                            Text(
                              scheduleDisplay,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(
                            color: _dividerColor,
                            height: 1,
                            thickness: 1,
                          ),
                        ),

                        // Baris 3: Pembayaran "✓ Lunas"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pembayaran',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _textGrey,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4F7E7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Color(0xFF00875A),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Lunas',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF00875A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Section Hitung Mundur Real-time menuju jadwal booking
                        _buildCountdownWidget(isUnlocked),

                        const SizedBox(height: 18),

                        // Baris 4: Tombol Mulai Konsultasi (Terkunci vs Aktif Real-time)
                        _buildConsultationActionButton(isUnlocked),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // ─── Teks Keterangan di Bawah Kartu ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Pembayaran sudah selesai. Tombol mulai konsultasi akan aktif otomatis saat jam booking tiba.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                    height: 1.45,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol Konsultasi:
  /// - Terkunci: latar abu-abu/pink lembut dengan gembok & teks "Mulai konsultasi (menunggu jadwal)"
  /// - Aktif: warna pink dengan ikon chat & teks "Mulai Konsultasi"
  Widget _buildConsultationActionButton(bool isUnlocked) {
    if (!isUnlocked) {
      return InkWell(
        onTap: _handleOpenConsultation,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1E7EA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFFA69399),
                ),
                const SizedBox(width: 8),
                Text(
                  'Mulai konsultasi (menunggu jadwal)',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA69399),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ketika jadwal booking tiba: tombol berubah jadi pink aktif!
    return InkWell(
      onTap: _handleOpenConsultation,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: _headerPink,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33E5406C),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                'Mulai Konsultasi',
                style: GoogleFonts.poppins(
                  fontSize: 14,
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

  /// Widget Hitung Mundur Real-time yang Berjalan Menuju Waktu Booking
  Widget _buildCountdownWidget(bool isUnlocked) {
    if (isUnlocked) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFA5D6A7), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF00875A),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Konsultasi Telah Tiba!',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B5E20),
                    ),
                  ),
                  Text(
                    'Ruang chat konsultasi dokter telah terbuka & siap digunakan.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final remaining = _getRemainingDuration();
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_outlined, size: 16, color: Color(0xFFD81B60)),
              const SizedBox(width: 6),
              Text(
                'Hitung Mundur Waktu Konsultasi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF880E4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeBox(hours.toString().padLeft(2, '0'), 'JAM'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE5406C),
                  ),
                ),
              ),
              _buildTimeBox(minutes.toString().padLeft(2, '0'), 'MENIT'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  ':',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFE5406C),
                  ),
                ),
              ),
              _buildTimeBox(seconds.toString().padLeft(2, '0'), 'DETIK'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Tombol aktif otomatis saat jam booking tiba',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: const Color(0xFF880E4F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _simulateScheduleArrived = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Jadwal konsultasi dibuka! Silakan klik Mulai Konsultasi.',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: const Color(0xFF00875A),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5406C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.flash_on_rounded, size: 12, color: Colors.white),
                      const SizedBox(width: 2),
                      Text(
                        'Uji Buka',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF8BBD0), width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFD81B60),
              ),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFA69399),
          ),
        ),
      ],
    );
  }
}
