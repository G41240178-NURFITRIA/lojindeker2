import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'risk_detail_screen.dart';

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

  // Theme Red (#E53935) & Modern Color Palette
  static const Color _primaryRed = Color(0xFFE53935); // Tema merah utama #E53935
  static const Color _darkRed = Color(0xFF7B181C); // Solid merah gelap
  static const Color _bannerBg = Color(0xFFFFF5F5); // Card banner merah muda
  static const Color _bannerBorder = Color(0xFFFFCDD2); // Border banner merah muda
  static const Color _inputBorder = Color(0xFFE8D0D0); // Border input netral lembut
  static const Color _resultCardBg = Color(0xFFFFF0F0); // Card hasil IMT merah muda
  static const Color _resultCardBorder = Color(0xFFFFCDD2);

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
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: _darkRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
        ),
        backgroundColor: _darkRed,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Hitung total skor risiko diabetes dan buka halaman Detail Risiko
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
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: _primaryRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    final height =
        double.tryParse(_heightController.text.trim().replaceAll(',', '.')) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskDetailScreen(
          weight: weight,
          height: height,
          imt: _calculatedImt!,
          imtCategory: _imtCategory ?? 'Normal',
          age: age,
          gender: _gender!,
          familyHistory: _familyHistory!,
          smokingHistory: _smokingHistory!,
          hypertensionHistory: _hypertensionHistory!,
          cardiovascularHistory: _cardiovascularHistory!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section Banner: Kuesioner Gaya Hidup & Riwayat Kesehatan
              _buildTopBanner(),
              const SizedBox(height: 22),

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
              const SizedBox(height: 22),

              // 2. Riwayat Keluarga
              _buildQuestionTitle('2. Riwayat Keluarga'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _familyHistory,
                onChanged: (val) => setState(() => _familyHistory = val),
              ),
              const SizedBox(height: 22),

              // 3. Usia
              _buildQuestionTitle('3. Usia'),
              const SizedBox(height: 10),
              _buildInputField(
                controller: _ageController,
                hintText: 'Contoh: 45',
                isInteger: true,
              ),
              const SizedBox(height: 22),

              // 4. Jenis Kelamin
              _buildQuestionTitle('4. Jenis Kelamin'),
              const SizedBox(height: 10),
              _buildGenderToggle(),
              const SizedBox(height: 22),

              // 5. Riwayat Merokok
              _buildQuestionTitle('5. Riwayat Merokok'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _smokingHistory,
                onChanged: (val) => setState(() => _smokingHistory = val),
              ),
              const SizedBox(height: 22),

              // 6. Riwayat Hipertensi
              _buildQuestionTitle('6. Riwayat Hipertensi'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _hypertensionHistory,
                onChanged: (val) => setState(() => _hypertensionHistory = val),
              ),
              const SizedBox(height: 22),

              // 7. Riwayat Kardiovaskuler
              _buildQuestionTitle('7. Riwayat Kardiovaskuler'),
              const SizedBox(height: 10),
              _buildYesNoToggle(
                currentValue: _cardiovascularHistory,
                onChanged: (val) => setState(() => _cardiovascularHistory = val),
              ),
              const SizedBox(height: 30),

              // 2 Tombol di bagian bawah:
              // Outline merah "Reset" & Solid merah gelap penuh "Hitung Skor Risiko"
              _buildBottomActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Header merah (#E53935) + tombol back, judul "Cek Risiko"
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
        'Cek Risiko',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
    );
  }

  /// Judul section "Kuesioner Gaya Hidup & Riwayat Kesehatan"
  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _bannerBorder, width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _bannerBorder.withValues(alpha: 0.6)),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: _primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kuesioner Gaya Hidup & Riwayat Kesehatan',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Isi kuesioner untuk mengestimasi tingkat risiko diabetes',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        color: const Color(0xFF212121),
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

  /// Input text field dengan styling modern & bersih
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isInteger = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isInteger
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          if (isInteger)
            FilteringTextInputFormatter.digitsOnly
          else
            FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
        ],
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF212121),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFBDBDBD),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _inputBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primaryRed, width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }

  /// Tombol solid merah gelap "Hitung IMT" di sebelah kiri,
  /// hasil ditampilkan di kanan dalam card merah muda: "HASIL IMT — IMT Anda: [nilai]"
  Widget _buildImtActionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tombol solid merah gelap "Hitung IMT"
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _calculateImt,
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRed, // Solid merah gelap
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Hitung IMT',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Card merah muda hasil IMT: "HASIL IMT — IMT Anda: [nilai]"
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
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _darkRed,
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
            icon: Icons.male_rounded,
            isSelected: _gender == 'Laki-Laki',
            onTap: () => setState(() => _gender = 'Laki-Laki'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildChoiceButton(
            title: 'Perempuan',
            icon: Icons.female_rounded,
            isSelected: _gender == 'Perempuan',
            onTap: () => setState(() => _gender = 'Perempuan'),
          ),
        ),
      ],
    );
  }

  /// Tombol pilihan (toggle):
  /// - Aktif: berwarna merah solid (#E53935) dengan teks putih
  /// - Tidak aktif: outline merah tipis dengan teks merah
  Widget _buildChoiceButton({
    required String title,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Sesuai requirement:
    // Pilihan aktif: merah solid dengan teks putih
    // Pilihan tidak aktif: outline merah tipis dengan teks merah
    final Color bgColor = isSelected ? _primaryRed : Colors.white;
    final Color contentColor = isSelected ? Colors.white : _primaryRed;
    final Border border = isSelected
        ? Border.all(color: _primaryRed, width: 1.5)
        : Border.all(color: _primaryRed, width: 1.0); // Outline merah tipis

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: border,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryRed.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 19,
                  color: contentColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 2 tombol di bagian bawah:
  /// - Outline merah "Reset"
  /// - Solid merah gelap penuh "Hitung Skor Risiko" (dengan ikon panah)
  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        // Tombol 1: Outline merah "Reset"
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _resetForm,
            style: OutlinedButton.styleFrom(
              foregroundColor: _primaryRed,
              side: const BorderSide(color: _primaryRed, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: _primaryRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reset',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _primaryRed,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tombol 2: Solid merah gelap penuh "Hitung Skor Risiko" (dengan ikon panah)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _calculateRiskScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRed, // Solid merah gelap
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: _darkRed.withValues(alpha: 0.35),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
