import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/consultation_booking_service.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_repository.dart';
import '../models/consultation_booking_model.dart';
import 'payment_success_screen.dart';

/// Model Bank Virtual Account
class VaBankInfo {
  final String id;
  final String name;
  final String shortName;
  final String vaNumber;
  final Color color;
  final IconData icon;

  const VaBankInfo({
    required this.id,
    required this.name,
    required this.shortName,
    required this.vaNumber,
    required this.color,
    required this.icon,
  });
}

/// Layar Pembayaran Virtual Account (Mandiri, BRI, BNI, BCA)
class PaymentVaScreen extends StatefulWidget {
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
  final int totalAmount;
  final String bankId; // 'mandiri', 'bri', 'bni', 'bca'

  const PaymentVaScreen({
    super.key,
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
    this.totalAmount = 52500,
    required this.bankId,
  });

  @override
  State<PaymentVaScreen> createState() => _PaymentVaScreenState();
}

class _PaymentVaScreenState extends State<PaymentVaScreen> {
  static const Color _headerPink = Color(0xFFE5406C);
  static const Color _bgScreen = Color(0xFFFCEDF2);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _dividerColor = Color(0xFFF1E3E7);

  late VaBankInfo _bankInfo;
  Timer? _countdownTimer;
  int _remainingSeconds = 24 * 3600 - 32; // ~23 jam 59 menit
  bool _isProcessing = false;

  static const Map<String, VaBankInfo> _bankCatalog = {
    'mandiri': VaBankInfo(
      id: 'mandiri',
      name: 'Bank Mandiri',
      shortName: 'Mandiri',
      vaNumber: '88708 0812 8899 4432',
      color: Color(0xFF003D79),
      icon: Icons.account_balance_rounded,
    ),
    'bri': VaBankInfo(
      id: 'bri',
      name: 'Bank Rakyat Indonesia',
      shortName: 'BRI',
      vaNumber: '12800 0812 8899 4432',
      color: Color(0xFF00529C),
      icon: Icons.account_balance_rounded,
    ),
    'bni': VaBankInfo(
      id: 'bni',
      name: 'Bank Negara Indonesia',
      shortName: 'BNI',
      vaNumber: '98808 1288 9944 3210',
      color: Color(0xFFE05A1F),
      icon: Icons.account_balance_rounded,
    ),
    'bca': VaBankInfo(
      id: 'bca',
      name: 'Bank Central Asia',
      shortName: 'BCA',
      vaNumber: '39010 8128 8994 4321',
      color: Color(0xFF005BAC),
      icon: Icons.account_balance_rounded,
    ),
  };

  @override
  void initState() {
    super.initState();
    _bankInfo = _bankCatalog[widget.bankId.toLowerCase()] ??
        _bankCatalog['mandiri']!;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatCountdown(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              '$label berhasil disalin!',
              style: GoogleFonts.poppins(fontSize: 12.5),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00875A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final user = AuthService.instance.currentUser;
      final patientUid = user?.uid ?? 'guest_patient';
      String patientName = 'Pasien';

      if (user != null) {
        if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
          patientName = user.displayName!.trim();
        } else {
          final profile = await UserRepository.instance.findByUid(user.uid);
          if (profile != null && profile.fullName.isNotEmpty) {
            patientName = profile.fullName;
          }
        }
      }

      final y = widget.selectedDate.year.toString().padLeft(4, '0');
      final m = widget.selectedDate.month.toString().padLeft(2, '0');
      final d = widget.selectedDate.day.toString().padLeft(2, '0');
      final randomNum = 100 + Random().nextInt(899);
      final transactionId = 'TRX-$y$m$d-$randomNum';

      final booking = ConsultationBookingModel(
        id: '',
        doctorId: widget.doctorId,
        doctorName: widget.doctorName,
        doctorSpecialty: widget.specialty,
        patientId: patientUid,
        patientName: patientName,
        date: widget.dateText,
        dateKey: widget.dateKey,
        timeSlot: widget.timeSlot,
        complaint: widget.complaint.isNotEmpty
            ? widget.complaint
            : 'Konsultasi dokter diabetes',
        transactionId: transactionId,
        paymentMethod: 'va_${_bankInfo.id}',
        totalAmount: widget.totalAmount,
      );

      final savedBooking =
          await ConsultationBookingService.instance.createBooking(booking);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            bookingId: savedBooking.id,
            doctor: widget.doctor,
            doctorId: widget.doctorId,
            doctorName: widget.doctorName,
            specialty: widget.specialty,
            initials: widget.initials,
            selectedDate: widget.selectedDate,
            dateKey: widget.dateKey,
            dateText: widget.dateText,
            timeSlot: widget.timeSlot,
            complaint: widget.complaint,
            transactionId: transactionId,
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kendala: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
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
                    'Virtual Account ${_bankInfo.shortName}',
                    style: GoogleFonts.poppins(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            // Timer batas waktu pembayaran
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3D6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Color(0xFFB5701B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selesaikan Pembayaran Dalam',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8D5B00),
                          ),
                        ),
                        Text(
                          _formatCountdown(_remainingSeconds),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB5701B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Kartu Utama Nomor Virtual Account
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Bank
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _bankInfo.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _bankInfo.shortName,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _bankInfo.color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _bankInfo.name,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: _dividerColor, height: 1),
                  ),

                  // Nomor Virtual Account
                  Text(
                    'Nomor Virtual Account',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SelectableText(
                        _bankInfo.vaNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB82855),
                          letterSpacing: 0.5,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyToClipboard(_bankInfo.vaNumber, 'Nomor VA'),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE7EE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.copy_rounded, size: 14, color: _headerPink),
                              const SizedBox(width: 4),
                              Text(
                                'Salin',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: _headerPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Total Pembayaran
                  Text(
                    'Total Pembayaran',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: _textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatCurrency(widget.totalAmount),
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: _textDark,
                        ),
                      ),
                      InkWell(
                        onTap: () => _copyToClipboard(
                          widget.totalAmount.toString(),
                          'Total Nominal',
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F1F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF555555)),
                              const SizedBox(width: 4),
                              Text(
                                'Salin',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF555555),
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
            ),

            const SizedBox(height: 14),

            // Petunjuk Cara Transfer
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    'Petunjuk Transfer ${_bankInfo.shortName}',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _buildStepRow('1', 'Buka aplikasi m-Banking ${_bankInfo.shortName} Anda.'),
                    _buildStepRow('2', 'Pilih menu Transfer atau Pembayaran > Virtual Account.'),
                    _buildStepRow('3', 'Masukkan Nomor Virtual Account di atas.'),
                    _buildStepRow('4', 'Pastikan nama penerima & nominal sesuai (${_formatCurrency(widget.totalAmount)}).'),
                    _buildStepRow('5', 'Konfirmasi transaksi & simpan bukti pembayaran Anda.'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Konfirmasi / Cek Status Pembayaran
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerPink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isProcessing ? 'Memverifikasi Pembayaran...' : 'Saya Sudah Bayar',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE7EE),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _headerPink,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF555555),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
