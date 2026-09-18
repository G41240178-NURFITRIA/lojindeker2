import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class RiskCheckScreen extends StatefulWidget {
  const RiskCheckScreen({super.key});

  @override
  State<RiskCheckScreen> createState() => _RiskCheckScreenState();
}

class _RiskCheckScreenState extends State<RiskCheckScreen> {
  // Controllers
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Selected states
  double? _calculatedImt;
  String? _imtCategory;

  bool? _familyHistory; // true = Ya, false = Tidak
  String? _gender; // 'Laki-Laki' or 'Perempuan'
  bool? _smokingHistory; // true = Ya, false = Tidak
  bool? _hypertensionHistory; // true = Ya, false = Tidak
  bool? _cardiovascularHistory; // true = Ya, false = Tidak

  // Style constants
  static const Color _primaryMaroon = Color(0xFF6B181C);
  static const Color _cardMaroon = Color(0xFF7B2024);
  static const Color _lightBg = Color(0xFFFFF9F9);
  static const Color _softPinkCard = Color(0xFFFFF6F6);
  static const Color _softPinkBorder = Color(0xFFFBECEC);
  static const Color _inputBorder = Color(0xFFF2D8D8);
  static const Color _inputFocusedBorder = Color(0xFF6B181C);
  static const Color _resultCardBg = Color(0xFFFDF1F1);
  static const Color _resultCardBorder = Color(0xFFFCDDDD);

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// Hitung IMT (Indeks Massa Tubuh)
  /// IMT = BB (kg) / (TB (m) * TB (m))
  void _calculateImt() {
    final weightText = _weightController.text.trim().replaceAll(',', '.');
    final heightText = _heightController.text.trim().replaceAll(',', '.');

    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);

    if (weight == null || height == null || weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mohon masukkan berat badan dan tinggi badan yang valid',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: _cardMaroon,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final heightInMeter = height / 100.0;
    final imt = weight / (heightInMeter * heightInMeter);

    String category;
    if (imt < 18.5) {
      category = 'Kurus';
    } else if (imt < 23.0) {
      category = 'Normal';
    } else if (imt < 25.0) {
      category = 'Kelebihan BB';
    } else {
      category = 'Obesitas';
    }

    setState(() {
      _calculatedImt = imt;
      _imtCategory = category;
    });

    FocusScope.of(context).unfocus();
  }

