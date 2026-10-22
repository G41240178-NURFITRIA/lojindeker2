import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/app_user.dart';
import 'payment_qris_screen.dart';

/// Layar Ringkasan Booking & Pemilihan Metode Pembayaran (Tampilan 1)
class BookingSummaryScreen extends StatefulWidget {
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
  final int consultationFee;
  final int serviceFee;

  const BookingSummaryScreen({
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
    this.consultationFee = 50000,
    this.serviceFee = 2500,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  static const Color _headerPink = Color(0xFFE5406C);
  static const Color _bgScreen = Color(0xFFFCEDF2);
  static const Color _selectedBorderPink = Color(0xFFE5406C);
  static const Color _unselectedBorder = Color(0xFFEADBE0);
  static const Color _textDark = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF757575);
  static const Color _dividerColor = Color(0xFFF1E3E7);

  // Default metode pembayaran: 'qris', opsi lain: 'bca_va', 'gopay'
  String _selectedPaymentMethod = 'qris';

  int get _totalAmount => widget.consultationFee + widget.serviceFee;

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

  void _handlePay() {
    if (_selectedPaymentMethod == 'qris') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentQrisScreen(
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
            totalAmount: _totalAmount,
          ),
        ),
      );
    } else {
      // Jika pengguna memilih metode selain QRIS, berikan opsi beralih ke QRIS
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan pilih QRIS untuk melanjutkan pembayaran otomatis.',
            style: GoogleFonts.poppins(fontSize: 12.5),
          ),
          backgroundColor: _headerPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatShortIndonesianDate(widget.selectedDate);

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
                    'Ringkasan booking',
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
              // 1. Kartu Jadwal Konsultasi
              _buildConsultationScheduleCard(formattedDate),

              const SizedBox(height: 16),

              // 2. Kartu Rincian Biaya
              _buildCostDetailsCard(),

              const SizedBox(height: 16),

              // 3. Judul "Metode pembayaran"
              Text(
                'Metode pembayaran',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),

              const SizedBox(height: 10),

              // 4. Opsi Metode Pembayaran (QRIS, BCA VA, GoPay)
              _buildPaymentOptions(),

              const SizedBox(height: 16),

              // 5. Kotak Info Notice
              _buildInfoNotice(),

              const SizedBox(height: 18),

              // 6. Tombol "Bayar Rp 52.500"
              _buildPayButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ─── 1. Kartu Jadwal Konsultasi ─────────────────────────────────────────

  Widget _buildConsultationScheduleCard(String formattedDate) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jadwal konsultasi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),

          // Dokter: Avatar + Nama + Spesialisasi
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
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
              Column(
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

          // Tanggal
          _buildRowDetail('Tanggal', formattedDate),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: _dividerColor,
              height: 1,
              thickness: 1,
            ),
          ),

          // Jam
          _buildRowDetail('Jam', '${widget.timeSlot} WIB'),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: _dividerColor,
              height: 1,
              thickness: 1,
            ),
          ),

          // Durasi sesi
          _buildRowDetail('Durasi sesi', '25 menit'),
        ],
      ),
    );
  }

  // ─── 2. Kartu Rincian Biaya ─────────────────────────────────────────────

  Widget _buildCostDetailsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian biaya',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 12),

          // Biaya konsultasi
          _buildRowDetail('Biaya konsultasi', _formatCurrency(widget.consultationFee)),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: _dividerColor,
              height: 1,
              thickness: 1,
            ),
          ),

          // Biaya layanan
          _buildRowDetail('Biaya layanan', _formatCurrency(widget.serviceFee)),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              color: _dividerColor,
              height: 1,
              thickness: 1,
            ),
          ),

          // Total bayar (dengan warna pink menonjol)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total bayar',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              Text(
                _formatCurrency(_totalAmount),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _headerPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: _textGrey,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  // ─── 3. Pilihan Metode Pembayaran ───────────────────────────────────────

  Widget _buildPaymentOptions() {
    return Column(
      children: [
        // 1. QRIS
        _buildPaymentOptionItem(
          id: 'qris',
          title: 'QRIS',
          subtitle: 'Scan pakai e-wallet atau m-banking apa saja',
          icon: Icons.qr_code_2_rounded,
        ),

        const SizedBox(height: 10),

        // 2. Virtual Account BCA
        _buildPaymentOptionItem(
          id: 'bca_va',
          title: 'Virtual Account BCA',
          subtitle: 'Transfer via ATM/m-banking BCA',
          icon: Icons.account_balance_outlined,
        ),

        const SizedBox(height: 10),

        // 3. GoPay
        _buildPaymentOptionItem(
          id: 'gopay',
          title: 'GoPay',
          subtitle: 'Saldo e-wallet GoPay',
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }

  Widget _buildPaymentOptionItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _selectedBorderPink : _unselectedBorder,
            width: isSelected ? 1.5 : 1.2,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x14E5406C),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Ikon kotak soft pink
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE7EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 22,
                  color: _headerPink,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Teks Judul & Subjudul
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: _textGrey,
                    ),
                  ),
                ],
              ),
            ),

            // Radio Button Custom
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _headerPink : const Color(0xFFCECECE),
                  width: isSelected ? 2 : 1.8,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: _headerPink,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 4. Kotak Info Notice ───────────────────────────────────────────────

  Widget _buildInfoNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E4E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: Color(0xFFD64D75),
          ),
          const SizedBox(height: 6),
          Text(
            'Booking baru diteruskan ke dokter setelah\npembayaran berhasil.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF666666),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. Tombol Bayar Rp 52.500 ──────────────────────────────────────────

  Widget _buildPayButton() {
    return InkWell(
      onTap: _handlePay,
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
                Icons.lock_outline_rounded,
                size: 16,
                color: Color(0xFF1F1F1F),
              ),
              const SizedBox(width: 8),
              Text(
                'Bayar ${_formatCurrency(_totalAmount)}',
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
}
