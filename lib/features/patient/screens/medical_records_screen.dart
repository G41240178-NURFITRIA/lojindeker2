import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String patientName;

  const MedicalRecordsScreen({
    super.key,
    this.patientName = 'Muhammad Nizam',
  });

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Hasil Lab', 'Resep Obat', 'Catatan Dokter'];

  // Data Rekam Medis Interaktif
  late List<_MedicalRecordItem> _records;

  @override
  void initState() {
    super.initState();
    _records = [
      _MedicalRecordItem(
        date: '20 Mei 2026',
        doctorName: 'dr. Afieta Putri, Sp.PD',
        clinic: 'Poli Penyakit Dalam & Endokrin - RS D-Care',
        status: 'Terkontrol Baik',
        statusColor: const Color(0xFF2E7D32),
        gdp: '108 mg/dL',
        gdpp: '135 mg/dL',
        hba1c: '6.2%',
        bloodPressure: '120/80 mmHg',
        weight: '68 kg',
        medicines: [
          'Metformin HCl 500 mg (2x1 sesudah makan)',
          'Vitamin B Complex (1x1 pagi)',
        ],
        notes:
            'Kadar gula darah stabil dalam target. Pasien disiplin diet dan olahraga. Jadwal kontrol berikutnya: 20 Juni 2026.',
        isExpanded: true,
      ),
      _MedicalRecordItem(
        date: '18 April 2026',
        doctorName: 'dr. Hendra Wijaya, Sp.PD',
        clinic: 'Poli Penyakit Dalam - RS D-Care',
        status: 'Evaluasi Dosis',
        statusColor: const Color(0xFFE65100),
        gdp: '125 mg/dL',
        gdpp: '158 mg/dL',
        hba1c: '6.6%',
        bloodPressure: '125/82 mmHg',
        weight: '69 kg',
        medicines: [
          'Metformin HCl 500 mg (2x1 sesudah makan)',
        ],
        notes:
            'Gula darah puasa sedikit di atas target. Lakukan penyesuaian jam makan malam dan kurangi konsumsi karbohidrat olahan.',
        isExpanded: false,
      ),
      _MedicalRecordItem(
        date: '15 Maret 2026',
        doctorName: 'dr. Hendra Wijaya, Sp.PD',
        clinic: 'Poli Umum / Skrining - RS D-Care',
        status: 'Diagnosis Awal',
        statusColor: const Color(0xFFC62828),
        gdp: '165 mg/dL',
        gdpp: '195 mg/dL',
        hba1c: '7.1%',
        bloodPressure: '130/85 mmHg',
        weight: '71 kg',
        medicines: [
          'Metformin HCl 500 mg (1x1 sesudah makan)',
        ],
        notes:
            'Keluhan sering haus dan lemas. Terdiagnosa awal Diabetes Melitus Tipe 2. Edukasi pola makan dan memulai terapi oral.',
        isExpanded: false,
      ),
    ];
  }

  void _showAddSelfCheckDialog() {
    final gdpController = TextEditingController();
    final noteController = TextEditingController();
    String selectedType = 'Puasa';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF1F1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.bloodtype_outlined,
                          color: Color(0xFFBA171E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tambah Catatan Glukosa Mandiri',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF141414),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Kadar Gula Darah (mg/dL)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: gdpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 110',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFFAF1F1),
                      suffixText: 'mg/dL',
                      suffixStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFBA171E)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Waktu Pemeriksaan',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Puasa', '2 Jam PP', 'Sewaktu'].map((type) {
                      final isSelected = selectedType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedType = type);
                          },
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? Colors.white : const Color(0xFF555555),
                          ),
                          selectedColor: const Color(0xFFBA171E),
                          backgroundColor: const Color(0xFFFAF1F1),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Catatan Tambahan (Opsional)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Misal: setelah jalan santai pagi...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFFAF1F1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final val = gdpController.text.trim();
                        if (val.isEmpty) return;

                        setState(() {
                          _records.insert(
                            0,
                            _MedicalRecordItem(
                              date: 'Hari Ini (${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year})',
                              doctorName: 'Pemeriksaan Mandiri ($selectedType)',
                              clinic: 'Pemeriksaan Glukometer Mandiri',
                              status: 'Catatan Pasien',
                              statusColor: const Color(0xFF1976D2),
                              gdp: '$val mg/dL',
                              gdpp: '-',
                              hba1c: '-',
                              bloodPressure: '-',
                              weight: '-',
                              medicines: const [],
                              notes: noteController.text.trim().isNotEmpty
                                  ? noteController.text.trim()
                                  : 'Pencatatan glukosa mandiri harian.',
                              isExpanded: true,
                            ),
                          );
                        });

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Data pemeriksaan berhasil ditambahkan ke Rekam Medis!',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBA171E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        'Simpan ke Rekam Medis',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
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
      },
    );
  }

  void _showDownloadResumeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFBA171E), size: 28),
              const SizedBox(width: 10),
              Text(
                'Resume Medis PDF',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dokumen resume medis atas nama ${widget.patientName} (No. RM: RM-2026-0812) siap diunduh atau dibagikan ke dokter.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF444444)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF1F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEADBDB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF2E7D32), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Terverifikasi resmi oleh RS D-Care Digital System',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Tutup',
                style: GoogleFonts.poppins(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Resume Rekam Medis berhasil diunduh (Resume_Medis_${widget.patientName.replaceAll(' ', '_')}.pdf)',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF8F0D12),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
              label: Text('Unduh PDF', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA171E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1F1),
      body: Stack(
        children: [
          // Background decorative circle at top right
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEED5D7).withValues(alpha: 0.8),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. App Bar Header
                _buildAppBar(context),

                // 2. Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Identity Card
                        _buildPatientProfileCard(),
                        const SizedBox(height: 18),

                        // Quick Filter Chips
                        _buildFilterChips(),
                        const SizedBox(height: 18),

                        // Title & Timeline Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Kunjungan Medis',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF141414),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBA171E).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_records.length} Catatan',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFBA171E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Records List
                        ..._records.map((item) => _buildRecordCard(item)),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom floating button for quick self-check record
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showAddSelfCheckDialog,
                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                label: Text(
                  'Catat Gula Darah Mandiri',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBA171E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEADBDB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),

          // Title
          Text(
            'Rekam Medis Pasien',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),

          // Download PDF button
          InkWell(
            onTap: _showDownloadResumeDialog,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEADBDB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.download_rounded,
                size: 20,
                color: Color(0xFF8F0D12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8F0D12),
            Color(0xFFBA171E),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8F0D12).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No. RM: RM-2026-0812',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Diabetes Melitus Tipe 2',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPatientMetaItem('Usia', '28 Thn'),
              _buildPatientMetaItem('Gender', 'Laki-laki'),
              _buildPatientMetaItem('Gol. Darah', 'O+'),
              _buildPatientMetaItem('Status', 'Rawat Jalan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientMetaItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilterIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFBA171E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFBA171E) : const Color(0xFFE0D0D0),
                    width: 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFFBA171E).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Text(
                  _filters[index],
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF555555),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRecordCard(_MedicalRecordItem item) {
    // Saring berdasarkan filter terpilih
    final showLab = _selectedFilterIndex == 0 || _selectedFilterIndex == 1;
    final showMeds = _selectedFilterIndex == 0 || _selectedFilterIndex == 2;
    final showNotes = _selectedFilterIndex == 0 || _selectedFilterIndex == 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Kunjungan
          InkWell(
            onTap: () {
              setState(() {
                item.isExpanded = !item.isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF1F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medical_information_outlined,
                      color: Color(0xFFBA171E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.date,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF141414),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: item.statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.doctorName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        Text(
                          item.clinic,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    item.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Detail Isi Rekam Medis (Jika di-expand)
          if (item.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hasil Laboratorium & Tanda Vital
                  if (showLab) ...[
                    Text(
                      'Tanda Vital & Glukosa',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8F0D12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF1F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabCell('Gula Darah Puasa (GDP)', item.gdp, isHighlight: true),
                              _buildLabCell('Gula Darah 2 Jam PP', item.gdpp),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildLabCell('HbA1c', item.hba1c, isHighlight: true),
                              _buildLabCell('Tekanan Darah', item.bloodPressure),
                            ],
                          ),
                          if (item.weight != '-') ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildLabCell('Berat Badan', item.weight),
                                const Spacer(),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Resep Obat
                  if (showMeds && item.medicines.isNotEmpty) ...[
                    Text(
                      'Resep Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8F0D12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...item.medicines.map(
                      (med) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.medication_outlined, size: 16, color: Color(0xFFBA171E)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                med,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Catatan Dokter & Diagnosis
                  if (showNotes) ...[
                    Text(
                      'Catatan Dokter & Anjuran',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8F0D12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        item.notes,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.4,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabCell(String label, String val, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              color: const Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isHighlight ? const Color(0xFFBA171E) : const Color(0xFF141414),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalRecordItem {
  final String date;
  final String doctorName;
  final String clinic;
  final String status;
  final Color statusColor;
  final String gdp;
  final String gdpp;
  final String hba1c;
  final String bloodPressure;
  final String weight;
  final List<String> medicines;
  final String notes;
  bool isExpanded;

  _MedicalRecordItem({
    required this.date,
    required this.doctorName,
    required this.clinic,
    required this.status,
    required this.statusColor,
    required this.gdp,
    required this.gdpp,
    required this.hba1c,
    required this.bloodPressure,
    required this.weight,
    required this.medicines,
    required this.notes,
    this.isExpanded = false,
  });
}