  /// Reset semua input dan state kuesioner
  void _resetForm() {
    setState(() {
      _weightController.clear();
      _heightController.clear();
      _ageController.clear();
      _calculatedImt = null;
      _imtCategory = null;
      _familyHistory = null;
      _gender = null;
      _smokingHistory = null;
      _hypertensionHistory = null;
      _cardiovascularHistory = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua data telah direset',
          style: GoogleFonts.poppins(fontSize: 12),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Hitung total skor risiko diabetes komprehensif
  void _calculateRiskScore() {
    // Pastikan IMT sudah terhitung jika BB & TB diisi
    if (_calculatedImt == null &&
        _weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty) {
      _calculateImt();
    }

    // Validasi kelengkapan data
    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    if (_calculatedImt == null ||
        age == null ||
        _familyHistory == null ||
        _gender == null ||
        _smokingHistory == null ||
        _hypertensionHistory == null ||
        _cardiovascularHistory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan lengkapi semua pertanyaan sebelum menghitung skor risiko',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          backgroundColor: const Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    int score = 0;

    // 1. Poin IMT (Klasifikasi Asia-Pasifik)
    if (_calculatedImt! >= 25) {
      score += 3;
    } else if (_calculatedImt! >= 23) {
      score += 1;
    }

    // 2. Poin Usia
    if (age >= 65) {
      score += 4;
    } else if (age >= 55) {
      score += 3;
    } else if (age >= 45) {
      score += 2;
    } else {
      score += 0;
    }

    // 3. Poin Riwayat Keluarga
    if (_familyHistory == true) {
      score += 4;
    }

    // 4. Poin Jenis Kelamin (Laki-laki sedikit berisiko lebih tinggi)
    if (_gender == 'Laki-Laki') {
      score += 1;
    }

    // 5. Poin Merokok
    if (_smokingHistory == true) {
      score += 2;
    }

    // 6. Poin Hipertensi
    if (_hypertensionHistory == true) {
      score += 2;
    }

    // 7. Poin Kardiovaskuler
    if (_cardiovascularHistory == true) {
      score += 2;
    }

    // Tentukan tingkat risiko
    String riskLevel;
    Color riskColor;
    String riskPercentage;
    String recommendation;

    if (score < 7) {
      riskLevel = 'Risiko Rendah';
      riskColor = const Color(0xFF2E7D32); // Hijau
      riskPercentage = 'Hanya ~1% kemungkinan diabetes';
      recommendation =
          'Kondisi Anda sangat baik! Pertahankan pola makan sehat bergizi seimbang, hindari konsumsi gula berlebih, dan lakukan olahraga teratur minimal 150 menit per minggu.';
    } else if (score <= 11) {
      riskLevel = 'Risiko Sedang';
      riskColor = const Color(0xFFE65100); // Oranye
      riskPercentage = '~4% kemungkinan diabetes';
      recommendation =
          'Anda memiliki beberapa indikator risiko. Disarankan untuk mulai membatasi makanan tinggi gula dan karbohidrat olahan, aktif bergerak, serta cek gula darah rutin setahun sekali.';
    } else if (score <= 14) {
      riskLevel = 'Risiko Tinggi';
      riskColor = const Color(0xFFD84315); // Oranye tua
      riskPercentage = '~17% kemungkinan diabetes';
      recommendation =
          'Terdapat faktor risiko signifikan. Sebaiknya Anda berkonsultasi dengan tenaga medis untuk tes gula darah puasa (GDP) dan menerapkan diet ketat rendah indeks glikemik.';
    } else {
      riskLevel = 'Risiko Sangat Tinggi';
      riskColor = const Color(0xFFC62828); // Merah
      riskPercentage = '33% - 50% kemungkinan diabetes';
      recommendation =
          'Skor Anda menunjukkan risiko yang sangat tinggi. Sangat dianjurkan segera melakukan pemeriksaan komprehensif ke dokter atau laboratorium (HbA1c) untuk deteksi dini.';
    }

    _showResultDialog(
      score: score,
      riskLevel: riskLevel,
      riskColor: riskColor,
      riskPercentage: riskPercentage,
      recommendation: recommendation,
    );
  }

  /// Dialog hasil perhitungan skor risiko
  void _showResultDialog({
    required int score,
    required String riskLevel,
    required Color riskColor,
    required String riskPercentage,
    required String recommendation,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Hasil Analisis Risiko Diabetes',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),
              const SizedBox(height: 16),

              // Status Badge Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      riskLevel,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: riskColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Skor: $score Poin • $riskPercentage',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Detail IMT & Usia
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniMetric(
                      'IMT',
                      _calculatedImt?.toStringAsFixed(1) ?? '-',
                      _imtCategory ?? '-',
                    ),
                    Container(height: 28, width: 1, color: Colors.grey.shade300),
                    _buildMiniMetric('Usia', '${_ageController.text} th', 'Tahun'),
                    Container(height: 28, width: 1, color: Colors.grey.shade300),
                    _buildMiniMetric('Gender', _gender ?? '-', ''),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Rekomendasi
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rekomendasi Medis & Gaya Hidup:',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF222222),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                recommendation,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF555555),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),

              // Tombol Tutup
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryMaroon,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tutup & Simpan Catatan',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
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

  Widget _buildMiniMetric(String label, String value, String sub) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF888888)),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF222222),
          ),
        ),
        if (sub.isNotEmpty)
          Text(
            sub,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _primaryMaroon,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner Card: Kuisioner Gaya Hidup & Riwayat
              _buildTopBanner(),
              const SizedBox(height: 20),

              // 1. Indeks Massa Tubuh (IMT) / Berat Badan
              _buildQuestionTitle('1. Indeks Massa Tubuh (IMT) / Berat Badan'),
              const SizedBox(height: 10),

              _buildFieldLabel('Berat Badan (kg)'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _weightController,
                hintText: 'Contoh: 65',
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Tinggi Badan (cm)'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _heightController,
                hintText: 'Contoh: 170',
              ),
              const SizedBox(height: 14),

              // Action Row: Hitung IMT Button & Result Box
              _buildImtActionRow(),
              const SizedBox(height: 24),

              // 2. Riwayat Keluarga
              _buildQuestionTitle('2. Riwayat Keluarga'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _familyHistory,
                onChanged: (val) => setState(() => _familyHistory = val),
              ),
              const SizedBox(height: 24),

              // 3. Usia
              _buildQuestionTitle('3. Usia'),
              const SizedBox(height: 10),
              _buildInputField(
                controller: _ageController,
                hintText: 'Contoh: 45',
              ),
              const SizedBox(height: 24),

              // 4. Jenis Kelamin
              _buildQuestionTitle('4. Jenis Kelamin'),
              const SizedBox(height: 10),
              _buildGenderToggle(),
              const SizedBox(height: 24),

              // 5. Riwayat Merokok
              _buildQuestionTitle('5. Riwayat Merokok'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _smokingHistory,
                onChanged: (val) => setState(() => _smokingHistory = val),
              ),
              const SizedBox(height: 24),

              // 6. Riwayat Hipertensi
              _buildQuestionTitle('6. Riwayat Hipertensi'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _hypertensionHistory,
                onChanged: (val) => setState(() => _hypertensionHistory = val),
              ),
              const SizedBox(height: 24),

              // 7. Riwayat Kardiovaskuler
              _buildQuestionTitle('7. Riwayat Kardiovaskuler'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _cardiovascularHistory,
                onChanged: (val) => setState(() => _cardiovascularHistory = val),
              ),
              const SizedBox(height: 28),

              // Footer: Reset Text Button
              Center(
                child: InkWell(
                  onTap: _resetForm,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Reset',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Main Button: Hitung Skor Risiko ➔
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// AppBar dengan tombol kembali `<` dan judul "Cek Risiko"
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _lightBg,
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
        'Cek Risiko',
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF222222),
        ),
      ),
      centerTitle: false,
    );
  }

  /// Banner atas "Kuisioner Gaya Hidup & Riwayat"
  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _softPinkCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _softPinkBorder),
      ),
      child: Text(
        'Kuisioner Gaya Hidup &\nRiwayat',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF333333),
          height: 1.35,
        ),
      ),
    );
  }

  /// Judul pertanyaan (misal: "1. Indeks Massa Tubuh (IMT) / Berat Badan")
  Widget _buildQuestionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2A2A2A),
      ),
    );
  }

  /// Label input (misal: "Berat Badan (kg)")
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF555555),
      ),
    );
  }

  /// Input text field dengan border merah muda lembut
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
        ],
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF222222),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFBDBDBD),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _inputBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _inputFocusedBorder, width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFFFDFC),
        ),
      ),
    );
  }

  /// Tombol "Hitung IMT" berdampingan dengan kotak "HASIL IMT / IMT Anda: -"
  Widget _buildImtActionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tombol Hitung IMT
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _calculateImt,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cardMaroon,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Hitung IMT',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Kotak Hasil IMT
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _resultCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _resultCardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'HASIL IMT',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF888888),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _calculatedImt == null
                      ? 'IMT Anda: -'
                      : 'IMT Anda: ${_calculatedImt!.toStringAsFixed(1)} ($_imtCategory)',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: _cardMaroon,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Opsi pilihan Ya / Tidak dengan ikon centang & silang
  Widget _buildYesNoToggle({
    required bool? currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        // Opsi "Ya"
        Expanded(
          child: _buildChoiceButton(
            title: 'Ya',
            icon: Icons.check_circle_outline_rounded,
            isSelected: currentValue == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 14),

        // Opsi "Tidak"
        Expanded(
          child: _buildChoiceButton(
            title: 'Tidak',
            icon: Icons.highlight_off_rounded,
            isSelected: currentValue == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }

  /// Opsi pilihan Jenis Kelamin: Laki-Laki / Perempuan
  Widget _buildGenderToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceButton(
            title: 'Laki-Laki',
            isSelected: _gender == 'Laki-Laki',
            onTap: () => setState(() => _gender = 'Laki-Laki'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildChoiceButton(
            title: 'Perempuan',
            isSelected: _gender == 'Perempuan',
            onTap: () => setState(() => _gender = 'Perempuan'),
          ),
        ),
      ],
    );
  }

  /// Komponen tombol pilihan kartu (Ya, Tidak, Laki-Laki, Perempuan)
  Widget _buildChoiceButton({
    required String title,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF6F6) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _cardMaroon : _inputBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 19,
                  color: isSelected ? _cardMaroon : const Color(0xFF4A4A4A),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _cardMaroon : const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol utama "Hitung Skor Risiko ➔"
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _calculateRiskScore,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryMaroon,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: _primaryMaroon.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hitung Skor Risiko',
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}
