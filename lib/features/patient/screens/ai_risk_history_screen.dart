import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/risk_assessment_model.dart';
import 'risk_detail_screen.dart';

/// Halaman Riwayat Cek Risiko AI
/// Menampilkan tab filter horizontal, info banner disclaimers, dan daftar card riwayat dinamis.
class AiRiskHistoryScreen extends StatefulWidget {
  const AiRiskHistoryScreen({super.key});

  @override
  State<AiRiskHistoryScreen> createState() => _AiRiskHistoryScreenState();
}

class _AiRiskHistoryScreenState extends State<AiRiskHistoryScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = [
    'Cek Risiko AI',
    'Konsultasi',
    'Monitoring',
    'Resep',
  ];

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
          'Riwayat Cek Risiko AI',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Horizontal Tab Bar
            _buildHorizontalTabBar(),

            // 2. Tab Content (Cek Risiko AI / Placeholder Tab Lain)
            Expanded(
              child: _selectedTabIndex == 0
                  ? _buildRiskHistoryList()
                  : _buildPlaceholderTabContent(_tabs[_selectedTabIndex]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Horizontal Tab Bar dengan 4 Tab berbentuk Pill
  Widget _buildHorizontalTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            final isSelected = _selectedTabIndex == index;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedTabIndex = index),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? RiskColors.maroonPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: RiskColors.maroonPrimary,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    _tabs[index],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : RiskColors.maroonPrimary,
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

  /// Tampilan Utama Tab "Cek Risiko AI"
  Widget _buildRiskHistoryList() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      children: [
        // Info Banner
        _buildInfoBanner(),

        const SizedBox(height: 14),

        // List Riwayat Card (Dinamis dari array dummyRiskAssessments)
        ...dummyRiskAssessments.map((assessment) => _buildRiskAssessmentCard(assessment)),

        const SizedBox(height: 16),
      ],
    );
  }

  /// Banner Disclaimer Hasil Risiko AI
  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: RiskColors.infoBannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RiskColors.infoBannerBorder, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Color(0xFF0284C7),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: RiskColors.infoBannerText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hasil ini adalah risiko AI berdasarkan data yang Anda input, bukan diagnosis medis final.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.4,
                    color: const Color(0xFF0369A1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card Item Riwayat Pemeriksaan Risiko AI
  Widget _buildRiskAssessmentCard(RiskAssessmentModel assessment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RiskColors.cardBorderPink, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Tanggal, Jam & Badge Skor + Kategori
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tanggal & Jam
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
                      size: 15,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      Text(
                        assessment.time,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Badges Skor & Kategori
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Skor Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: assessment.level.badgeBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: assessment.level.badgeBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${assessment.score}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: assessment.level.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Kategori Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: assessment.level.badgeBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: assessment.level.badgeBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      assessment.level.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: assessment.level.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Faktor Risiko
          Text(
            'Faktor Risiko',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            assessment.formattedFactors,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Outline "Lihat Detail >"
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiskDetailScreen(assessment: assessment),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: RiskColors.maroonPrimary,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: RiskColors.maroonPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: RiskColors.maroonPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder untuk Tab Konsultasi, Monitoring, dan Resep
  Widget _buildPlaceholderTabContent(String tabTitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF1F1),
                shape: BoxShape.circle,
                border: Border.all(color: RiskColors.cardBorderPink),
              ),
              child: const Icon(
                Icons.folder_open_rounded,
                size: 44,
                color: RiskColors.maroonPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Riwayat $tabTitle',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Belum ada riwayat $tabTitle yang tercatat saat ini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Persistent Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
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
            onTap: () => Navigator.pop(context),
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
            isSelected: true,
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
