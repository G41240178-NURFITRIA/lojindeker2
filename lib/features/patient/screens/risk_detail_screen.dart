import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

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
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
          ),
        ),
      ],
    );
  }

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
    final color = isSelected ? _primaryRed : const Color(0xFFD65C62);

    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 0) {
          // Kembali ke Dashboard utama jika menekan ikon Home
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
