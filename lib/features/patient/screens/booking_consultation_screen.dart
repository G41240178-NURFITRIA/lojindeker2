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
    // Default ke September 2026 tanggal 24 agar langsung identik dengan gambar jika dibuka
    // Pengguna juga bebas navigasi bulan dan tanggal manapun
    final now = DateTime.now();
    if (now.year == 2026 && now.month == 9) {
      _displayedMonth = DateTime(2026, 9, 1);
      _selectedDate = DateTime(2026, 9, 24);
    } else if (now.year == 2026 && now.month < 9) {
      _displayedMonth = DateTime(2026, 9, 1);
      _selectedDate = DateTime(2026, 9, 24);
    } else {
      // Jika saat ini di September 2026 atau bulan lainnya, set default tanggal 24 September atau hari ini
      _displayedMonth = DateTime(2026, 9, 1);
      _selectedDate = DateTime(2026, 9, 24);
    }

    _selectedSlot = '09:00'; // Default terpilih sesuai referensi gambar

    _seedInitialDataIfAvailable();
  }

  @override
  void dispose() {
    _complaintController.dispose();
    super.dispose();
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
    if (now.year == d.year && now.month == d.month && now.day == d.day) {
      return true;
    }
    // Tanggal 24 September 2026 juga dihitung sebagai "Hari ini" sesuai UI gambar
    return d.year == 2026 && d.month == 9 && d.day == 24;
  }

  String _formatDateHeaderLabel(DateTime d) {
    final dayStr = _dayName(d.weekday);
    final monthStr = _monthName(d.month);
    if (_isToday(d)) {
      return 'Hari ini, $dayStr, ${d.day} $monthStr';
    }
    return '$dayStr, ${d.day} $monthStr';
  }

  /// Menentukan apakah tanggal dapat dipilih
  bool _isDateSelectable(DateTime d) {
    // Di September 2026, tanggal 1-23 nonaktif, 24-30 aktif
    if (d.year == 2026 && d.month == 9) {
      return d.day >= 24;
    }
    final cleanToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final cleanDate = DateTime(d.year, d.month, d.day);
    return !cleanDate.isBefore(cleanToday);
  }

  void _previousMonth() {
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
                onTap: _previousMonth,
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
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: _headerPink,
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

          // Grid Tanggal (7 Kolom)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 35, // 5 baris kalender
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

  // ─── 4. Grid Pilihan Jam Real-Time ────────────────────────────────────

  Widget _buildTimeSlotsGrid(Set<String> bookedSlots) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Grid 4 Kolom
        const crossAxisCount = 4;
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: 10,
          children: _allSlots.map((slot) {
            final isBooked = bookedSlots.contains(slot);
            final isSelected = !isBooked && (_selectedSlot == slot);

            return SizedBox(
              width: itemWidth,
              height: 38,
              child: _buildTimeSlotPill(
                slot: slot,
                isBooked: isBooked,
                isSelected: isSelected,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTimeSlotPill({
    required String slot,
    required bool isBooked,
    required bool isSelected,
  }) {
    Color bg;
    Border? border;
    Color textColor;
    TextDecoration? textDecoration;
    FontWeight fontWeight;

    if (isBooked) {
      // Slot sudah dibooking orang lain:
      // Tampilan persis di gambar referensi: abu-abu muda, border abu-abu, teks dicoret (strikethrough)
      bg = _bookedBg;
      border = Border.all(color: _bookedBorder, width: 1.2);
      textColor = _bookedText;
      textDecoration = TextDecoration.lineThrough;
      fontWeight = FontWeight.w600;
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
