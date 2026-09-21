import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/risk_assessment_model.dart';

/// Halaman Detail Cek Risiko - Komponen Dinamis & Reusable
/// Menerima objek [assessment] dan menyesuaikan seluruh data, warna,
/// tabel, chip faktor dominan, serta box rekomendasi berdasarkan data tersebut.
class RiskDetailScreen extends StatelessWidget {
  final RiskAssessmentModel assessment;

  const RiskDetailScreen({
    super.key,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: RiskColors.maroonPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detail Cek Risiko',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Tanggal & Status Badge
              _buildDateAndStatusHeader(),

              const SizedBox(height: 16),

              // 2. Card Skor Risiko
              _buildScoreCard(),

              const SizedBox(height: 20),

              // 3. Tabel Data yang Diinput
              _buildInputDataTable(),

              const SizedBox(height: 20),

              // 4. Section Faktor Risiko Dominan
              _buildDominantFactorsSection(),

              const SizedBox(height: 20),

              // 5. Box Rekomendasi
              _buildRecommendationBox(context),

              // 6. Tombol CTA Khusus Kategori Tinggi
              if (assessment.level == RiskLevel.tinggi) ...[
                const SizedBox(height: 20),
                _buildConsultationCtaButton(context),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  /// Header tanggal pemeriksaan & badge level risiko
  Widget _buildDateAndStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: RiskColors.maroonPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assessment.date,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  assessment.time,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Status Badge (Rendah / Sedang / Tinggi)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: assessment.level.badgeBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: assessment.level.badgeBorderColor,
              width: 1,
            ),
          ),
          child: Text(
            assessment.level.label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: assessment.level.color,
            ),
          ),
        ),
      ],
    );
  }

  /// Card Skor Risiko di tengah
  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3C7CB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Skor Risiko',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${assessment.score}',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: assessment.level.color,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'dari skala 0-100',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  /// Tabel Data yang Diinput
  Widget _buildInputDataTable() {
    final rows = [
      {'label': 'Usia', 'value': assessment.age},
      {'label': 'Pola Makan', 'value': assessment.diet},
      {'label': 'Aktivitas Fisik', 'value': assessment.physicalActivity},
      {'label': 'Riwayat Keluarga', 'value': assessment.familyHistory},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data yang Diinput',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            children: List.generate(rows.length, (index) {
              final row = rows[index];
              final isLast = index == rows.length - 1;

              return Container(
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                        ),
                ),
                child: Row(
                  children: [
                    // Label Column
                    Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      child: Text(
                        row['label']!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFE5E7EB),
                    ),
                    // Value Column
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        child: Text(
                          row['value']!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  /// Section Faktor Risiko Dominan
  Widget _buildDominantFactorsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Faktor Risiko Dominan',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: assessment.dominantFactors.map((factor) {
            final isHighlighted = factor.isHighlighted;

            Color bgColor;
            Color borderColor;
            Color textColor;

            if (isHighlighted) {
              if (assessment.level == RiskLevel.sedang) {
                bgColor = const Color(0xFFFEF3C7);
                borderColor = const Color(0xFFFDE68A);
                textColor = const Color(0xFFB45309);
              } else {
                bgColor = const Color(0xFFFEE2E2);
                borderColor = const Color(0xFFFECACA);
                textColor = const Color(0xFFDC2626);
              }
            } else {
              bgColor = const Color(0xFFF3F4F6);
              borderColor = const Color(0xFFE5E7EB);
              textColor = const Color(0xFF4B5563);
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Text(
                factor.name,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Box Rekomendasi
  Widget _buildRecommendationBox(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: assessment.level.recommendationBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: assessment.level.recommendationBorderColor,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                assessment.level.recommendationIcon,
                color: assessment.level.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Rekomendasi',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: assessment.level.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            assessment.level.recommendationText,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol CTA "Konsultasi Dokter Sekarang" (Hanya untuk Kategori Tinggi)
  Widget _buildConsultationCtaButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiskColors.maroonPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Mengarahkan ke layanan Konsultasi Dokter...',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: RiskColors.maroonPrimary,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Text(
          'Konsultasi Dokter Sekarang',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Bottom Navigation Bar Persisten
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 64,
      color: RiskColors.scaffoldBg,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            isSelected: false,
            onTap: () {
              // Navigasi kembali ke Beranda (pop hingga dashboard)
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          _buildNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            isSelected: false,
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            isSelected: false,
            onTap: () {},
          ),
          _buildNavItem(
            icon: Icons.calendar_month_outlined,
            isSelected: true, // Tab Riwayat aktif
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xFFBA171E) : const Color(0xFFD65C62);

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
