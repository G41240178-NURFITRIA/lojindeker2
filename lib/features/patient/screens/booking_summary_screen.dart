import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/app_user.dart';
import 'payment_qris_screen.dart';
import 'payment_va_screen.dart';
import 'payment_gopay_screen.dart';

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

  // Metode pembayaran: 'qris', 'va', 'gopay'
  String _selectedPaymentMethod = 'qris';

  // Bank terpilih untuk Virtual Account: 'mandiri', 'bri', 'bni', 'bca'
  String _selectedBank = 'mandiri';

  // Saldo GoPay pengguna (Tersedia & bisa digunakan)
  final int _gopayBalance = 150000;

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

  String get _bankDisplayName {
    switch (_selectedBank) {
      case 'mandiri':
        return 'Mandiri';
      case 'bri':
        return 'BRI';
      case 'bni':
        return 'BNI';
      case 'bca':
        return 'BCA';
      default:
        return 'Mandiri';
    }
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
    } else if (_selectedPaymentMethod == 'va') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentVaScreen(
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
            bankId: _selectedBank,
          ),
        ),
      );
    } else if (_selectedPaymentMethod == 'gopay') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentGopayScreen(
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
            gopayBalance: _gopayBalance,
          ),
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
    final isVaSelected = _selectedPaymentMethod == 'va';
    final isGopaySelected = _selectedPaymentMethod == 'gopay';

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

        // 2. Virtual Account (Tanpa embel-embel BCA di judul)
        _buildPaymentOptionItem(
          id: 'va',
          title: 'Virtual Account',
          subtitle: 'Transfer via ATM/m-banking ($_bankDisplayName)',
          icon: Icons.account_balance_outlined,
          extraContent: isVaSelected ? _buildBankSelector() : null,
        ),

        const SizedBox(height: 10),

        // 3. GoPay (Menampilkan saldo langsung & rincian saat dipilih)
        _buildPaymentOptionItem(
          id: 'gopay',
          title: 'GoPay',
          subtitle: 'Saldo e-wallet GoPay: ${_formatCurrency(_gopayBalance)}',
          icon: Icons.account_balance_wallet_outlined,
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFD4F7E7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '✓ Cukup',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF00875A),
              ),
            ),
          ),
          extraContent: isGopaySelected ? _buildGopayBalanceDetail() : null,
        ),
      ],
    );
  }

  /// Pilihan Bank untuk Virtual Account (Mandiri, BRI, BNI, BCA)
  Widget _buildBankSelector() {
    final banks = [
      {'id': 'mandiri', 'name': 'Bank Mandiri', 'code': 'MANDIRI', 'color': 0xFF003D79},
      {'id': 'bri', 'name': 'Bank Rakyat Indonesia', 'code': 'BRI', 'color': 0xFF00529C},
      {'id': 'bni', 'name': 'Bank Negara Indonesia', 'code': 'BNI', 'color': 0xFFE05A1F},
      {'id': 'bca', 'name': 'Bank Central Asia', 'code': 'BCA', 'color': 0xFF005BAC},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF8BBD0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 15, color: _headerPink),
              const SizedBox(width: 6),
              Text(
                'Pilih Bank Tujuan:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _headerPink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...banks.map((b) {
            final isBankSelected = _selectedBank == b['id'];
            final bankColor = Color(b['color'] as int);

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedBank = b['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isBankSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isBankSelected ? _selectedBorderPink : const Color(0xFFEADBE0),
                    width: isBankSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: bankColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          b['code'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: bankColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        b['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: isBankSelected ? FontWeight.w700 : FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                    ),
                    Radio<String>(
                      value: b['id'] as String,
                      groupValue: _selectedBank,
                      activeColor: _headerPink,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBank = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Detail Saldo GoPay dan Rincian Pemotongan
  Widget _buildGopayBalanceDetail() {
    final remaining = _gopayBalance - _totalAmount;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA).withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFB2EBF2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, size: 16, color: Color(0xFF0081A0)),
              const SizedBox(width: 6),
              Text(
                'Informasi Saldo GoPay',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0081A0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Saldo Saat Ini', style: GoogleFonts.poppins(fontSize: 11.5, color: _textGrey)),
              Text(_formatCurrency(_gopayBalance), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF00875A))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pembayaran', style: GoogleFonts.poppins(fontSize: 11.5, color: _textGrey)),
              Text('- ${_formatCurrency(_totalAmount)}', style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: _headerPink)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(color: Color(0xFFB2EBF2), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sisa Saldo GoPay Nanti', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: _textDark)),
              Text(_formatCurrency(remaining), style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w800, color: const Color(0xFF0081A0))),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '• Pembayaran instan 1-klik dengan saldo GoPay Anda.',
            style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF00738F), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionItem({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? badge,
    Widget? extraContent,
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
        child: Column(
          children: [
            Row(
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
                      Row(
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            badge,
                          ],
                        ],
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
            if (extraContent != null) extraContent,
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
