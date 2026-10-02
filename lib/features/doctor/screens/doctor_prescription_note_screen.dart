import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MedicationItem {
  final TextEditingController nameController;
  final TextEditingController instructionController;

  MedicationItem({
    String name = '',
    String instruction = '',
  })  : nameController = TextEditingController(text: name),
        instructionController = TextEditingController(text: instruction);

  void dispose() {
    nameController.dispose();
    instructionController.dispose();
  }
}

class DoctorPrescriptionNoteScreen extends StatefulWidget {
  final String patientName;
  final String rmNumber;
  final String age;

  const DoctorPrescriptionNoteScreen({
    super.key,
    this.patientName = 'Widyatna Dwi',
    this.rmNumber = 'RM-2026-0812',
    this.age = '28 thn',
  });

  @override
  State<DoctorPrescriptionNoteScreen> createState() =>
      _DoctorPrescriptionNoteScreenState();
}

class _DoctorPrescriptionNoteScreenState
    extends State<DoctorPrescriptionNoteScreen> {
  // Status Kunjungan: 'Terkontrol baik' | 'Evaluasi dosis'
  String _selectedStatus = 'Terkontrol baik';

  // Medication list
  final List<MedicationItem> _medications = [];

  // Note controller
  late final TextEditingController _noteController;

  final List<String> _quickSuggestions = [
    'Lanjutkan obat',
    'Kurangi gula',
    'Olahraga rutin',
    'Cek gula pagi',
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(
      text: 'Kadar gula darah stabil. Lanjutkan obat dan pola makan saat ini.',
    );

    // Initial default medication
    _medications.add(
      MedicationItem(
        name: 'Metformin HCl 500 mg',
        instruction: '2x1 sesudah makan',
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final med in _medications) {
      med.dispose();
    }
    super.dispose();
  }

  void _addMedication() {
    setState(() {
      _medications.add(MedicationItem());
    });
  }

  void _removeMedication(int index) {
    if (_medications.length <= 1) {
      // Clear instead of removing if only 1 item left
      _medications[0].nameController.clear();
      _medications[0].instructionController.clear();
      setState(() {});
      return;
    }
    setState(() {
      final item = _medications.removeAt(index);
      item.dispose();
    });
  }

  void _appendSuggestion(String suggestion) {
    final currentText = _noteController.text.trim();
    if (currentText.contains(suggestion)) return;

    setState(() {
      if (currentText.isEmpty) {
        _noteController.text = '$suggestion.';
      } else {
        if (!currentText.endsWith('.')) {
          _noteController.text = '$currentText. $suggestion.';
        } else {
          _noteController.text = '$currentText $suggestion.';
        }
      }
    });
  }

  void _saveToHistory() {
    final List<String> activeMeds = [];
    for (final med in _medications) {
      final name = med.nameController.text.trim();
      final instr = med.instructionController.text.trim();
      if (name.isNotEmpty) {
        if (instr.isNotEmpty) {
          activeMeds.add('$name ($instr)');
        } else {
          activeMeds.add(name);
        }
      }
    }

    final result = {
      'status': _selectedStatus,
      'medications': activeMeds,
      'note': _noteController.text.trim(),
      'date': 'Hari ini',
    };

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F9),
      body: Stack(
        children: [
          // Background decorative pink blush at top right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD9E2).withValues(alpha: 0.55),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                _buildHeader(context),

                // Main Scrollable Form Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Card
                        _buildPatientCard(),
                        const SizedBox(height: 20),

                        // Section 1: Status Kunjungan
                        _buildSectionTitle('Status kunjungan'),
                        const SizedBox(height: 10),
                        _buildStatusSelector(),
                        const SizedBox(height: 22),

                        // Section 2: Resep Obat
                        _buildSectionTitle('Resep obat'),
                        const SizedBox(height: 10),
                        _buildMedicationsCard(),
                        const SizedBox(height: 12),
                        _buildAddMedicationButton(),
                        const SizedBox(height: 22),

                        // Section 3: Catatan Dokter dan Anjuran
                        _buildSectionTitle('Catatan dokter dan anjuran'),
                        const SizedBox(height: 10),
                        _buildNoteInput(),
                        const SizedBox(height: 14),
                        _buildQuickSuggestions(),
                      ],
                    ),
                  ),
                ),

                // Fixed Bottom Save Action
                _buildBottomBar(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFCDD7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF2D2D2D),
                size: 26,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 42),
                child: Text(
                  'Resep dan catatan',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFD6E0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8DA1).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFD81B60),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.patientName,
                  style: GoogleFonts.poppins(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'No. RM: ${widget.rmNumber}, ${widget.age}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF2D2D2D),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final options = ['Terkontrol baik', 'Evaluasi dosis'];
    return Row(
      children: options.map((opt) {
        final isSelected = _selectedStatus == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedStatus = opt;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD81B60) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFD81B60)
                      : const Color(0xFFFFB2C5),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFD81B60).withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                opt,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMedicationsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFC5D3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: List.generate(_medications.length, (index) {
          final med = _medications[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < _medications.length - 1 ? 14.0 : 0.0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: TextField(
                          controller: med.nameController,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D2D2D),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Nama obat & dosis (cth: Metformin HCl 500 mg)',
                            hintStyle: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: const Color(0xFFA0AEC0),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _removeMedication(index),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFD81B60),
                        size: 22,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: med.instructionController,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D2D2D),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Aturan pakai (cth: 2x1 sesudah makan)',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: const Color(0xFFA0AEC0),
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAddMedicationButton() {
    return GestureDetector(
      onTap: _addMedication,
      child: CustomPaint(
        painter: _DashedRRectPainter(
          color: const Color(0xFFFF8DA1),
          strokeWidth: 1.5,
          gap: 4.0,
          dash: 6.0,
          radius: 16.0,
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add,
                color: Color(0xFFD81B60),
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                'Tambah obat',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD81B60),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteInput() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: TextField(
        controller: _noteController,
        maxLines: 4,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF2D2D2D),
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: 'Tulis catatan dokter dan anjuran...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFFA0AEC0),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _quickSuggestions.map((sug) {
        return GestureDetector(
          onTap: () => _appendSuggestion(sug),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFFFB2C5),
                width: 1.4,
              ),
            ),
            child: Text(
              sug,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0xFFFFE0E8),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: _saveToHistory,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.save_outlined,
                  color: Color(0xFF212121),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Simpan ke riwayat',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for dashed rounded rectangle border
class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dash;
  final double radius;

  _DashedRRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dash = 6.0,
    this.radius = 12.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = dash;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += length + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dash != dash ||
        oldDelegate.radius != radius;
  }
}
