import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/risk_assessment_model.dart';

/// Halaman Detail Cek Risiko - Komponen Dinamis & Reusable
/// Menerima objek [assessment] dan menyesuaikan seluruh data, warna,
/// tabel, chip faktor dominan, serta box rekomendasi berdasarkan data tersebut.
class RiskDetailScreen extends StatelessWidget {
  final RiskAssessmentModel assessment;

  const RiskDetailScreen({
    super.key,
<<<<<<< HEAD
    this.weight = 65,
    this.height = 170,
    this.imt = 22.5,
    this.imtCategory = 'Normal',
    this.age = 45,
    this.gender = 'Laki-Laki',
    this.familyHistory = false,
    this.smokingHistory = false,
    this.hypertensionHistory = false,
    this.cardiovascularHistory = false,
  });

  @override
  State<RiskDetailScreen> createState() => _RiskDetailScreenState();
}

class _RiskDetailScreenState extends State<RiskDetailScreen> {
  int _selectedTabIndex = 0;

  // Theme Constants
  static const Color _primaryRed = Color(0xFFE53935); // Merah tema #E53935
  static const Color _bgScreen = Color(0xFFFAF4F4); // Latar belakang halus modern

  /// Hitung total skor risiko diabetes (rentang 0 - 100)
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

    // Tentukan konfigurasi notifikasi berdasarkan level risiko
    final String riskTitle;
    final String riskDescription;
    final Color notifBgColor;
    final Color notifBorderColor;
    final Color notifIconColor;
    final Color notifTextColor;

    if (score < 30) {
      // Risiko Rendah -> Box notifikasi hijau muda
      riskTitle = 'Risiko Rendah: ';
      riskDescription =
          'Pertahankan gaya hidup sehat Anda. Lanjutkan olahraga rutin dan pola makan seimbang.';
      notifBgColor = const Color(0xFFE8F5E9); // Hijau muda lembut
      notifBorderColor = const Color(0xFFC8E6C9);
      notifIconColor = const Color(0xFF2E7D32);
      notifTextColor = const Color(0xFF1B5E20);
    } else if (score <= 60) {
      // Risiko Sedang -> Box notifikasi oranye/kuning muda
      riskTitle = 'Risiko Sedang: ';
      riskDescription =
          'Perhatikan asupan gula dan karbohidrat olahan. Tingkatkan aktivitas fisik dan pantau gula darah berkala.';
      notifBgColor = const Color(0xFFFFF3E0); // Oranye muda lembut
      notifBorderColor = const Color(0xFFFFE0B2);
      notifIconColor = const Color(0xFFE65100);
      notifTextColor = const Color(0xFFBF360C);
    } else {
      // Risiko Tinggi -> Box notifikasi merah muda
      riskTitle = 'Risiko Tinggi: ';
      riskDescription =
          'Terdapat indikator risiko signifikan. Sangat disarankan berkonsultasi dengan dokter untuk cek gula darah (HbA1c).';
      notifBgColor = const Color(0xFFFFEBEE); // Merah muda lembut
      notifBorderColor = const Color(0xFFFFCDD2);
      notifIconColor = const Color(0xFFC62828);
      notifTextColor = const Color(0xFFB71C1C);
    }

    return Scaffold(
      backgroundColor: _bgScreen,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Card Putih: Skor Risiko Saat Ini
              _buildScoreCard(
                score: score,
                riskTitle: riskTitle,
                riskDescription: riskDescription,
                notifBgColor: notifBgColor,
                notifBorderColor: notifBorderColor,
                notifIconColor: notifIconColor,
                notifTextColor: notifTextColor,
              ),
              const SizedBox(height: 18),

              // 2. Card Putih: Prediksi Kontribusi Faktor
              _buildFactorsCard(),
=======
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

>>>>>>> 22ff46862068b9a56aae931db57db9f0a592124a
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

<<<<<<< HEAD
  /// Header merah (#E53935) + tombol back, judul "Detail Risiko Diabetes"
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryRed,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: _primaryRed,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detail Risiko Diabetes',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
    );
  }

  /// Card putih: "Skor Risiko Saat Ini" dengan progress bar gradasi & indicator dot
  Widget _buildScoreCard({
    required int score,
    required String riskTitle,
    required String riskDescription,
    required Color notifBgColor,
    required Color notifBorderColor,
    required Color notifIconColor,
    required Color notifTextColor,
  }) {
    // Posisi dot indikator (0.0 sampai 1.0)
    final double markerPercent = (score / 100.0).clamp(0.0, 1.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E3E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul card
          Text(
            'Skor Risiko Saat Ini',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 6),

          // Teks skor besar "0 / 100" (atau skor aktual hasil kalkulasi)
          Text(
            '$score / 100',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 16),

          // Progress bar gradasi horizontal (hijau -> kuning -> merah)
          // dengan indicator dot di posisi skor
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              const barHeight = 10.0;
              const dotSize = 20.0;
              final dotLeft = ((barWidth - dotSize) * markerPercent)
                  .clamp(0.0, barWidth - dotSize);

              return Column(
                children: [
                  SizedBox(
                    height: 22,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.centerLeft,
                      children: [
                        // Bar gradasi horizontal
                        Container(
                          width: barWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4CAF50), // Hijau
                                Color(0xFF81C784),
                                Color(0xFFFFEE58), // Kuning
                                Color(0xFFFFA726), // Oranye
                                Color(0xFFE53935), // Merah
                                Color(0xFFB71C1C), // Merah gelap
                              ],
                              stops: [0.0, 0.2, 0.45, 0.7, 0.9, 1.0],
                            ),
                          ),
                        ),

                        // Indicator dot di posisi skor
                        Positioned(
                          left: dotLeft,
                          child: Container(
                            width: dotSize,
                            height: dotSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFF212121),
                                width: 3.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: score < 30
                                      ? const Color(0xFF2E7D32)
                                      : (score <= 60
                                          ? const Color(0xFFEF6C00)
                                          : const Color(0xFFE53935)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Label: "Rendah" (kiri), "Sedang" (tengah), "Tinggi" (kanan)
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
                          color: const Color(0xFFEF6C00),
                        ),
                      ),
                      Text(
                        'Tinggi',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE53935),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Box notifikasi (menyesuaikan level risiko hasil perhitungan)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: notifBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: notifBorderColor, width: 1.0),
=======
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
>>>>>>> 22ff46862068b9a56aae931db57db9f0a592124a
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
<<<<<<< HEAD
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: notifIconColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: riskTitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: notifTextColor,
                            height: 1.45,
                          ),
                        ),
                        TextSpan(
                          text: riskDescription,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: notifTextColor,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
=======
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
>>>>>>> 22ff46862068b9a56aae931db57db9f0a592124a
                  ),
                ),
              ],
            ),
          ],
        ),

