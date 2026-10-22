import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/app_user.dart';
import 'patient_schedule_screen.dart';

/// Layar Konfirmasi Pembayaran Berhasil (Tampilan 3)
/// Menampilkan ikon sukses, rincian booking & transaksi, serta tombol ke jadwal pasien
class PaymentSuccessScreen extends StatelessWidget {
  final String? bookingId;
  final AppUser? doctor;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String initials;
  final DateTime selectedDate;
  final String? dateKey;
  final String dateText;
  final String timeSlot;
  final String complaint;
  final String transactionId;
  final int totalAmount;

  const PaymentSuccessScreen({
    super.key,
    this.bookingId,
    this.doctor,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.initials,
    required this.selectedDate,
    this.dateKey,
    required this.dateText,
    required this.timeSlot,
    required this.complaint,
    required this.transactionId,
    this.totalAmount = 52500,
  });

  static const Color _bgScreen = Color(0xFFFCEDF2);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _dividerColor = Color(0xFFF1E3E7);

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

  String _formatShortIndonesianDate(DateTime d) {
    final dayStr = _dayNames[d.weekday - 1];
    final monthStr = _monthNames[d.month - 1];
    return '$dayStr, ${d.day} $monthStr';
  }

  String _formatCurrency(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatShortIndonesianDate(selectedDate);

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // 1. Lingkaran Ikon Centang Hijau
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4F7E7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 46,
                    color: Color(0xFF00B074),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 2. Judul "Pembayaran berhasil"
              Text(
                'Pembayaran berhasil',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(height: 10),

              // 3. Deskripsi Subjudul
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF555555),
                      height: 1.45,
                    ),
                    children: [
                      const TextSpan(text: 'Booking kamu dengan '),
                      TextSpan(
                        text: doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const TextSpan(text: ' pada '),
                      TextSpan(
                        text: '$formattedDate, $timeSlot WIB',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const TextSpan(
                        text: ' sedang diteruskan ke dokter untuk dikonfirmasi.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // 4. Kartu Rincian Transaksi
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
                  children: [
                    // Row 1: No. transaksi
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'No. transaksi',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textGrey,
                          ),
                        ),
                        Text(
                          transactionId,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: _dividerColor,
                        height: 1,
                        thickness: 1,
                      ),
                    ),

                    // Row 2: Total dibayar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total dibayar',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textGrey,
                          ),
                        ),
                        Text(
                          _formatCurrency(totalAmount),
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        color: _dividerColor,
                        height: 1,
                        thickness: 1,
                      ),
                    ),

                    // Row 3: Status booking
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status booking',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _textGrey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Menunggu konfirmasi dokter',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB5701B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // 5. Tombol "Lihat jadwal saya"
              InkWell(
                onTap: () {
                  // Navigasi ke Tampilan Jadwal Saya (Real-time Status Booking)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientScheduleScreen(
                        bookingId: bookingId,
                        doctor: doctor,
                        doctorId: doctorId,
                        doctorName: doctorName,
                        specialty: specialty,
                        initials: initials,
                        selectedDate: selectedDate,
                        dateKey: dateKey ?? '',
                        dateText: dateText,
                        timeSlot: timeSlot,
                        complaint: complaint,
                        transactionId: transactionId,
                        totalAmount: totalAmount,
                      ),
                    ),
                  );
                },
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                          color: Color(0xFF1F1F1F),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lihat jadwal saya',
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
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
