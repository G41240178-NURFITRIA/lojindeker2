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

  // Soft Pink Theme Palette
  static const Color _primaryPink = Color(0xFFF06292); // Soft pink utama
  static const Color _darkRose = Color(0xFFD81B60);    // Deep rose untuk teks & tombol kontras
  static const Color _bannerBg = Color(0xFFFFF0F5);    // Card blush lembut
  static const Color _bannerBorder = Color(0xFFF8BBD0); // Border soft pink
  static const Color _inputBorder = Color(0xFFF8BBD0);  // Border input lembut
  static const Color _resultCardBg = Color(0xFFFFF0F5); // Card hasil IMT
  static const Color _resultCardBorder = Color(0xFFF8BBD0);

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
          backgroundColor: _darkRose,
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
        backgroundColor: _darkRose,
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

    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    final weight = double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 65.0;
    final height = double.tryParse(_heightController.text.trim().replaceAll(',', '.')) ?? 170.0;

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
          backgroundColor: _darkRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RiskDetailScreen(
          weight: weight,
          height: height,
          imt: _calculatedImt!,
          imtCategory: _imtCategory ?? 'Normal',
          age: age,
          gender: _gender ?? 'Laki-Laki',
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
      backgroundColor: const Color(0xFFFFF0F5), // Soft Pink Blush
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section Banner: Kuesioner Gaya Hidup & Riwayat
              _buildTopBanner(),
              const SizedBox(height: 20),

              // 1. Indeks Massa Tubuh (IMT) / Berat Badan
              _buildQuestionTitle('1. Indeks Massa Tubuh (IMT) / Berat Badan'),
              const SizedBox(height: 10),

              _buildFieldLabel('Berat Badan (kg)'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _weightController,
                hintText: 'Contoh : 65',
              ),
              const SizedBox(height: 14),

              _buildFieldLabel('Tinggi Badan (cm)'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _heightController,
                hintText: 'Contoh : 170',
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
                hintText: 'Contoh : 45',
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
              const SizedBox(height: 28),

              // Tombol Reset & Hitung Total Risiko
              _buildBottomActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Header Soft Pink + tombol back, judul "< Cek Risiko"
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryPink,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: _primaryPink,
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

  /// Banner judul "Kuesioner Gaya Hidup & Riwayat"
  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _bannerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _bannerBorder, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kuesioner Gaya Hidup & Riwayat',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Isi data kesehatan di bawah untuk mengestimasi risiko diabetes Anda',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _inputBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _primaryPink, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  /// Tombol "Hitung IMT" di kiri & Hasil IMT di kanan
  Widget _buildImtActionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _calculateImt,
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRose,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                      ? 'IMT Anda: --'
                      : 'IMT Anda: ${_calculatedImt!.toStringAsFixed(1)} ($_imtCategory)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _darkRose,
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

  Widget _buildYesNoToggle({
    required bool? currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildChoiceButton(
            title: 'Ya',
            icon: Icons.check_circle_outline_rounded,
            isSelected: currentValue == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 14),
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

  Widget _buildChoiceButton({
    required String title,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final Color bgColor = isSelected ? _primaryPink : Colors.white;
    final Color contentColor = isSelected ? Colors.white : const Color(0xFF333333);
    final Border border = isSelected
        ? Border.all(color: _primaryPink, width: 1.5)
        : Border.all(color: _inputBorder, width: 1.0);

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
                      color: _primaryPink.withValues(alpha: 0.25),
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
                  color: isSelected ? Colors.white : const Color(0xFF757575),
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

  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        // Text Button "Reset"
        Center(
          child: TextButton(
            onPressed: _resetForm,
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF888888),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Tombol besar "Hitung Total Risiko >"
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _calculateRiskScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRose,
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: _darkRose.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hitung Total Risiko >',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
