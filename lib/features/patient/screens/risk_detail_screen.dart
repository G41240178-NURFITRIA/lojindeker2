import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RiskDetailScreen extends StatefulWidget {
  final double weight;
  final double height;
  final double imt;
  final String imtCategory;
  final int age;
  final String gender;
  final bool familyHistory;
  final bool smokingHistory;
  final bool hypertensionHistory;
  final bool cardiovascularHistory;

  const RiskDetailScreen({
    super.key,
    required this.weight,
    required this.height,
    required this.imt,
    required this.imtCategory,
    required this.age,
    required this.gender,
    required this.familyHistory,
    required this.smokingHistory,
    required this.hypertensionHistory,
    required this.cardiovascularHistory,
  });

  @override
  State<RiskDetailScreen> createState() => _RiskDetailScreenState();
}

class _RiskDetailScreenState extends State<RiskDetailScreen> {
  int _selectedTabIndex = 0;

  /// Hitung total skor risiko 0 - 100
  int get calculatedScore {
    int score = 0;

    // 1. Riwayat Keluarga (max 20)
    if (widget.familyHistory) score += 20;

    // 2. IMT (max 25)
    if (widget.imt >= 25.0) {
      score += 25;
    } else if (widget.imt >= 23.0) {
      score += 12;
    }

    // 3. Riwayat Hipertensi (max 15)
    if (widget.hypertensionHistory) score += 15;

    // 4. Riwayat Kardiovaskuler (max 10)
    if (widget.cardiovascularHistory) score += 10;

    // 5. Merokok (max 10)
    if (widget.smokingHistory) score += 10;

    // 6. Usia (max 20)
    if (widget.age >= 65) {
      score += 20;
    } else if (widget.age >= 55) {
      score += 16;
    } else if (widget.age >= 45) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final score = calculatedScore;

    // Tentukan kategori & saran
    final String riskTitle;
    final String riskDescription;
    final Color riskTextColor;

    if (score < 30) {
      riskTitle = 'Risiko Rendah:';
      riskDescription =
          'Pertahankan gaya hidup sehat Anda. Lanjutkan olahraga rutin dan pola makan seimbang.';
      riskTextColor = const Color(0xFF1B5E20); // Hijau pekat
    } else if (score <= 60) {
      riskTitle = 'Risiko Sedang:';
      riskDescription =
          'Perhatikan asupan gula dan karbohidrat olahan. Tingkatkan aktivitas fisik dan pantau gula darah berkala.';
      riskTextColor = const Color(0xFFE65100); // Oranye
    } else {
      riskTitle = 'Risiko Tinggi:';
      riskDescription =
          'Terdapat indikator risiko signifikan. Sangat disarankan berkonsultasi dengan dokter untuk cek gula darah (HbA1c).';
      riskTextColor = const Color(0xFFC62828); // Merah
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAF2F2),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kartu Skor Risiko Saat Ini
              _buildScoreCard(
                score: score,
                riskTitle: riskTitle,
                riskDescription: riskDescription,
                riskTextColor: riskTextColor,
              ),
              const SizedBox(height: 20),

              // 2. Kartu Prediksi Kontribusi Faktor
              _buildFactorsCard(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// AppBar dengan tombol kembali `<` dan judul "Detail Risiko Diabetes"
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAF2F2),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF222222),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detail Risiko Diabetes',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF222222),
        ),
      ),
      centerTitle: false,
    );
  }

  /// Kartu Skor Risiko Saat Ini
  Widget _buildScoreCard({
    required int score,
    required String riskTitle,
    required String riskDescription,
    required Color riskTextColor,
  }) {
    // Normalisasi posisi marker pada slider bar (0.0 sampai 1.0)
    final double markerPercent = (score / 100.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E3E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skor Risiko Saat Ini',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$score / 100',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 14),

          // Spectrum Bar dengan Marker
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              const markerWidth = 4.0;
              final markerLeft = (barWidth - markerWidth) * markerPercent;

              return SizedBox(
                height: 12,
                child: Stack(
                  children: [
                    // Gradien bar
                    Container(
                      width: barWidth,
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFA5D6A7), // Hijau muda
                            Color(0xFFC8E6C9),
                            Color(0xFFFFF59D), // Kuning
                            Color(0xFFFFCC80), // Oranye
                            Color(0xFFEF9A9A), // Merah muda
                            Color(0xFFE57373), // Merah
                            Color(0xFFC62828), // Merah gelap
                          ],
                        ),
                      ),
                    ),
                    // Marker penunjuk hitam
                    Positioned(
                      left: markerLeft,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: markerWidth,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // Label Rendah, Sedang, Tinggi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rendah',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              Text(
                'Sedang',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFB8C00),
                ),
              ),
              Text(
                'Tinggi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC62828),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Kotak Info Rekomendasi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFBE8E8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Color(0xFF8D4046),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$riskTitle ',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: riskTextColor,
                            height: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: riskDescription,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: riskTextColor,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu Prediksi Kontribusi Faktor
  Widget _buildFactorsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E3E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prediksi Kontribusi Faktor',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A2A2A),
            ),
          ),
          const SizedBox(height: 14),

          // Faktor-faktor
          _buildFactorRow(
            title: 'Riwayat',
            isPositive: !widget.familyHistory,
          ),
          const SizedBox(height: 12),

          _buildFactorRow(
            title: 'BMI',
            isPositive: widget.imt < 25.0,
          ),
          const SizedBox(height: 12),

          _buildFactorRow(
            title: 'Riwayat Hipertensi',
            isPositive: !widget.hypertensionHistory,
          ),
          const SizedBox(height: 12),

          _buildFactorRow(
            title: 'Riwayat Kardiovaskuler',
            isPositive: !widget.cardiovascularHistory,
          ),
          const SizedBox(height: 12),

          _buildFactorRow(
            title: 'Merokok',
            isPositive: !widget.smokingHistory,
          ),
          const SizedBox(height: 12),

          _buildFactorRow(
            title: 'Usia',
            isPositive: widget.age < 55,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Baris item faktor dengan titik indikator hijau/oranye/merah
  Widget _buildFactorRow({
    required String title,
    required bool isPositive,
  }) {
    // Hijau jika risiko rendah/normal
    final dotColor = isPositive ? const Color(0xFF2E7D32) : const Color(0xFFE53935);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF555555),
          ),
        ),
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 60,
      color: const Color(0xFFFAF1F1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined),
          _buildNavItem(1, Icons.chat_bubble_outline_rounded),
          _buildNavItem(2, Icons.person_outline_rounded),
          _buildNavItem(3, Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? const Color(0xFFBA171E) : const Color(0xFFD65C62);

    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 0) {
          // Navigasi kembali ke Dashboard jika ikon home ditekan
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 24,
          color: color,
        ),
      ),
    );
  }
}
