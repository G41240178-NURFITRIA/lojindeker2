import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultation_list_screen.dart';
import 'riwayat_resep_screen.dart';

class RiskAssessmentRecord {
  final String id;
  final String date;
  final String status; // 'Rendah' | 'Sedang' | 'Tinggi'
  final String glucoseLevel;
  final String scoreDescription;
  final String recommendation;
  final String bmi;
  final String bloodPressure;
  final String familyHistory;
  final String physicalActivity;

  const RiskAssessmentRecord({
    required this.id,
    required this.date,
    required this.status,
    required this.glucoseLevel,
    required this.scoreDescription,
    required this.recommendation,
    this.bmi = '22.4 kg/m² (Normal)',
    this.bloodPressure = '120/80 mmHg',
    this.familyHistory = 'Tidak Ada',
    this.physicalActivity = 'Rutin (> 3x seminggu)',
  });
}

class RiwayatRisikoScreen extends StatefulWidget {
  const RiwayatRisikoScreen({super.key});

  @override
  State<RiwayatRisikoScreen> createState() => _RiwayatRisikoScreenState();
}

class _RiwayatRisikoScreenState extends State<RiwayatRisikoScreen> {
  int _selectedCategoryIndex = 0; // 0 = 'Cek Risiko AI'
  final int _selectedBottomNavIndex = 0; // 0 = Home / Dashboard

  final List<String> _categories = const [
    'Cek Risiko AI',
    'Konsultasi',
    'Resep',
  ];

  final List<RiskAssessmentRecord> _records = const [
    RiskAssessmentRecord(
      id: 'RSK-2026-001',
      date: '20 Mei 2026',
      status: 'Rendah',
      glucoseLevel: 'Kadar Gula: 98 mg/dL',
      scoreDescription: 'Skor Risiko: 8% • Kategori Rendah',
      recommendation:
          'Pertahankan pola makan sehat, hidrasi cukup, dan olahraga rutin minimal 30 menit sehari.',
      bmi: '21.8 kg/m² (Ideal)',
      bloodPressure: '118/76 mmHg',
      familyHistory: 'Tidak ada riwayat diabetes',
      physicalActivity: 'Aktif (4x / minggu)',
    ),
    RiskAssessmentRecord(
      id: 'RSK-2026-002',
      date: '14 Maret 2026',
      status: 'Sedang',
      glucoseLevel: 'Kadar Gula: 135 mg/dL',
      scoreDescription: 'Skor Risiko: 42% • Kategori Sedang',
      recommendation:
          'Kurangi konsumsi gula dan karbohidrat sederhana. Perbanyak serat serta jadwalkan kontrol ulang 1 bulan lagi.',
      bmi: '25.6 kg/m² (Kelebihan BB ringan)',
      bloodPressure: '128/84 mmHg',
      familyHistory: 'Ada pada garis keluarga tingkat 1',
      physicalActivity: 'Jarang (1x / minggu)',
    ),
    RiskAssessmentRecord(
      id: 'RSK-2026-003',
      date: '10 Januari 2026',
      status: 'Tinggi',
      glucoseLevel: 'Kadar Gula: 185 mg/dL',
      scoreDescription: 'Skor Risiko: 76% • Kategori Tinggi',
      recommendation:
          'Segera konsultasikan dengan dokter spesialis penyakit dalam untuk evaluasi terapi obat dan tes laboratorium lanjutan.',
      bmi: '28.2 kg/m² (Obesitas tingkat 1)',
      bloodPressure: '138/90 mmHg',
      familyHistory: 'Orang tua dengan riwayat diabetes tipe 2',
      physicalActivity: 'Sangat jarang / pasif',
    ),
  ];

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'rendah':
        return const Color(0xFFE2F8E7);
      case 'sedang':
        return const Color(0xFFFEF7D6);
      case 'tinggi':
        return const Color(0xFFFDECEE);
      default:
        return const Color(0xFFEEEEEE);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'rendah':
        return const Color(0xFF1B8738);
      case 'sedang':
        return const Color(0xFFB45309);
      case 'tinggi':
        return const Color(0xFFBA171E);
      default:
        return const Color(0xFF757575);
    }
  }

  void _onCategoryTap(int index) {
    if (index == _selectedCategoryIndex) return;

    if (index == 1) {
      // Konsultasi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ConsultationListScreen(),
        ),
      );
    } else if (index == 2) {
      // Resep
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RiwayatResepScreen(),
        ),
      );
    } else {
      setState(() {
        _selectedCategoryIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA171E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Riwayat Cek Risiko',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Horizontal Category Tabs/Chips
          _buildCategoryTabs(),

          // 2. Risk Assessment Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _records.length,
              itemBuilder: (context, index) {
                final record = _records[index];
                return _buildRiskCard(record);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Horizontal scrollable tabs row: Cek Risiko AI, Konsultasi, Resep
  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_categories.length, (index) {
            final title = _categories[index];
            final isSelected = _selectedCategoryIndex == index;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => _onCategoryTap(index),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7D0E12) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7D0E12),
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF7D0E12),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Card item for each risk check record
  Widget _buildRiskCard(RiskAssessmentRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD64D52),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date on left, Status badge on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Date with red calendar icon
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 20,
                    color: Color(0xFFBA171E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.date,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                ],
              ),

              // Status / Level Risiko Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusBgColor(record.status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  record.status,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _getStatusTextColor(record.status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Inner box for summary result & recommendation
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD64D52),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Result summary row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      // Blood drop / glucose icon
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDECEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Color(0xFFBA171E),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.glucoseLevel,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              record.scoreDescription,
                              style: GoogleFonts.poppins(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF616161),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF3D5D5),
                ),

                // 2. Brief recommendation row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B1317),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.recommendation,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // "Lihat Detail" Button
          InkWell(
            onTap: () => _showRecordDetail(record),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFBA171E),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B1317),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF8B1317),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Detail Bottom Sheet for full risk evaluation
  void _showRecordDetail(RiskAssessmentRecord record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0D0D0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rincian Cek Risiko AI',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B1317),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBgColor(record.status),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        record.status,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getStatusTextColor(record.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'ID: ${record.id} • Tanggal: ${record.date}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0DEDE)),
                const SizedBox(height: 14),
                _buildDetailRow('Kadar Gula Darah', record.glucoseLevel.replaceFirst('Kadar Gula: ', '')),
                _buildDetailRow('Skor Penilaian Risiko', record.scoreDescription),
                _buildDetailRow('Indeks Massa Tubuh (BMI)', record.bmi),
                _buildDetailRow('Tekanan Darah', record.bloodPressure),
                _buildDetailRow('Riwayat Diabetes Keluarga', record.familyHistory),
                _buildDetailRow('Aktivitas Fisik', record.physicalActivity),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7F7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF3D5D5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rekomendasi Medis:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8B1317),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.recommendation,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.4,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBA171E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
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
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF666666),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E1E),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar matching other screens
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFF6ECEB),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationListScreen(),
                ),
              );
            },
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedBottomNavIndex == index;
    final color =
        isSelected ? const Color(0xFFBA171E) : const Color(0xFFD65C62);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 26,
          color: color,
        ),
      ),
    );
  }
}
