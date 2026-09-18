import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'riwayat_resep_screen.dart';

class DetailResepScreen extends StatefulWidget {
  final String date;
  final String status;
  final String doctorName;
  final String doctorSpecialty;
  final List<MedicineModel> medicines;
  final String doctorNotes;
  final bool isReminderActive;

  const DetailResepScreen({
    super.key,
    required this.date,
    required this.status,
    required this.doctorName,
    this.doctorSpecialty = 'Sp. Penyakit Dalam',
    required this.medicines,
    required this.doctorNotes,
    this.isReminderActive = true,
  });

  factory DetailResepScreen.fromPrescription(PrescriptionModel prescription) {
    return DetailResepScreen(
      date: prescription.date,
      status: prescription.status,
      doctorName: prescription.doctorName,
      doctorSpecialty: prescription.doctorSpecialty,
      medicines: prescription.medicines,
      doctorNotes: prescription.notes,
      isReminderActive: prescription.isActive,
    );
  }

  @override
  State<DetailResepScreen> createState() => _DetailResepScreenState();
}

class _DetailResepScreenState extends State<DetailResepScreen> {
  final int _selectedBottomNavIndex = 3; // Calendar / Schedule icon

  bool get _isActive => widget.status.toLowerCase() == 'aktif';

  void _showSetReminderDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0D0D0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Atur Jadwal Pengingat',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8B1317),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notifikasi otomatis akan dikirim ke perangkat Anda sesuai waktu makan.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildReminderTimeTile('Pagi (Sesudah Sarapan)', '07:00 WIB', true),
                    _buildReminderTimeTile('Siang (Sesudah Makan Siang)', '13:00 WIB', true),
                    _buildReminderTimeTile('Malam (Sebelum Tidur)', '21:00 WIB', false),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jadwal pengingat obat berhasil diperbarui!'),
                              backgroundColor: Color(0xFF1B8738),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFBA171E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Simpan Pengingat',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  Widget _buildReminderTimeTile(String label, String time, bool initialVal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3DCDC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF222222),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFFBA171E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.alarm_on_rounded,
            color: Color(0xFFBA171E),
            size: 22,
          ),
        ],
      ),
    );
  }

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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Detail Resep Obat',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Info Header Section: Date, Status, Doctor, Specialty
            _buildInfoHeaderSection(),

            const SizedBox(height: 20),

            // 2. Section: Daftar Obat
            Text(
              'Daftar Obat',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            ...widget.medicines.map((med) => _buildMedicineCard(med)),

            const SizedBox(height: 20),

            // 3. Section: Catatan Dokter
            Text(
              'Catatan Dokter',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E1E),
              ),
            ),
            const SizedBox(height: 8),
            _buildDoctorNotesCard(),

            const SizedBox(height: 28),

            // 4. Conditional Bottom Status / Reminder
            _buildConditionalStatusSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Header Info: Calendar + Date on left, Status badge on right, Doctor & Specialty below
  Widget _buildInfoHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Date with red calendar icon
            Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 20,
                  color: Color(0xFFBA171E),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.date,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _isActive
                    ? const Color(0xFFE2F8E7)
                    : const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.status,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _isActive
                      ? const Color(0xFF1B8738)
                      : const Color(0xFF757575),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          widget.doctorName,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.doctorSpecialty,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// Individual medicine card with red outline
  Widget _buildMedicineCard(MedicineModel med) {
    final bool isBottle = med.isBottle ||
        med.name.toLowerCase().contains('vitamin') ||
        med.quantity.toLowerCase().contains('kapsul') ||
        med.quantity.toLowerCase().contains('botol');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD64D52),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Icon on left (Capsule or Bottle)
          isBottle ? _buildCustomBottleIcon() : _buildCustomPillIcon(),

          const SizedBox(width: 12),

          // Medicine details
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
                    color: const Color(0xFF424242),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jumlah: ${med.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Custom capsule/pill icon (angled 45 degrees, upper red, lower white)
  Widget _buildCustomPillIcon() {
    return Transform.rotate(
      angle: -0.7,
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

  /// Custom supplement bottle icon matching screenshot 2 (Vitamin D3)
  Widget _buildCustomBottleIcon() {
    return Container(
      width: 18,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFBA171E),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFBA171E),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFBA171E),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Doctor notes card
  Widget _buildDoctorNotesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD64D52),
          width: 1.2,
        ),
      ),
      child: Text(
        widget.doctorNotes,
        style: GoogleFonts.poppins(
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF222222),
        ),
      ),
    );
  }

  /// Conditional Section depending on status
  Widget _buildConditionalStatusSection() {
    if (_isActive) {
      // Status Aktif: Yellow card + "Atur Pengingat" button
      return Column(
        children: [
          // Pale yellow reminder card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF7D6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFFDE68A),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: Color(0xFFB45309),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Pengingat minum obat sudah aktif untuk resep ini',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF854D0E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Solid Maroon Button: Atur Pengingat
          InkWell(
            onTap: _showSetReminderDialog,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF7D0E12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  'Atur Pengingat',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Status Selesai: Grey card with green checkmark
      return Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD6D6D6),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 13,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Masa konsumsi resep ini sudah selesai',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF424242),
              ),
            ),
          ],
        ),
      );
    }
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
