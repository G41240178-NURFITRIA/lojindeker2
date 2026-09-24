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
  static const Color _deepPink = Color(0xFFE91E63);    // Vibrant soft pink untuk tombol utama
  static const Color _lightPinkBg = Color(0xFFFFF0F5); // Card blush lembut
  static const Color _borderPink = Color(0xFFF8BBD0);  // Border soft pink
  static const Color _textDark = Color(0xFF212121);    // Teks hitam pekat

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
          backgroundColor: _primaryPink,
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
        backgroundColor: _primaryPink,
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
          backgroundColor: _primaryPink,
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
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section Banner: Kuesioner Gaya Hidup & Riwayat (Persis Image 1)
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
              const SizedBox(height: 12),

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
              _buildRadioToggle(
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

              // 4. Jenis Kelamin (Laki-Laki / Perempuan tanpa icon, persis Image 1)
              _buildQuestionTitle('4. Jenis Kelamin'),
              const SizedBox(height: 10),
              _buildGenderToggle(),
              const SizedBox(height: 22),

              // 5. Riwayat Merokok
              _buildQuestionTitle('5. Riwayat Merokok'),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _smokingHistory,
                onChanged: (val) => setState(() => _smokingHistory = val),
              ),
              const SizedBox(height: 22),

              // 6. Riwayat Hipertensi
              _buildQuestionTitle('6. Riwayat Hipertensi'),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _hypertensionHistory,
                onChanged: (val) => setState(() => _hypertensionHistory = val),
              ),
              const SizedBox(height: 22),

              // 7. Riwayat Kardiovaskuler
              _buildQuestionTitle('7. Riwayat Kardiovaskuler'),
              const SizedBox(height: 10),
              _buildRadioToggle(
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

  /// Header Bersih Putih dengan "< Cek Risiko" (Persis Image 1)
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: _textDark,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Cek Risiko',
        style: GoogleFonts.poppins(
          fontSize: 16.5,
          fontWeight: FontWeight.w700,
          color: _textDark,
        ),
      ),
      centerTitle: false,
    );
  }

  /// Banner judul "Kuesioner Gaya Hidup & Riwayat" (Persis Image 1)
  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _lightPinkBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderPink, width: 1.0),
      ),
      child: Text(
        'Kuesioner Gaya Hidup &\nRiwayat',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _textDark,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _buildQuestionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: _textDark,
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
          color: _textDark,
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
            borderSide: const BorderSide(color: _borderPink, width: 1),
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

  /// Tombol "Hitung IMT" di kiri & Hasil IMT di kanan dalam Soft Pink
  Widget _buildImtActionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _calculateImt,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _lightPinkBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _borderPink),
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
                      ? 'IMT Anda : -'
                      : 'IMT Anda : ${_calculatedImt!.toStringAsFixed(1)} ($_imtCategory)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _deepPink,
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

  /// Pilihan Radio "Ya" dan "Tidak" dengan Icon Radio Bulat (Persis Image 1)
  Widget _buildRadioToggle({
    required bool? currentValue,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildRadioOption(
            title: 'Ya',
            isSelected: currentValue == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRadioOption(
            title: 'Tidak',
            isSelected: currentValue == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }

  Widget _buildRadioOption({
    required String title,
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
            color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _primaryPink : _borderPink,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 19,
                color: isSelected ? _primaryPink : const Color(0xFF9E9E9E),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? _deepPink : _textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tombol Jenis Kelamin (Laki-Laki / Perempuan, persis Image 1 tanpa icon)
  Widget _buildGenderToggle() {
    return Row(
      children: [
        Expanded(
          child: _buildGenderOption(
            title: 'Laki-Laki',
            isSelected: _gender == 'Laki-Laki',
            onTap: () => setState(() => _gender = 'Laki-Laki'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildGenderOption(
            title: 'Perempuan',
            isSelected: _gender == 'Perempuan',
            onTap: () => setState(() => _gender = 'Perempuan'),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption({
    required String title,
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFF0F5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _primaryPink : _borderPink,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? _deepPink : _textDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Tombol Reset & Tombol "Hitung Total Risiko >" (Soft Pink)
  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        // Text Link "Reset"
        Center(
          child: TextButton(
            onPressed: _resetForm,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF757575),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            ),
            child: Text(
              'Reset',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Tombol besar "Hitung Total Risiko >" dalam Soft Pink
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _calculateRiskScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
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
                    fontWeight: FontWeight.w600,
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