<<<<<<< HEAD
  /// Card putih: "Prediksi Kontribusi Faktor"
  Widget _buildFactorsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3E3E3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),

          // 1. Riwayat (Riwayat Keluarga)
          _buildFactorRow(
            title: 'Riwayat',
            dotColor: widget.familyHistory
                ? const Color(0xFFE53935) // Merah jika ada riwayat keluarga
                : const Color(0xFF2E7D32), // Hijau jika tidak ada
          ),
          const SizedBox(height: 14),

          // 2. IMT (Indeks Massa Tubuh)
          _buildFactorRow(
            title: 'IMT',
            dotColor: widget.imt < 23.0
                ? const Color(0xFF2E7D32) // Hijau jika normal/kurus
                : (widget.imt < 25.0
                    ? const Color(0xFFFFA000) // Kuning jika kelebihan BB
                    : const Color(0xFFE53935)), // Merah jika obesitas
          ),
          const SizedBox(height: 14),

          // 3. Riwayat Hipertensi
          _buildFactorRow(
            title: 'Riwayat Hipertensi',
            dotColor: widget.hypertensionHistory
                ? const Color(0xFFE53935) // Merah
                : const Color(0xFF2E7D32), // Hijau
          ),
          const SizedBox(height: 14),

          // 4. Riwayat Kardiovaskuler
          _buildFactorRow(
            title: 'Riwayat Kardiovaskuler',
            dotColor: widget.cardiovascularHistory
                ? const Color(0xFFE53935) // Merah
                : const Color(0xFF2E7D32), // Hijau
          ),
          const SizedBox(height: 14),

          // 5. Merokok
          _buildFactorRow(
            title: 'Merokok',
            dotColor: widget.smokingHistory
                ? const Color(0xFFE53935) // Merah
                : const Color(0xFF2E7D32), // Hijau
          ),
          const SizedBox(height: 14),

          // 6. Usia
          _buildFactorRow(
            title: 'Usia',
            dotColor: widget.age < 45
                ? const Color(0xFF2E7D32) // Hijau jika usia < 45
                : (widget.age < 55
                    ? const Color(0xFFFFA000) // Kuning jika 45 - 54
                    : const Color(0xFFE53935)), // Merah jika >= 55
          ),
        ],
      ),
    );
  }

  /// Baris faktor: Nama faktor di kiri, dot indikator (hijau/kuning/merah) di kanan
  Widget _buildFactorRow({
    required String title,
    required Color dotColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF424242),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
=======
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
>>>>>>> 22ff46862068b9a56aae931db57db9f0a592124a
          ),
        ),
      ],
    );
  }

<<<<<<< HEAD
  /// Bottom Navigation Bar 4 ikon: Home, Chat, Profile, Calendar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF6F6),
        border: Border(
          top: BorderSide(color: Color(0xFFFBE8E8), width: 1.0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
=======
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
>>>>>>> 22ff46862068b9a56aae931db57db9f0a592124a
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

<<<<<<< HEAD
  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? _primaryRed : const Color(0xFFD65C62);

    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 0) {
          // Kembali ke Dashboard utama jika menekan ikon Home
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
=======
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
>>>>>>> 22ff46862068b9a56aae931db57db9f0a592124a
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
