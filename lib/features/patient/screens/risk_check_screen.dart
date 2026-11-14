import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'risk_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../services/user_repository.dart';
import '../../../../naive_bayes_model.dart';
import '../../../../risk_helpers.dart';

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
  DateTime? _selectedBirthDate;

  // Selected states
  double? _calculatedImt;
  String? _imtCategory;

  bool? _familyHistory; // true = Ya, false = Tidak
  String? _gender; // 'Laki-Laki' or 'Perempuan'
  bool? _smokingHistory; // true = Ya, false = Tidak
  bool? _hypertensionHistory; // true = Ya, false = Tidak
  bool? _cardiovascularHistory; // true = Ya, false = Tidak
  bool? _physicalActivity; // true = Ya, false = Tidak
  bool? _fruitConsumption; // true = Ya, false = Tidak
  bool? _vegetableConsumption; // true = Ya, false = Tidak

  bool _isLoading = false; // Loading saat prediksi
  NaiveBayesModel? _nbModel; // Model Naive Bayes lokal

  // Soft Pink Theme Palette
  static const Color _primaryPink = Color(0xFFF06292); // Soft pink utama
  static const Color _deepPink = Color(0xFFE91E63);    // Vibrant soft pink untuk tombol utama
  static const Color _lightPinkBg = Color(0xFFFFF0F5); // Card blush lembut
  static const Color _borderPink = Color(0xFFF8BBD0);  // Border soft pink
  static const Color _textDark = Color(0xFF212121);    // Teks hitam pekat

  @override
  void initState() {
    super.initState();
    _loadUserDob();
    _loadModel();
  }

  /// Memuat model Naive Bayes dari asset JSON
  Future<void> _loadModel() async {
    final m = await NaiveBayesModel.muat();
    if (mounted) setState(() => _nbModel = m);
  }

  /// Memuat tanggal lahir pasien dari Firestore secara otomatis jika sudah tersimpan di profil
  Future<void> _loadUserDob() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final appUser = await UserRepository.instance.findByUid(user.uid);
        if (appUser != null && appUser.dob.isNotEmpty && mounted) {
          final parsed = DateTime.tryParse(appUser.dob);
          if (parsed != null) {
            final age = _calculateAge(parsed);
            setState(() {
              _selectedBirthDate = parsed;
              _ageController.text = age.toString();
            });
          }
        }
      }
    } catch (_) {}
  }

  /// Hitung usia secara presisi berdasarkan tanggal lahir menggunakan risk_helpers.dart
  int _calculateAge(DateTime birthDate) {
    final age = hitungUsia(birthDate);
    return age < 0 ? 0 : age;
  }

  /// Format tanggal ke Bahasa Indonesia (Contoh: 12 Mei 1998)
  String _formatIndoDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Menampilkan dialog kalender kustom yang rapi & mudah memilih Tanggal, Bulan, dan Tahun Lahir
  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _selectedBirthDate ?? DateTime(now.year - 25, now.month, now.day);

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const dayHeaders = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    int selectedYear = initial.year;
    int selectedMonth = initial.month;
    int selectedDay = initial.day;

    final yearInputController = TextEditingController(text: '${initial.year}');
    bool showYearGrid = false;

    int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final maxDays = daysInMonth(selectedYear, selectedMonth);
            if (selectedDay > maxDays) selectedDay = maxDays;

            final firstWeekday = DateTime(selectedYear, selectedMonth, 1).weekday % 7; // 0 = Minggu
            final tempDate = DateTime(selectedYear, selectedMonth, selectedDay);
            final previewAge = _calculateAge(tempDate);

            // Filter tahun jika user sedang mengetik sebagian angka di mode cari tahun
            final typedQuery = yearInputController.text.trim();
            final allYears = List.generate(now.year - 1920 + 1, (idx) => now.year - idx);
            final filteredYears = (typedQuery.isEmpty || typedQuery == '$selectedYear')
                ? allYears
                : allYears.where((y) => '$y'.contains(typedQuery)).toList();

            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: _borderPink, width: 1.2),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Judul & Preview Usia
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _lightPinkBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderPink),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cake_rounded,
                              color: _deepPink,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pilih Tanggal Lahir',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF757575),
                                    ),
                                  ),
                                  Text(
                                    '$selectedDay ${months[selectedMonth - 1]} $selectedYear',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: _textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _primaryPink,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$previewAge Thn',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Baris Bulan (Dropdown) & Tahun (Bisa diketik langsung + Tombol Cari Grid Tahun)
                      Row(
                        children: [
                          // Dropdown Bulan
                          Expanded(
                            flex: 5,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _borderPink, width: 1.2),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedMonth,
                                  isExpanded: true,
                                  menuMaxHeight: 280,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: _deepPink,
                                    size: 20,
                                  ),
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: _textDark,
                                  ),
                                  items: List.generate(12, (idx) {
                                    final m = idx + 1;
                                    final disabled = selectedYear == now.year && m > now.month;
                                    return DropdownMenuItem<int>(
                                      value: m,
                                      enabled: !disabled,
                                      child: Text(
                                        months[idx],
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: m == selectedMonth
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: disabled
                                              ? const Color(0xFFBDBDBD)
                                              : (m == selectedMonth ? _deepPink : _textDark),
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    if (selectedYear == now.year && val > now.month) return;
                                    setDialogState(() {
                                      selectedMonth = val;
                                      showYearGrid = false;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Input Ketik Tahun + Tombol Grid Pencarian Tahun
                          Expanded(
                            flex: 4,
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.only(left: 10, right: 4),
                              decoration: BoxDecoration(
                                color: showYearGrid ? _lightPinkBg : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: showYearGrid ? _primaryPink : _borderPink,
                                  width: showYearGrid ? 1.5 : 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: yearInputController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(4),
                                      ],
                                      style: GoogleFonts.poppins(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: _textDark,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Tahun',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFFBDBDBD),
                                        ),
                                        isDense: true,
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        final parsed = int.tryParse(val);
                                        setDialogState(() {
                                          if (parsed != null &&
                                              parsed >= 1900 &&
                                              parsed <= now.year) {
                                            selectedYear = parsed;
                                            if (selectedYear == now.year &&
                                                selectedMonth > now.month) {
                                              selectedMonth = now.month;
                                            }
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        showYearGrid = !showYearGrid;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Tooltip(
                                      message: showYearGrid
                                          ? 'Kembali ke Tanggal'
                                          : 'Cari / Pilih Tahun',
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: showYearGrid
                                              ? _primaryPink
                                              : _lightPinkBg,
                                          borderRadius: BorderRadius.circular(7),
                                        ),
                                        child: Icon(
                                          showYearGrid
                                              ? Icons.calendar_view_month_rounded
                                              : Icons.manage_search_rounded,
                                          size: 16,
                                          color: showYearGrid
                                              ? Colors.white
                                              : _deepPink,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Mode 1: Grid Pilih/Cari Tahun (bukan dropdown memanjang)
                      if (showYearGrid) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ketik tahun di atas atau klik tahun di bawah:',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 210,
                          child: filteredYears.isEmpty
                              ? Center(
                                  child: Text(
                                    'Tahun tidak ditemukan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                )
                              : GridView.builder(
                                  itemCount: filteredYears.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 2.1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final y = filteredYears[index];
                                    final isSelected = y == selectedYear;
                                    return InkWell(
                                      onTap: () {
                                        setDialogState(() {
                                          selectedYear = y;
                                          yearInputController.text = '$y';
                                          if (selectedYear == now.year &&
                                              selectedMonth > now.month) {
                                            selectedMonth = now.month;
                                          }
                                          showYearGrid = false;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _primaryPink
                                              : _lightPinkBg.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? _primaryPink
                                                : _borderPink,
                                          ),
                                        ),
                                        child: Text(
                                          '$y',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white
                                                : _textDark,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ] else ...[
                        // Mode 2: Kalender Tanggal Normal
                        Row(
                          children: dayHeaders
                              .map(
                                (d) => Expanded(
                                  child: Center(
                                    child: Text(
                                      d,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: d == 'Min' ? _deepPink : const Color(0xFF757575),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 6),

                        // Grid Tanggal
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: firstWeekday + maxDays,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1.05,
                          ),
                          itemBuilder: (context, index) {
                            if (index < firstWeekday) {
                              return const SizedBox.shrink();
                            }
                            final day = index - firstWeekday + 1;
                            final isFuture = selectedYear == now.year &&
                                selectedMonth == now.month &&
                                day > now.day;
                            final isSelected = day == selectedDay;

                            return InkWell(
                              onTap: isFuture
                                  ? null
                                  : () => setDialogState(() => selectedDay = day),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _primaryPink
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$day',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isFuture
                                        ? const Color(0xFFD0D0D0)
                                        : (isSelected ? Colors.white : _textDark),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Tombol Batal & Pilih
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF757575),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(
                              ctx,
                              DateTime(selectedYear, selectedMonth, selectedDay),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryPink,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Pilih Tanggal',
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null) {
      final age = _calculateAge(picked);
      setState(() {
        _selectedBirthDate = picked;
        _ageController.text = age.toString();
      });
    }
  }

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

    final hasilImt = hitungImt(weight, height);

    setState(() {
      _calculatedImt = hasilImt.nilai;
      _imtCategory = hasilImt.kategori;
    });

    FocusScope.of(context).unfocus();
  }

  /// Reset semua input dan state kuesioner
  void _resetForm() {
    setState(() {
      _weightController.clear();
      _heightController.clear();
      _ageController.clear();
      _selectedBirthDate = null;
      _calculatedImt = null;
      _imtCategory = null;
      _familyHistory = null;
      _gender = null;
      _smokingHistory = null;
      _hypertensionHistory = null;
      _cardiovascularHistory = null;
      _physicalActivity = null;
      _fruitConsumption = null;
      _vegetableConsumption = null;
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

  /// Prediksi dengan model Naive Bayes lokal lalu buka halaman Detail Risiko
  Future<void> _calculateRiskScore() async {
    // Pastikan IMT sudah terhitung jika BB & TB diisi
    if (_calculatedImt == null &&
        _weightController.text.isNotEmpty &&
        _heightController.text.isNotEmpty) {
      _calculateImt();
    }

    final ageText = _ageController.text.trim();
    final age = int.tryParse(ageText);

    final weight =
        double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ??
            65.0;
    final height =
        double.tryParse(_heightController.text.trim().replaceAll(',', '.')) ??
            170.0;

    // Validasi semua field terisi
    if (_calculatedImt == null ||
        age == null ||
        _familyHistory == null ||
        _gender == null ||
        _smokingHistory == null ||
        _hypertensionHistory == null ||
        _cardiovascularHistory == null ||
        _physicalActivity == null ||
        _fruitConsumption == null ||
        _vegetableConsumption == null) {
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

    if (_nbModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Model belum siap, mohon tunggu sebentar...',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: const Color(0xFFE65100),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Hitung kategori IMT sesuai risk_helpers.dart
      final hasilImt = hitungImt(weight, height);

      // Bangun input untuk model NB
      final input = <String, String>{
        'JK': labelJk(_gender == 'Laki-Laki'),
        'Usia': _nbModel!.kelompokUsia(age),
        'IMT': hasilImt.kategori,
        'Hipertensi': yaTidak(_hypertensionHistory!),
        'Riwayat Kardiovaskuler': yaTidak(_cardiovascularHistory!),
        'Riwayat Merokok': yaTidak(_smokingHistory!),
        'Riwayat Keluarga': yaTidak(_familyHistory!),
        'Aktivitas Fisik': yaTidak(_physicalActivity!),
        'Konsumsi Buah': yaTidak(_fruitConsumption!),
        'Konsumsi Sayur': yaTidak(_vegetableConsumption!),
      };

      final hasil = _nbModel!.prediksi(input);

      if (!mounted) return;

      // Navigasi ke halaman detail dengan membawa hasil prediksi Naive Bayes
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RiskDetailScreen(
            weight: weight,
            height: height,
            imt: _calculatedImt!,
            imtCategory: hasilImt.kategori,
            age: age,
            gender: _gender ?? 'Laki-Laki',
            familyHistory: _familyHistory!,
            smokingHistory: _smokingHistory!,
            hypertensionHistory: _hypertensionHistory!,
            cardiovascularHistory: _cardiovascularHistory!,
            vegetableConsumption: _vegetableConsumption!,
            fruitConsumption: _fruitConsumption!,
            physicalActivity: _physicalActivity!,
            hasilPrediksiNb: hasil,
            hasilPrediksiApi: hasil.berisiko ? 'Risiko Tinggi' : 'Risiko Rendah',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memprediksi: $e',
              style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
            ),
            backgroundColor: const Color(0xFFE65100),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              _buildQuestionTitle(
                '1. Indeks Massa Tubuh (IMT) / Berat Badan',
                subtitle:
                    'Masukkan berat dan tinggi badan Anda untuk mengetahui kategori IMT',
              ),
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

              // 2. Usia
              _buildQuestionTitle(
                '2. Usia',
                subtitle:
                    'Pilih tanggal lahir Anda untuk menghitung usia saat ini',
              ),
              const SizedBox(height: 10),
              _buildAgePickerField(),
              const SizedBox(height: 22),

              // 3. Jenis Kelamin (Laki-Laki / Perempuan tanpa icon, persis Image 1)
              _buildQuestionTitle(
                '3. Jenis Kelamin',
                subtitle: 'Pilih jenis kelamin biologis Anda',
              ),
              const SizedBox(height: 10),
              _buildGenderToggle(),
              const SizedBox(height: 22),

              // 4. Riwayat Keluarga DM
              _buildQuestionTitle(
                '4. Riwayat Keluarga DM',
                subtitle:
                    'Memiliki anggota keluarga kandung (orang tua / saudara) dengan riwayat diabetes',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _familyHistory,
                onChanged: (val) => setState(() => _familyHistory = val),
              ),
              const SizedBox(height: 22),

              // 5. Riwayat Merokok
              _buildQuestionTitle(
                '5. Riwayat Merokok',
                subtitle:
                    'Merupakan perokok aktif atau memiliki riwayat kebiasaan merokok',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _smokingHistory,
                onChanged: (val) => setState(() => _smokingHistory = val),
              ),
              const SizedBox(height: 22),

              // 6. Riwayat Hipertensi
              _buildQuestionTitle(
                '6. Riwayat Hipertensi',
                subtitle:
                    'Pernah didiagnosis memiliki tekanan darah tinggi (hipertensi) atau rutin mengonsumsi obat antihipertensi',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _hypertensionHistory,
                onChanged: (val) => setState(() => _hypertensionHistory = val),
              ),
              const SizedBox(height: 22),

              // 7. Riwayat Kardiovaskuler
              _buildQuestionTitle(
                '7. Riwayat Kardiovaskuler',
                subtitle:
                    'Memiliki riwayat penyakit jantung atau gangguan pembuluh darah (seperti penyakit jantung koroner atau stroke)',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _cardiovascularHistory,
                onChanged: (val) => setState(() => _cardiovascularHistory = val),
              ),
              const SizedBox(height: 22),

              // 8. Konsumsi Sayuran
              _buildQuestionTitle(
                '8. Konsumsi Sayuran',
                subtitle:
                    'Rutin mengonsumsi sayuran dalam menu makan sehari-hari',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _vegetableConsumption,
                onChanged: (val) => setState(() => _vegetableConsumption = val),
              ),
              const SizedBox(height: 22),

              // 9. Konsumsi Buah-buahan
              _buildQuestionTitle(
                '9. Konsumsi Buah-buahan',
                subtitle:
                    'Rutin mengonsumsi buah-buahan segar setiap hari',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _fruitConsumption,
                onChanged: (val) => setState(() => _fruitConsumption = val),
              ),
              const SizedBox(height: 22),

              // 10. Aktivitas Fisik
              _buildQuestionTitle(
                '10. Aktivitas Fisik',
                subtitle:
                    'Rutin melakukan aktivitas fisik atau olahraga sehari-hari',
              ),
              const SizedBox(height: 10),
              _buildRadioToggle(
                currentValue: _physicalActivity,
                onChanged: (val) => setState(() => _physicalActivity = val),
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

  Widget _buildQuestionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ],
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

  /// Widget pemilih tanggal lahir kalender dengan perhitungan usia otomatis
  Widget _buildAgePickerField() {
    final hasDate = _selectedBirthDate != null && _ageController.text.isNotEmpty;

    return InkWell(
      onTap: _pickBirthDate,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasDate ? _primaryPink : _borderPink,
            width: hasDate ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: hasDate
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_ageController.text} Tahun',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          'Lahir: ${_formatIndoDate(_selectedBirthDate!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF757575),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : Text(
                      'Pilih tanggal lahir',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFFBDBDBD),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _lightPinkBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderPink.withValues(alpha: 0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 15,
                    color: _deepPink,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hasDate ? 'Ubah' : 'Pilih',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _deepPink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
            onPressed: _isLoading ? null : _calculateRiskScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Hitung Total Risiko >',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
