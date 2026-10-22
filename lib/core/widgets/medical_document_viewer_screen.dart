import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Layar Viewer & Unduh Dokumen Medis Resmi D-Care
class MedicalDocumentViewerScreen extends StatefulWidget {
  final String documentTitle;
  final String patientName;
  final String doctorName;
  final String? date;
  final String? fileSize;
  final String? glucoseSummary;

  const MedicalDocumentViewerScreen({
    super.key,
    required this.documentTitle,
    this.patientName = 'verelgio_',
    this.doctorName = 'dr. Kaka, Sp.PD',
    this.date,
    this.fileSize = '95 KB',
    this.glucoseSummary,
  });

  @override
  State<MedicalDocumentViewerScreen> createState() =>
      _MedicalDocumentViewerScreenState();
}

class _MedicalDocumentViewerScreenState
    extends State<MedicalDocumentViewerScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  bool _isDownloaded = false;

  Future<void> _startDownload() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    // Simulasi proses unduh berkas PDF
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;
      setState(() {
        _downloadProgress = i / 10;
      });
    }

    if (!mounted) return;
    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
    });

    _showDownloadSuccessDialog();
  }

  void _showDownloadSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32),
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Unduhan Berhasil!',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Berkas "${widget.documentTitle}" berhasil disimpan ke folder Download / Dokumen perangkat Anda.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Selesai',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayDate = widget.date ?? '22 Oktober 2026';
    final isResep = widget.documentTitle.toLowerCase().contains('resep');
    final isRujukan = widget.documentTitle.toLowerCase().contains('rujukan');

    return Scaffold(
      backgroundColor: const Color(0xFF525659), // Background abu-abu PDF viewer
      appBar: AppBar(
        backgroundColor: const Color(0xFF323639),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentTitle,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.fileSize} • Halaman 1/1',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
            tooltip: 'Bagikan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tautan berkas ${widget.documentTitle} disalin ke papan klip.',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded,
                color: Colors.white, size: 22),
            tooltip: 'Unduh PDF',
            onPressed: _startDownload,
          ),
        ],
      ),
      body: Column(
        children: [
          // Bar Progress Download jika sedang proses
          if (_isDownloading)
            LinearProgressIndicator(
              value: _downloadProgress,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),

          // Area Lembar Kertas PDF A4
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kop Surat Resmi Rumah Sakit
                      _buildHospitalHeader(),

                      const Divider(color: Colors.black87, thickness: 2),
                      const SizedBox(height: 2),
                      const Divider(color: Colors.black54, thickness: 0.8),

                      const SizedBox(height: 12),

                      // Judul Dokumen
                      Center(
                        child: Text(
                          isResep
                              ? 'SALINAN RESEP DOKTER RESMI'
                              : (isRujukan
                                  ? 'SURAT RUJUKAN PEMERIKSAAN KLINIS'
                                  : 'LEMBAR HASIL PEMERIKSAAN LABORATORIUM'),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: const Color(0xFF1E1E1E),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'No. Dokumen: DC-LAB/2026/X/0812',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Identitas Pasien & Dokter
                      _buildPatientInfoBox(displayDate),

                      const SizedBox(height: 16),

                      // Konten Tabel / Rincian Medis
                      if (isResep)
                        _buildPrescriptionContent()
                      else if (isRujukan)
                        _buildReferralContent()
                      else
                        _buildLabResultsTable(),

                      const SizedBox(height: 16),

                      // Catatan & Rekomendasi Dokter
                      _buildDoctorRecommendation(),

                      const SizedBox(height: 20),

                      // Tanda Tangan & Cap Validasi
                      _buildSignatureAndStamp(displayDate),

                      const SizedBox(height: 16),

                      // Footer Keamanan Dokumen
                      _buildDocumentFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Tombol Aksi Bawah: Unduh / Buka
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildHospitalHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.softPinkCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.local_hospital_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RS D-CARE & LABORATORIUM MEDIS',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB71C1C),
                ),
              ),
              Text(
                'Pusat Layanan Diabetes & Penyakit Dalam Terpadu',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),
              Text(
                'Jl. Danau Toba No. 12 • Telp: (0331) 543210 • Akreditasi Paripurna KARS',
                style: GoogleFonts.poppins(
                  fontSize: 8.5,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfoBox(String displayDate) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Nama Pasien', widget.patientName),
              ),
              Expanded(
                child: _buildInfoItem('No. Rekam Medis', 'RM-2026-0812'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem('Dokter Pengirim', widget.doctorName),
              ),
              Expanded(
                child: _buildInfoItem('Tgl Pemeriksaan', displayDate),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLabResultsTable() {
    final rows = [
      {'param': 'Glukosa Darah Puasa (GDP)', 'hasil': '110 mg/dL', 'rujukan': '< 100 mg/dL', 'status': 'Terkontrol'},
      {'param': 'Glukosa Darah 2 Jam PP', 'hasil': '138 mg/dL', 'rujukan': '< 140 mg/dL', 'status': 'Normal'},
      {'param': 'HbA1c', 'hasil': '6.2 %', 'rujukan': '< 6.5 %', 'status': 'Optimal Terkendali'},
      {'param': 'Tekanan Darah', 'hasil': '120/80 mmHg', 'rujukan': '< 130/80 mmHg', 'status': 'Normal'},
      {'param': 'Kolesterol Total', 'hasil': '175 mg/dL', 'rujukan': '< 200 mg/dL', 'status': 'Normal'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A. HASIL PEMERIKSAAN KUANTITATIF',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Table(
            border: TableBorder(
              horizontalInside:
                  BorderSide(color: Colors.grey.shade300, width: 0.8),
            ),
            columnWidths: const {
              0: FlexColumnWidth(2.3),
              1: FlexColumnWidth(1.2),
              2: FlexColumnWidth(1.3),
              3: FlexColumnWidth(1.2),
            },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFECEFF1)),
                children: [
                  _buildTableCell('Pemeriksaan', isHeader: true),
                  _buildTableCell('Hasil', isHeader: true),
                  _buildTableCell('Nilai Rujukan', isHeader: true),
                  _buildTableCell('Status', isHeader: true),
                ],
              ),
              ...rows.map((r) {
                return TableRow(
                  children: [
                    _buildTableCell(r['param']!),
                    _buildTableCell(r['hasil']!, isBold: true),
                    _buildTableCell(r['rujukan']!),
                    _buildTableCell(
                      r['status']!,
                      color: const Color(0xFF2E7D32),
                      isBold: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAFTAR RESEP & ATURAN PAKAI OBAT',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE4EC).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF8BBD0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('R/ Metformin HCl 500 mg Tablet — No. LX (60 Tab)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              const Text('     S. 2 dd tab 1 d.c. (2 kali sehari 1 tablet setelah makan)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF424242))),
              const Divider(height: 14),
              const Text('R/ Glimepiride 2 mg Tablet — No. XXX (30 Tab)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
              const Text('     S. 1 dd tab 1 mane (1 kali sehari 1 tablet saat sarapan)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF424242))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferralContent() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Diagnosa Kerja : Diabetes Melitus Tipe 2 Terkontrol',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          const SizedBox(height: 4),
          const Text(
              'Mohon evaluasi berkala profil glikemik, fungsi ginjal (Ureum/Kreatinin), serta skrining retinopati diabetik lanjutan.',
              style: TextStyle(fontSize: 11, color: Color(0xFF424242), height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: isHeader ? 9.5 : 9.5,
          fontWeight: isHeader || isBold ? FontWeight.w700 : FontWeight.w400,
          color: color ?? (isHeader ? const Color(0xFF37474F) : const Color(0xFF212121)),
        ),
      ),
    );
  }

  Widget _buildDoctorRecommendation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'B. CATATAN & INTERPRETASI KLINIS',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            widget.glucoseSummary ??
                'Kadar gula darah puasa (110 mg/dL) dan HbA1c (6.2%) menunjukkan kontrol glikemik yang sangat baik. Terapi oral dapat dilanjutkan sesuai anjuran dan jadwal evaluasi berikutnya adalah 1 bulan dari sekarang.',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xFF424242),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignatureAndStamp(String displayDate) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Cap Resmi RS D-Care
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1976D2), width: 2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'RS D-CARE\nTERVALIDASI\nMEDIS',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1976D2),
                height: 1.2,
              ),
            ),
          ),
        ),

        // Tanda Tangan Dokter
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Jember, $displayDate',
              style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade700),
            ),
            Text(
              'Dokter Pemeriksa,',
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF2E7D32), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Tanda Tangan Digital',
                    style: GoogleFonts.poppins(
                      fontSize: 8.5,
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.doctorName,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
            Text(
              'SIP: 446/SIP-D/2024/0112',
              style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentFooter() {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '🔒 Enkripsi Rekam Medis Elektronik D-Care',
            style: GoogleFonts.poppins(fontSize: 8, color: Colors.grey.shade600),
          ),
          Text(
            'Dokumen Asli Bersertifikasi',
            style: GoogleFonts.poppins(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      color: const Color(0xFF323639),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isDownloaded ? const Color(0xFF2E7D32) : AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: _startDownload,
            icon: Icon(
              _isDownloaded
                  ? Icons.check_circle_rounded
                  : Icons.file_download_rounded,
              color: Colors.white,
            ),
            label: Text(
              _isDownloaded
                  ? 'Dokumen Sudah Diunduh'
                  : (_isDownloading
                      ? 'Mengunduh... ${(_downloadProgress * 100).toInt()}%'
                      : 'Unduh Berkas PDF Resmi'),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
