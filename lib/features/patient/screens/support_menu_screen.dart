import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'when_to_see_doctor_screen.dart';

class SupportMenuScreen extends StatelessWidget {
  const SupportMenuScreen({super.key});

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

              // Edukasi Diabetes
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
                  Column(
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
                ],
              ),
              const SizedBox(height: 16),

              // Horizontal list of articles
              SizedBox(
                height: 230,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildArticleCard(
                      imageBgColor: const Color(0xFFFBE9E7),
                      category: 'Pola Makan',
                      title: 'Pola Makan Sehat Untuk Diabetes',
                      subtitle: 'Tips Memilih Makanan Sehari-Hari Yang Aman Untuk Gula Darah',
                      iconData: Icons.restaurant_menu_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildArticleCard(
                      imageBgColor: const Color(0xFFF3E5F5),
                      category: 'Aktivitas Fisik',
                      title: 'Olahraga Yang Aman Untuk Penderita Diabetes',
                      subtitle: 'Jenis Olahraga Yang Aman Dan Bermanfaat Menjaga Gula Darah',
                      iconData: Icons.directions_run_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildArticleCard(
                      imageBgColor: const Color(0xFFEFEBE9),
                      category: 'Monitoring',
                      title: 'Cara Memantau Gula Darah Di Rumah',
                      subtitle: 'Panduan Mudah Memantau Gula Darah Secara Mandiri',
                      iconData: Icons.monitor_heart_rounded,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Kapan Harus Ke Dokter? — navigasi ke WhenToSeeDoctorScreen
              GestureDetector(
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pelajari selengkapnya >',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: const Color(0xFFB81018),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Pengingat Section
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
                          'Pengingat',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFFB81018),
                          ),
                        ),
                        Text(
                          'Kelola pengingat minum obat anda',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF616161),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8F0D12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      '+ Tambah Pengingat',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Reminder Items
              _buildReminderCard(
                medicineName: 'Metaformin 500 Mg',
                dosage: '1 tablet - Setelah makan',
                schedule: 'Setiap 12 jam',
                time: '08:00',
                isActive: true,
                iconData: Icons.medication_rounded,
              ),
              const SizedBox(height: 12),
              _buildReminderCard(
                medicineName: 'Glimepiride 2mg',
                dosage: '1 tablet - Sebelum makan',
                schedule: 'Setiap 24 jam',
                time: '20:00',
                isActive: false,
                iconData: Icons.medication_liquid_rounded,
              ),
              const SizedBox(height: 12),
              _buildReminderCard(
                medicineName: 'Glimepiride 2mg',
                dosage: '1 tablet - Sebelum makan',
                schedule: 'Setiap 24 jam',
                time: '08:00',
                isActive: true,
                iconData: Icons.medication_liquid_rounded,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildArticleCard({
    required Color imageBgColor,
    required String category,
    required String title,
    required String subtitle,
    required IconData iconData,
  }) {
    return Container(
      width: 165,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF9EAEB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: imageBgColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Center(
              child: Icon(iconData, color: Colors.black26, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB81018),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF141414),
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: const Color(0xFF757575),
                    height: 1.2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderCard({
    required String medicineName,
    required String dosage,
    required String schedule,
    required String time,
    required bool isActive,
    required IconData iconData,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBDB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9EAEB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: const Color(0xFF8F0D12), size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicineName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8F0D12),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dosage,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFFB81018)),
                    const SizedBox(width: 4),
                    Text(
                      schedule,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF757575),
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
                time,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB81018),
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
                  value: isActive,
                  onChanged: (val) {},
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
          _buildNavItem(Icons.home_outlined),
          _buildNavItem(Icons.chat_bubble_outline_rounded),
          _buildNavItem(Icons.person_outline_rounded),
          _buildNavItem(Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 26,
          color: const Color(0xFFD65C62),
        ),
      ),
    );
  }
}
