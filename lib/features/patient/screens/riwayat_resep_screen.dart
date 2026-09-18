import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_resep_screen.dart';

class MedicineModel {
  final String name;
  final String dosage;
  final String instruction;
  final String quantity;
  final bool isBottle;

  const MedicineModel({
    required this.name,
    required this.dosage,
    required this.instruction,
    required this.quantity,
    this.isBottle = false,
  });

  String get displayName => '$name $dosage';
}

class PrescriptionModel {
  final String id;
  final String date;
  final String doctorName;
  final String doctorSpecialty;
  final String status; // 'Aktif' | 'Selesai'
  final List<MedicineModel> medicines;
  final String notes;

  const PrescriptionModel({
    required this.id,
    required this.date,
    required this.doctorName,
    this.doctorSpecialty = 'Sp. Penyakit Dalam',
    required this.status,
    required this.medicines,
    this.notes = 'Konsumsi obat sesuai anjuran dan pantau gula darah secara berkala.',
  });

  bool get isActive => status.toLowerCase() == 'aktif';
}

class RiwayatResepScreen extends StatefulWidget {
  const RiwayatResepScreen({super.key});

  @override
  State<RiwayatResepScreen> createState() => _RiwayatResepScreenState();
}

class _RiwayatResepScreenState extends State<RiwayatResepScreen> {
  int _selectedCategoryIndex = 3; // Default 'Resep'
  final int _selectedBottomNavIndex = 3; // Calendar / Schedule icon

  final List<String> _categories = const [
    'Cek Risiko AI',
    'Konsultasi',
    'Monitoring',
    'Resep',
  ];

  final List<PrescriptionModel> _prescriptions = const [
    PrescriptionModel(
      id: 'RXP-001',
      date: '18 Mei 2024',
      doctorName: 'dr. Andini Putri',
      doctorSpecialty: 'Sp. Penyakit Dalam',
      status: 'Aktif',
      notes:
          'Kontrol gula darah rutin, kurangi konsumsi gula dan karbohidrat sederhana. Kontrol ulang 2 minggu lagi.',
      medicines: [
        MedicineModel(
          name: 'Metformin',
          dosage: '500 mg',
          instruction: '2x sehari sesudah makan',
          quantity: '30 tablet',
        ),
        MedicineModel(
          name: 'Glimepiride',
          dosage: '1 mg',
          instruction: '1x sehari sebelum makan pagi',
          quantity: '30 tablet',
        ),
      ],
    ),
    PrescriptionModel(
      id: 'RXP-002',
      date: '15 Februari 2024',
      doctorName: 'dr. Andini Putri',
      doctorSpecialty: 'Sp. Penyakit Dalam',
      status: 'Selesai',
      notes:
          'Kondisi Stabil. Tambahkan suplemen vitamin D3 untuk daya tahan tubuh. Kontrol rutin sebulan sekali.',
      medicines: [
        MedicineModel(
          name: 'Metformin',
          dosage: '500 mg',
          instruction: '2x sehari sesudah makan',
          quantity: '30 tablet',
        ),
        MedicineModel(
          name: 'Vitamin D3',
          dosage: '1000 IU',
          instruction: '1x sehari sesudah makan',
          quantity: '30 kapsul',
          isBottle: true,
        ),
      ],
    ),
    PrescriptionModel(
      id: 'RXP-003',
      date: '10 November 2023',
      doctorName: 'dr. Budi Santoso',
      doctorSpecialty: 'Sp. Penyakit Dalam',
      status: 'Selesai',
      notes:
          'Pemeriksaan awal terdeteksi gula darah tinggi. Mulai terapi obat dan disarankan mengatur pola makan.',
      medicines: [
        MedicineModel(
          name: 'Metformin',
          dosage: '500 mg',
          instruction: '2x sehari sesudah makan',
          quantity: '30 tablet',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFBA171E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 32,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Riwayat Resep Obat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. Horizontal Category Tabs/Chips
          _buildCategoryTabs(),

          // 2. Prescription Cards List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _prescriptions.length,
              itemBuilder: (context, index) {
                final prescription = _prescriptions[index];
                return _buildPrescriptionCard(prescription);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Horizontal scrollable tabs row: Cek Risiko AI, Konsultasi, Monitoring, Resep
  Widget _buildCategoryTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(_categories.length, (index) {
            final title = _categories[index];
            final isSelected = _selectedCategoryIndex == index;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedCategoryIndex = index;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7D0E12)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF7D0E12),
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF7D0E12),
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

  /// Card item for each prescription
  Widget _buildPrescriptionCard(PrescriptionModel prescription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD64D52),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Doctor on left, Status on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Red calendar icon
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 8),
                child: Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: const Color(0xFFBA171E),
                ),
              ),
              // Date and Doctor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prescription.date,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prescription.doctorName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: prescription.isActive
                      ? const Color(0xFFE2F8E7)
                      : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  prescription.status,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: prescription.isActive
                        ? const Color(0xFF1B8738)
                        : const Color(0xFF757575),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Medicines inner box with thin red border
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFD64D52),
                width: 1.2,
              ),
            ),
            child: Column(
              children: List.generate(prescription.medicines.length, (idx) {
                final med = prescription.medicines[idx];
                final isLast = idx == prescription.medicines.length - 1;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Custom Pill Capsule Icon (45-degree angle, top red, bottom white)
                          _buildCustomPillIcon(),

                          const SizedBox(width: 10),

                          // Medicine name, dosage, instruction
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1E1E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  med.instruction,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF333333),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Quantity
                          Text(
                            med.quantity,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF3D5D5),
                      ),
                  ],
                );
              }),
            ),
          ),

          const SizedBox(height: 12),

          // "Lihat Detail" Button
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetailResepScreen.fromPrescription(prescription),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFBA171E),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Detail',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B1317),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF8B1317),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom capsule/pill icon matching the reference screenshot
  Widget _buildCustomPillIcon() {
    return Transform.rotate(
      angle: -0.7, // 45-degree angle
      child: Container(
        width: 13,
        height: 23,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFBA171E),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Top half: Solid Red
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFBA171E),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
            // Bottom half: White
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Navigation Bar with 4 icons: Home, Chat, Profile, Calendar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFF6ECEB),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {},
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.person_outline_rounded,
            onTap: () {},
          ),
          _buildNavItem(
            index: 3,
            icon: Icons.calendar_month_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedBottomNavIndex == index;
    final color =
        isSelected ? const Color(0xFFBA171E) : const Color(0xFFD65C62);

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
