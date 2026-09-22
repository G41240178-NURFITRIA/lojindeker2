import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'when_to_see_doctor_screen.dart';
import 'article_detail_screen.dart';
import 'consultation_list_screen.dart';
import 'medical_records_screen.dart';
import 'riwayat_resep_screen.dart';

class MedicationReminder {
  final String id;
  String medicineName;
  String dosage;
  String schedule;
  String time;
  bool isActive;
  bool isTakenToday;
  IconData iconData;

  MedicationReminder({
    required this.id,
    required this.medicineName,
    required this.dosage,
    required this.schedule,
    required this.time,
    this.isActive = true,
    this.isTakenToday = false,
    this.iconData = Icons.medication_rounded,
  });
}

class SupportMenuScreen extends StatefulWidget {
  const SupportMenuScreen({super.key});

  @override
  State<SupportMenuScreen> createState() => _SupportMenuScreenState();
}

class _SupportMenuScreenState extends State<SupportMenuScreen> {
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _darkRose = Color(0xFFD81B60);
  static const Color _maroon = Color(0xFFB81018);

  // Daftar pengingat interaktif
  late List<MedicationReminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = [
      MedicationReminder(
        id: 'rem-1',
        medicineName: 'Metformin 500 Mg',
        dosage: '1 tablet - Setelah makan',
        schedule: 'Setiap 12 jam',
        time: '08:00',
        isActive: true,
        iconData: Icons.medication_rounded,
      ),
      MedicationReminder(
        id: 'rem-2',
        medicineName: 'Glimepiride 2mg',
        dosage: '1 tablet - Sebelum makan',
        schedule: 'Setiap 24 jam',
        time: '20:00',
        isActive: false,
        iconData: Icons.medication_liquid_rounded,
      ),
      MedicationReminder(
        id: 'rem-3',
        medicineName: 'Glimepiride 2mg',
        dosage: '1 tablet - Sebelum makan',
        schedule: 'Setiap 24 jam',
        time: '08:00',
        isActive: true,
        iconData: Icons.medication_liquid_rounded,
      ),
    ];
  }

  /// Toggle aktif/nonaktifkan notifikasi pengingat
  void _toggleReminder(MedicationReminder rem, bool value) {
    setState(() {
      rem.isActive = value;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              value ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value
                    ? 'Pengingat "${rem.medicineName}" diaktifkan (Pukul ${rem.time}).'
                    : 'Pengingat "${rem.medicineName}" dinonaktifkan.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: value ? const Color(0xFF2E7D32) : const Color(0xFF616161),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /// Simulasi notifikasi pengingat berbunyi
  void _triggerSimulatedAlarm(MedicationReminder item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.alarm_on_rounded, color: _darkRose, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WAKTU MINUM OBAT!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _darkRose,
                    ),
                  ),
                  Text(
                    'Pengingat Notifikasi D-Care',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF8BBD0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.medicineName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.dosage,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF555555),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, size: 14, color: _primaryPink),
                      const SizedBox(width: 4),
                      Text(
                        'Jadwal: ${item.time} (${item.schedule})',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primaryPink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Pastikan minum obat sesuai dosis dan anjuran dokter untuk menjaga kadar gula darah tetap stabil.',
              style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF666666)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Nanti (5 Menit)',
              style: GoogleFonts.poppins(color: const Color(0xFF757575), fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.isTakenToday = true;
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Hebat! Anda telah mencatat minum obat ${item.medicineName}',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkRose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Sudah Minum',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Buka Modal Tambah Pengingat
  void _showAddReminderSheet() {
    final nameController = TextEditingController();
    String selectedDosage = '1 tablet - Setelah makan';
    String selectedSchedule = 'Setiap 12 jam (2x sehari)';
    TimeOfDay selectedTime = const TimeOfDay(hour: 8, minute: 0);
    IconData selectedIcon = Icons.medication_rounded;

    final dosageOptions = [
      '1 tablet - Setelah makan',
      '1 tablet - Sebelum makan',
      '1 tablet - Bersama makanan',
      '2 tablet - Setelah makan',
      '1 sendok takar (5ml)',
      '10 Unit - Sebelum tidur (Insulin)',
    ];

    final scheduleOptions = [
      'Setiap 8 jam (3x sehari)',
      'Setiap 12 jam (2x sehari)',
      'Setiap 24 jam (1x sehari)',
      'Sesuai kebutuhan (PRN)',
    ];

    final presetChips = ['Metformin 500mg', 'Glimepiride 2mg', 'Acarbose 50mg', 'Insulin Lantus'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9EAEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_alarm_rounded, color: Color(0xFFB81018), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tambah Jadwal Pengingat Obat',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF141414),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Preset Chips
                    Text(
                      'Pilihan Cepat Obat Diabetes:',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: presetChips.map((chip) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: const Color(0xFFFFF0F2),
                              side: const BorderSide(color: Color(0xFFF48FB1), width: 0.8),
                              label: Text(
                                chip,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFFB81018),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  nameController.text = chip;
                                  if (chip.toLowerCase().contains('insulin')) {
                                    selectedIcon = Icons.vaccines_rounded;
                                    selectedDosage = '10 Unit - Sebelum tidur (Insulin)';
                                  } else {
                                    selectedIcon = Icons.medication_rounded;
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nama Obat
                    Text(
                      'Nama Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Misal: Metformin 500 Mg',
                        hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF9E9E9E)),
                        prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFFB81018), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFB81018), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Bentuk Obat (Icon Choice)
                    Text(
                      'Bentuk Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildIconChoice(
                          icon: Icons.medication_rounded,
                          label: 'Tablet / Kapsul',
                          isSelected: selectedIcon == Icons.medication_rounded,
                          onTap: () => setModalState(() => selectedIcon = Icons.medication_rounded),
                        ),
                        const SizedBox(width: 8),
                        _buildIconChoice(
                          icon: Icons.medication_liquid_rounded,
                          label: 'Sirup / Cair',
                          isSelected: selectedIcon == Icons.medication_liquid_rounded,
                          onTap: () => setModalState(() => selectedIcon = Icons.medication_liquid_rounded),
                        ),
                        const SizedBox(width: 8),
                        _buildIconChoice(
                          icon: Icons.vaccines_rounded,
                          label: 'Injeksi / Insulin',
                          isSelected: selectedIcon == Icons.vaccines_rounded,
                          onTap: () => setModalState(() => selectedIcon = Icons.vaccines_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dosis & Aturan
                    Text(
                      'Dosis & Aturan Minum',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: dosageOptions.contains(selectedDosage) ? selectedDosage : dosageOptions.first,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF757575)),
                          items: dosageOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt, style: GoogleFonts.poppins(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedDosage = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Jadwal / Frekuensi
                    Text(
                      'Jadwal Frekuensi',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: scheduleOptions.contains(selectedSchedule) ? selectedSchedule : scheduleOptions.first,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF757575)),
                          items: scheduleOptions.map((opt) {
                            return DropdownMenuItem(
                              value: opt,
                              child: Text(opt, style: GoogleFonts.poppins(fontSize: 12)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedSchedule = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Waktu Pengingat
                    Text(
                      'Waktu Alarm Minum Obat',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: sheetContext,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFB81018),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF212121),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, color: Color(0xFFB81018), size: 20),
                            const SizedBox(width: 10),
                            Text(
                              formattedTime,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF141414),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9EAEB),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Pilih Jam',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFFB81018),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF757575),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final text = nameController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Silakan masukkan nama obat terlebih dahulu',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                                return;
                              }

                              final newRem = MedicationReminder(
                                id: 'rem-${DateTime.now().millisecondsSinceEpoch}',
                                medicineName: text,
                                dosage: selectedDosage,
                                schedule: selectedSchedule.replaceAll(RegExp(r'\s*\(.*?\)'), ''),
                                time: formattedTime,
                                isActive: true,
                                iconData: selectedIcon,
                              );

                              setState(() {
                                _reminders.insert(0, newRem);
                              });

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Pengingat "$text" berhasil ditambahkan!',
                                    style: GoogleFonts.poppins(fontSize: 12),
                                  ),
                                  backgroundColor: const Color(0xFF2E7D32),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFB81018),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'Simpan Pengingat',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconChoice({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF9EAEB) : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? _maroon : const Color(0xFFE0E0E0),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? _maroon : const Color(0xFF757575), size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? _maroon : const Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Modal Opsi Pengingat (Tandai Diminum, Tes Alarm, Ubah Waktu, Hapus)
  void _showReminderOptions(MedicationReminder rem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9EAEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(rem.iconData, color: const Color(0xFF8F0D12), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rem.medicineName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8F0D12),
                          ),
                        ),
                        Text(
                          '${rem.dosage} • Pukul ${rem.time}',
                          style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF616161)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Opsi 1: Tandai Diminum
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: rem.isTakenToday ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    rem.isTakenToday ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                    color: rem.isTakenToday ? const Color(0xFF2E7D32) : const Color(0xFF757575),
                    size: 22,
                  ),
                ),
                title: Text(
                  rem.isTakenToday ? 'Batalkan Status Sudah Diminum' : 'Tandai Sudah Diminum Hari Ini',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: rem.isTakenToday ? const Color(0xFF2E7D32) : const Color(0xFF212121),
                  ),
                ),
                subtitle: Text(
                  rem.isTakenToday ? 'Status: Obat sudah diminum hari ini' : 'Catat kepatuhan minum obat Anda',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                ),
                onTap: () {
                  setState(() {
                    rem.isTakenToday = !rem.isTakenToday;
                  });
                  Navigator.pop(sheetContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        rem.isTakenToday
                            ? 'Bagus! ${rem.medicineName} ditandai sudah diminum.'
                            : 'Status ${rem.medicineName} dikembalikan.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      backgroundColor: rem.isTakenToday ? const Color(0xFF2E7D32) : const Color(0xFF616161),
                    ),
                  );
                },
              ),

              // Opsi 2: Tes Simulasi Alarm
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: _darkRose, size: 22),
                ),
                title: Text(
                  'Tes Simulasi Alarm Notifikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
                subtitle: Text(
                  'Coba tampilan bunyi alarm notifikasi obat',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _triggerSimulatedAlarm(rem);
                },
              ),

              // Opsi 3: Ubah Waktu
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9EAEB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_calendar_rounded, color: Color(0xFFB81018), size: 22),
                ),
                title: Text(
                  'Ubah Waktu Pengingat',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
                subtitle: Text(
                  'Waktu saat ini: Pukul ${rem.time}',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final parts = rem.time.split(':');
                  final initialHour = int.tryParse(parts[0]) ?? 8;
                  final initialMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: initialHour, minute: initialMin),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFB81018),
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );

                  if (picked != null) {
                    final formatted =
                        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                    setState(() {
                      rem.time = formatted;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Waktu pengingat ${rem.medicineName} diubah menjadi $formatted',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          backgroundColor: const Color(0xFFB81018),
                        ),
                      );
                    }
                  }
                },
              ),

              // Opsi 4: Hapus Pengingat
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828), size: 22),
                ),
                title: Text(
                  'Hapus Pengingat Ini',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC62828),
                  ),
                ),
                subtitle: Text(
                  'Hapus jadwal ini dari daftar pengingat harian',
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final removedIndex = _reminders.indexOf(rem);
                  setState(() {
                    _reminders.remove(rem);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pengingat ${rem.medicineName} dihapus.',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      action: SnackBarAction(
                        label: 'URUNGKAN',
                        textColor: const Color(0xFFFFCC80),
                        onPressed: () {
                          setState(() {
                            _reminders.insert(removedIndex, rem);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Menu Penunjang',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fitur pendukung untuk membantu mengelola diabetes anda setiap hari',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF616161),
                ),
              ),
              const SizedBox(height: 20),

              // Edukasi Diabetes Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCECDD),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Color(0xFFD35400)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edukasi Diabetes',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFFB81018),
                          ),
                        ),
                        Text(
                          'Artikel pilihan untuk hidup sehat dengan diabetes',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${educationalArticles.length} Artikel',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB81018),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal list of articles (Clickable!)
              SizedBox(
                height: 240,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: educationalArticles.length,
                  itemBuilder: (context, index) {
                    final article = educationalArticles[index];
                    return Padding(
                      padding: EdgeInsets.only(right: index == educationalArticles.length - 1 ? 0 : 12),
                      child: _buildArticleCard(article: article),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Kapan Harus Ke Dokter? — navigasi ke WhenToSeeDoctorScreen (Clickable!)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WhenToSeeDoctorScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9EAEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF0D5D8)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFB81018), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kapan Harus Ke Dokter?',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFFB81018),
                                ),
                              ),
                              Text(
                                'Kenali gejala yang perlu penanganan medis segera',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Pelajari',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFFB81018),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFFB81018)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pengingat Section Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9EAEB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFB81018)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengingat Minum Obat',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFFB81018),
                          ),
                        ),
                        Text(
                          'Kelola jadwal rutin obat Anda',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddReminderSheet,
                    icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F0D12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                    ),
                    label: Text(
                      'Tambah',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Daftar Pengingat Interaktif
              if (_reminders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEEEEEE)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.alarm_off_rounded, size: 40, color: Color(0xFFBDBDBD)),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada pengingat obat',
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF757575)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tekan "+ Tambah" untuk membuat pengingat baru',
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                )
              else
                ..._reminders.map((rem) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildReminderCard(rem),
                    )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildArticleCard({
    required EducationArticle article,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 170,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF9EAEB), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 96,
                decoration: BoxDecoration(
                  color: article.imageBgColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(article.iconData, color: article.categoryColor.withValues(alpha: 0.5), size: 46),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          article.readTime,
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF424242),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.category,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: article.categoryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141414),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: const Color(0xFF757575),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Baca artikel',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB81018),
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_rounded, size: 10, color: Color(0xFFB81018)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(MedicationReminder rem) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showReminderOptions(rem),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: rem.isTakenToday ? const Color(0xFFF6FAF6) : const Color(0xFFFDFBFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: rem.isTakenToday ? const Color(0xFFA5D6A7) : const Color(0xFFEADBDB),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: rem.isTakenToday ? const Color(0xFFE8F5E9) : const Color(0xFFF9EAEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  rem.iconData,
                  color: rem.isTakenToday ? const Color(0xFF2E7D32) : const Color(0xFF8F0D12),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            rem.medicineName,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: rem.isTakenToday ? const Color(0xFF2E7D32) : const Color(0xFF8F0D12),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rem.isTakenToday) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF81C784), width: 0.8),
                            ),
                            child: Text(
                              'Sudah Diminum ✓',
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rem.dosage,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF616161),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.repeat_rounded, size: 12, color: Color(0xFFB81018)),
                        const SizedBox(width: 4),
                        Text(
                          rem.schedule,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• Tekan opsi',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: const Color(0xFF9E9E9E),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    rem.time,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: rem.isActive ? const Color(0xFFB81018) : const Color(0xFF9E9E9E),
                    ),
                  ),
                  Text(
                    'Hari ini',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 24,
                    width: 44,
                    child: Switch(
                      value: rem.isActive,
                      onChanged: (val) => _toggleReminder(rem, val),
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFFF06292),
                      inactiveThumbColor: const Color(0xFFD81B60),
                      inactiveTrackColor: Colors.transparent,
                      trackOutlineColor: WidgetStateProperty.resolveWith(
                        (states) => const Color(0xFFF8BBD0),
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
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFAF1F1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            tooltip: 'Dashboard Utama',
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
          _buildNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Konsultasi Dokter',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationListScreen(),
                ),
              );
            },
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            tooltip: 'Rekam Medis Pasien',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicalRecordsScreen(),
                ),
              );
            },
          ),
          _buildNavItem(
            icon: Icons.calendar_month_outlined,
            tooltip: 'Riwayat Resep & Jadwal',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RiwayatResepScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 26,
            color: const Color(0xFFD65C62),
          ),
        ),
      ),
    );
  }
}
