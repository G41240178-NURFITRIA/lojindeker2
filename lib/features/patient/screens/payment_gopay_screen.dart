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

/// Layar Pembayaran GoPay Real-time
/// Menampilkan saldo GoPay, rincian transaksi, dan konfirmasi bayar instan
class PaymentGopayScreen extends StatefulWidget {
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
  final int gopayBalance;

  const PaymentGopayScreen({
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
    this.gopayBalance = 150000,
  });

  @override
  State<PaymentGopayScreen> createState() => _PaymentGopayScreenState();
}

class _PaymentGopayScreenState extends State<PaymentGopayScreen> {
  static const Color _gopayBlue = Color(0xFF0081A0);
  static const Color _headerPink = Color(0xFFE5406C);
  static const Color _bgScreen = Color(0xFFFCEDF2);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _dividerColor = Color(0xFFF1E3E7);

  bool _isProcessing = false;
  late int _currentBalance;

  @override
  void initState() {
    super.initState();
    _currentBalance = widget.gopayBalance;
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

  Future<void> _handleGopayPayment() async {
    if (_isProcessing) return;

    if (_currentBalance < widget.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saldo GoPay tidak mencukupi untuk pembayaran ini.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulasi otentikasi GoPay 1.2 detik
      await Future.delayed(const Duration(milliseconds: 1200));

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
            : 'Konsultasi dokter diabetes via GoPay',
        transactionId: transactionId,
        paymentMethod: 'gopay',
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
            content: Text('Terjadi kesalahan: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingBalance = _currentBalance - widget.totalAmount;
    final isSufficient = _currentBalance >= widget.totalAmount;

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
                    'Pembayaran GoPay',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Kartu Akun GoPay & Saldo Utama
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F7FA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.account_balance_wallet_rounded,
                                color: _gopayBlue,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GoPay',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _gopayBlue,
                                ),
                              ),
                              Text(
                                'Akun Terhubung (0812-****-4432)',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: _textGrey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4F7E7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Aktif ✓',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00875A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(color: _dividerColor, height: 1),
                  ),

                  // Informasi Saldo GoPay
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saldo GoPay Anda',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _textGrey,
                        ),
                      ),
                      Text(
                        _formatCurrency(_currentBalance),
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00875A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Rincian Pembayaran
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
                  Text(
                    'Rincian Transaksi',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Konsultasi ${widget.doctorName}',
                        style: GoogleFonts.poppins(fontSize: 12.5, color: _textGrey),
                      ),
                      Text(
                        _formatCurrency(widget.totalAmount - 2500),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya Layanan Sistem',
                        style: GoogleFonts.poppins(fontSize: 12.5, color: _textGrey),
                      ),
                      Text(
                        _formatCurrency(2500),
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: _dividerColor, height: 1),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Yang Dipotong',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        _formatCurrency(widget.totalAmount),
                        style: GoogleFonts.poppins(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: _headerPink,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sisa Saldo GoPay Nanti',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _textGrey,
                        ),
                      ),
                      Text(
                        _formatCurrency(remainingBalance),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0081A0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Kartu Keamanan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8E9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pembayaran diproses instan & terenkripsi aman dengan sistem GoPay.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tombol Konfirmasi Bayar GoPay
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSufficient ? _gopayBlue : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: (_isProcessing || !isSufficient) ? null : _handleGopayPayment,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _isProcessing
                      ? 'Memproses Pembayaran GoPay...'
                      : 'Bayar Sekarang ${_formatCurrency(widget.totalAmount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
