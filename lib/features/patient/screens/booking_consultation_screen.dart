import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/consultation_booking_service.dart';
import '../../../models/app_user.dart';
import '../models/consultation_booking_model.dart';
import 'booking_summary_screen.dart';

/// Layar Booking Konsultasi Jadwal Dokter
/// Menampilkan kalender, pilihan jam konsultasi real-time, dan input keluhan
class BookingConsultationScreen extends StatefulWidget {
  final AppUser? doctor;
  final String? doctorId;
  final String doctorName;
  final String specialty;
  final String initials;
  final String schedule;

  const BookingConsultationScreen({
    super.key,
    this.doctor,
    this.doctorId,
    this.doctorName = 'dr. Yosua',
    this.specialty = 'Sp.A',
    this.initials = 'DY',
    this.schedule = 'Senin – Jumat (09:00 – 17:00)',
  });

  @override
  State<BookingConsultationScreen> createState() =>
      _BookingConsultationScreenState();
}

class _BookingConsultationScreenState extends State<BookingConsultationScreen> {
  // Palet warna sesuai gambar referensi
  static const Color _headerPink = Color(0xFFE5406C);
  static const Color _bgScreen = Color(0xFFFCEDF2);
  static const Color _selectedSlotPink = Color(0xFFE52865);
  static const Color _borderPink = Color(0xFFF5B5C8);
  static const Color _bookedBg = Color(0xFFF7F7F8);
  static const Color _bookedBorder = Color(0xFFE8E8E8);
  static const Color _bookedText = Color(0xFFA6A6A6);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF757575);

  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  String? _selectedSlot;
  final TextEditingController _complaintController = TextEditingController();
  bool _isSubmitting = false;
  String? _liveSchedule;
  StreamSubscription? _doctorScheduleSub;

  // Daftar default slot jam konsultasi (durasi 25 menit, jeda 5 menit, istirahat 12:00-13:00)
  static const List<String> _allSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
  ];

  @override
  void initState() {
    super.initState();
    // Inisialisasi kalender real-time sesuai tanggal saat ini (misal 22 Oktober 2026)
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);

    _selectedSlot = _findInitialValidSlot();

    _seedInitialDataIfAvailable();
    _listenToDoctorSchedule();
  }

  void _listenToDoctorSchedule() {
    try {
      final docId = _effectiveDoctorId;
      if (docId.isNotEmpty) {
        _doctorScheduleSub = FirebaseFirestore.instance
            .collection('doctors')
            .doc(docId)
            .snapshots()
            .listen((snap) {
          if (snap.exists && snap.data() != null) {
            final s = snap.data()!['schedule'] as String?;
            if (s != null && s.isNotEmpty && mounted) {
              setState(() {
                _liveSchedule = s;
                if (_selectedSlot != null &&
                    !_computedSlots.contains(_selectedSlot)) {
                  _selectedSlot = _findInitialValidSlot();
                }
              });
            }
          }
        });
      }
    } catch (e) {
      debugPrint('ℹ️ [BookingConsultation] listen doctor schedule: $e');
    }
  }

  @override
  void dispose() {
    _doctorScheduleSub?.cancel();
    _complaintController.dispose();
    super.dispose();
  }

  /// Cek apakah dokter membuka jadwal praktik pada hari yang dipilih pada kalender
  bool get _isDoctorPracticingOnSelectedDate {
    final sch = _effectiveSchedule.toLowerCase();
    final weekday = _selectedDate.weekday; // 1 = Senin, ..., 7 = Minggu
    if (sch.contains('setiap hari')) {
      return true;
    }
    if (sch.contains('senin - kamis') || sch.contains('senin – kamis')) {
      return weekday >= DateTime.monday && weekday <= DateTime.thursday;
    }
    if (sch.contains('senin - sabtu') || sch.contains('senin – sabtu')) {
      return weekday >= DateTime.monday && weekday <= DateTime.saturday;
    }
    if (sch.contains('senin - jumat') || sch.contains('senin – jumat')) {
      return weekday >= DateTime.monday && weekday <= DateTime.friday;
    }
    return true;
  }

  /// Menghitung slot jam dinamis berdasarkan jadwal praktik dokter saat ini
  List<String> get _computedSlots {
    try {
      final reg = RegExp(r'(\d{1,2}:\d{2})\s*[-–]\s*(\d{1,2}:\d{2})');
      final match = reg.firstMatch(_effectiveSchedule);
      if (match != null) {
        final startParts = match.group(1)!.split(':');
        final endParts = match.group(2)!.split(':');
        int startMinutes =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        if (endMinutes > startMinutes) {
          final List<String> generated = [];
          for (int m = startMinutes; m + 30 <= endMinutes; m += 30) {
            final h = m ~/ 60;
            final min = m % 60;
            // Lewati istirahat 12:00 - 13:00 jika jadwal mencakup pagi s/d sore
            if (startMinutes <= 11 * 60 && endMinutes >= 14 * 60 && (h == 12)) {
              continue;
            }
            final slotStr =
                '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
            generated.add(slotStr);
          }
          if (generated.isNotEmpty) {
            return generated;
          }
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [BookingConsultation] parse schedule slots error: $e');
    }
    return _allSlots;
  }

  /// Cek apakah slot jam tertentu sudah lewat waktu saat ini (jika hari ini dipilih)
  bool _isSlotPast(String slot) {
    if (!_isToday(_selectedDate)) {
      return false; // Jika hari esok / lusa, semua sesi jam belum lewat
    }
    try {
      final parts = slot.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final now = DateTime.now();
      final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
      return now.isAfter(slotTime);
    } catch (_) {
      return false;
    }
  }

  /// Cari slot jam pertama yang masih belum lewat waktu
  String? _findInitialValidSlot() {
    if (!_isDoctorPracticingOnSelectedDate) return null;
    for (final slot in _computedSlots) {
      if (!_isSlotPast(slot)) {
        return slot;
      }
    }
    return null;
  }

  String get _effectiveDoctorId {
    if (widget.doctor != null && widget.doctor!.uid.isNotEmpty) {
      return widget.doctor!.uid;
    }
    if (widget.doctorId != null && widget.doctorId!.isNotEmpty) {
      return widget.doctorId!;
    }
    return 'doctor_yosua';
  }

  String get _effectiveDoctorName {
    if (widget.doctor != null && widget.doctor!.fullName.isNotEmpty) {
      return widget.doctor!.fullName;
    }
    return widget.doctorName;
  }

  String get _effectiveSpecialty {
    if (widget.doctor != null &&
        widget.doctor!.specialization != null &&
        widget.doctor!.specialization!.isNotEmpty) {
      return widget.doctor!.specialization!;
    }
    return widget.specialty;
  }

  String get _effectiveInitials {
    if (widget.doctor != null) {
      final name = widget.doctor!.fullName.isNotEmpty
          ? widget.doctor!.fullName
          : widget.doctor!.username;
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.isEmpty) return 'DR';
      if (parts.length == 1) {
        return parts[0].substring(0, parts[0].length.clamp(0, 2)).toUpperCase();
      }
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return widget.initials;
  }

  String get _effectiveSchedule {
    if (_liveSchedule != null && _liveSchedule!.isNotEmpty) {
      return _liveSchedule!;
    }
    if (widget.doctor != null &&
        widget.doctor!.schedule != null &&
        widget.doctor!.schedule!.isNotEmpty) {
      return widget.doctor!.schedule!;
    }
    return widget.schedule;
  }

  String _formatDateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Seed data booking awal (slot 10:30 & 14:00 terisi) untuk tanggal aktif jika kosong
  Future<void> _seedInitialDataIfAvailable() async {
    final dateKey = _formatDateKey(_selectedDate);
    final dateText = _formatFullIndonesianDate(_selectedDate);
    await ConsultationBookingService.instance.seedInitialBookingsIfEmpty(
      doctorId: _effectiveDoctorId,
      doctorName: _effectiveDoctorName,
      doctorSpecialty: _effectiveSpecialty,
      dateKey: dateKey,
      dateText: dateText,
    );
  }

  // ─── Format Tanggal Bahasa Indonesia ───────────────────────────────────

  static const List<String> _monthNames = [
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
    'Desember'
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

  String _monthName(int month) => _monthNames[month - 1];

  String _dayName(int weekday) => _dayNames[weekday - 1];

  String _formatFullIndonesianDate(DateTime d) {
    return '${_dayName(d.weekday)}, ${d.day} ${_monthName(d.month)} ${d.year}';
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return now.year == d.year && now.month == d.month && now.day == d.day;
  }

  String _formatDateHeaderLabel(DateTime d) {
    final dayStr = _dayName(d.weekday);
    final monthStr = _monthName(d.month);
    if (_isToday(d)) {
      return 'Hari ini, $dayStr, ${d.day} $monthStr';
    }
    return '$dayStr, ${d.day} $monthStr';
  }

  /// Menentukan apakah tanggal dapat dipilih (tanggal yang sudah terlewati tidak bisa dipilih)
  bool _isDateSelectable(DateTime d) {
    final now = DateTime.now();
    final cleanToday = DateTime(now.year, now.month, now.day);
    final cleanDate = DateTime(d.year, d.month, d.day);
    return !cleanDate.isBefore(cleanToday);
  }

  bool get _canGoPreviousMonth {
    final now = DateTime.now();
    final currentMonthStart = DateTime(now.year, now.month, 1);
    return _displayedMonth.isAfter(currentMonthStart);
  }

  void _previousMonth() {
    if (!_canGoPreviousMonth) return;
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month - 1,
        1,
      );
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + 1,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _formatDateKey(_selectedDate);

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
                  // Back Button rounded circle
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
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
                    'Booking konsultasi',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kartu Info Dokter
              _buildDoctorCard(),

              const SizedBox(height: 12),

              // 2. Info Jadwal & Durasi Sesi
              _buildScheduleText(),

              const SizedBox(height: 16),

              // 3. Bagian "Pilih tanggal"
              Text(
                'Pilih tanggal',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),

              // Kalender Kartu Putih
              _buildCalendarCard(),

              const SizedBox(height: 20),

              // 4. Bagian "Pilih jam" dengan Real-Time Firestore Stream
              StreamBuilder<List<ConsultationBookingModel>>(
                stream: ConsultationBookingService.instance.streamBookings(
                  doctorId: _effectiveDoctorId,
                  dateKey: dateKey,
                ),
                builder: (context, snapshot) {
                  final bookings = snapshot.data ?? [];
                  final bookedSlots =
                      bookings.map((b) => b.timeSlot.trim()).toSet();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row "Pilih jam" + "Hari ini, Kamis, 24 September"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pilih jam',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          Text(
                            _formatDateHeaderLabel(_selectedDate),
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _textGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Grid 4 Kolom Pilihan Jam
                      _buildTimeSlotsGrid(bookedSlots),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // 5. Bagian "Keluhan singkat"
              Text(
                'Keluhan singkat',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              _buildComplaintInput(),

              const SizedBox(height: 24),

              // 6. Tombol "→ Lanjutkan"
              _buildContinueButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. Kartu Info Dokter ─────────────────────────────────────────────

  Widget _buildDoctorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lingkaran Avatar Inisial Soft Pink
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFCE7EE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _effectiveInitials,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB82855),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _effectiveDoctorName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _effectiveSpecialty,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Teks Info Jadwal Dokter ───────────────────────────────────────

  Widget _buildScheduleText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Jadwal: $_effectiveSchedule • Durasi sesi 25 menit',
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF2E2E2E),
          height: 1.4,
        ),
      ),
    );
  }

  // ─── 3. Kartu Kalender ───────────────────────────────────────────────

  Widget _buildCalendarCard() {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    // Header hari Minggu s/d Sabtu (Min, Sen, Sel, Rab, Kam, Jum, Sab)
    // Dart: Monday=1, ..., Sunday=7. Sunday % 7 = 0
    final firstWeekdayOffset = DateTime(year, month, 1).weekday % 7;

    final weekTitles = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bulan & Navigasi < >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: _canGoPreviousMonth ? _previousMonth : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _canGoPreviousMonth ? const Color(0xFFFDECEF) : const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: _canGoPreviousMonth ? _headerPink : const Color(0xFFC7C7C7),
                    ),
                  ),
                ),
              ),
              Text(
                '${_monthName(month)} $year',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              InkWell(
                onTap: _nextMonth,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: _headerPink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Header Hari (Min, Sen, Sel, Rab, Kam, Jum, Sab)
          Row(
            children: weekTitles.map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _textGrey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Grid Tanggal (7 Kolom, mendukung 5 atau 6 baris agar tanggal tidak terpotong)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ((firstWeekdayOffset + daysInMonth) > 35) ? 42 : 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekdayOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(year, month, dayNumber);
              final isSelected = _selectedDate.year == cellDate.year &&
                  _selectedDate.month == cellDate.month &&
                  _selectedDate.day == cellDate.day;

              final isSelectable = _isDateSelectable(cellDate);

              return InkWell(
                onTap: isSelectable
                    ? () {
                        setState(() {
                          _selectedDate = cellDate;
                          // Sesuaikan slot terpilih jika di tanggal baru slot tersebut sudah lewat
                          if (_selectedSlot == null || _isSlotPast(_selectedSlot!)) {
                            _selectedSlot = _findInitialValidSlot();
                          }
                        });
                        _seedInitialDataIfAvailable();
                      }
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? _selectedSlotPink : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight:
                          isSelected || isSelectable ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isSelectable ? _textDark : const Color(0xFFC7C7C7)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotsGrid(Set<String> bookedSlots) {
    // Jika dokter tidak buka pada hari yang dipilih, tampilkan banner
    if (!_isDoctorPracticingOnSelectedDate) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFB74D), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_busy_rounded, color: Color(0xFFE65100), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Dokter tidak membuka praktik pada hari ini.\nJadwal: $_effectiveSchedule',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8D4B00),
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final slots = _computedSlots;
    // Hitung apakah semua slot jam hari ini sudah terlewati
    final allSlotsPast = _isToday(_selectedDate) && slots.every((s) => _isSlotPast(s));

    return LayoutBuilder(
      builder: (context, constraints) {
        // Grid 4 Kolom
        const crossAxisCount = 4;
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: slots.map((slot) {
                final isBooked = bookedSlots.contains(slot);
                final isPast = _isSlotPast(slot);
                final isSelected = !isBooked && !isPast && (_selectedSlot == slot);

                return SizedBox(
                  width: itemWidth,
                  height: 38,
                  child: _buildTimeSlotPill(
                    slot: slot,
                    isBooked: isBooked,
                    isPast: isPast,
                    isSelected: isSelected,
                  ),
                );
              }).toList(),
            ),
            if (allSlotsPast) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: Color(0xFFE65100), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Semua sesi hari ini telah selesai. Silakan pilih tanggal berikutnya pada kalender di atas.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF8D4B00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTimeSlotPill({
    required String slot,
    required bool isBooked,
    required bool isPast,
    required bool isSelected,
  }) {
    Color bg;
    Border? border;
    Color textColor;
    TextDecoration? textDecoration;
    FontWeight fontWeight;

    if (isBooked) {
      // Slot sudah dibooking orang lain:
      bg = _bookedBg;
      border = Border.all(color: _bookedBorder, width: 1.2);
      textColor = _bookedText;
      textDecoration = TextDecoration.lineThrough;
      fontWeight = FontWeight.w600;
    } else if (isPast) {
      // Slot waktu sudah lewat dari jam saat ini (real-time):
      bg = const Color(0xFFF3F3F3);
      border = Border.all(color: const Color(0xFFE0E0E0), width: 1.0);
      textColor = const Color(0xFFAAAAAA);
      textDecoration = null;
      fontWeight = FontWeight.w500;
    } else if (isSelected) {
      // Slot terpilih oleh pengguna: solid pink
      bg = _selectedSlotPink;
      border = null;
      textColor = Colors.white;
      textDecoration = null;
      fontWeight = FontWeight.w700;
    } else {
      // Slot tersedia: latar putih, border pink lembut, teks gelap
      bg = Colors.white;
      border = Border.all(color: _borderPink, width: 1.2);
      textColor = _textDark;
      textDecoration = null;
      fontWeight = FontWeight.w600;
    }

    return InkWell(
      onTap: isBooked
          ? () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jam $slot sudah dibooking oleh pasien lain.',
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF555555),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          : isPast
              ? () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Jam $slot sudah terlewati hari ini. Silakan pilih jam berikutnya atau tanggal lain.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF555555),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : () {
                  setState(() {
                    _selectedSlot = slot;
                  });
                },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          border: border,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          slot,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: fontWeight,
            color: textColor,
            decoration: textDecoration,
            decorationColor: _bookedText,
            decorationThickness: 1.8,
          ),
        ),
      ),
    );
  }

  // ─── 5. Input Keluhan Singkat ─────────────────────────────────────────

  Widget _buildComplaintInput() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderPink, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: TextField(
        controller: _complaintController,
        minLines: 3,
        maxLines: 5,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: _textDark,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Contoh: gula darah naik beberapa hari terakhir',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF9E9E9E),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ─── 6. Tombol Lanjutkan ──────────────────────────────────────────────

  Widget _buildContinueButton() {
    return InkWell(
      onTap: _isSubmitting ? null : _handleContinueBooking,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFCECECE),
            width: 1.2,
          ),
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _headerPink,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Color(0xFF1F1F1F),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selanjutnya',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ─── Logika Proses Booking ────────────────────────────────────────────

  Future<void> _handleContinueBooking() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan pilih jam konsultasi yang masih tersedia.',
            style: GoogleFonts.poppins(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isSlotPast(_selectedSlot!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jam $_selectedSlot sudah terlewati hari ini. Silakan pilih jam berikutnya atau tanggal lain.',
            style: GoogleFonts.poppins(fontSize: 12.5),
          ),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final isBooked = await ConsultationBookingService.instance.isSlotBooked(
        doctorId: _effectiveDoctorId,
        dateKey: _formatDateKey(_selectedDate),
        timeSlot: _selectedSlot!,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (isBooked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Slot jam $_selectedSlot sudah dibooking oleh pasien lain. Silakan pilih jam lain.',
              style: GoogleFonts.poppins(fontSize: 12.5),
            ),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final dateKey = _formatDateKey(_selectedDate);
      final dateText = _formatFullIndonesianDate(_selectedDate);
      final complaint = _complaintController.text.trim();

      // Navigasi ke Ringkasan Booking & Pembayaran (Tampilan 1)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSummaryScreen(
            doctor: widget.doctor,
            doctorId: _effectiveDoctorId,
            doctorName: _effectiveDoctorName,
            specialty: _effectiveSpecialty,
            initials: _effectiveInitials,
            selectedDate: _selectedDate,
            dateKey: dateKey,
            dateText: dateText,
            timeSlot: _selectedSlot!,
            complaint: complaint,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final dateKey = _formatDateKey(_selectedDate);
      final dateText = _formatFullIndonesianDate(_selectedDate);
      final complaint = _complaintController.text.trim();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingSummaryScreen(
            doctor: widget.doctor,
            doctorId: _effectiveDoctorId,
            doctorName: _effectiveDoctorName,
            specialty: _effectiveSpecialty,
            initials: _effectiveInitials,
            selectedDate: _selectedDate,
            dateKey: dateKey,
            dateText: dateText,
            timeSlot: _selectedSlot!,
            complaint: complaint,
          ),
        ),
      );
    }
  }
}
