import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'live_chat_screen.dart';

class DoctorModel {
  final String id;
  final String name;
  final String initials;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String availabilityLabel;
  final String availabilityTime;
  final bool isOnline;

  const DoctorModel({
    required this.id,
    required this.name,
    required this.initials,
    required this.specialty,
    required this.rating,
    required this.reviewCount,
    required this.availabilityLabel,
    required this.availabilityTime,
    required this.isOnline,
  });
}

class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  final int _selectedBottomNavIndex = 1; // 1 = Chat / Konsultasi

  final List<DoctorModel> _doctors = const [
    DoctorModel(
      id: 'kaka',
      name: 'Dr. Kaka',
      initials: 'DK',
      specialty: 'Spesialis Penyakit Dalam',
      rating: 4.9,
      reviewCount: 120,
      availabilityLabel: 'Tersedia Hari Ini',
      availabilityTime: '14:00 - 17:00',
      isOnline: true,
    ),
    DoctorModel(
      id: 'ika',
      name: 'Dr. Ika',
      initials: 'DI',
      specialty: 'Spesialis Penyakit Dalam',
      rating: 4.9,
      reviewCount: 120,
      availabilityLabel: 'Tersedia Besok',
      availabilityTime: '9:00 - 14:00',
      isOnline: false,
    ),
  ];

  void _onChatPressed(DoctorModel doctor) {
    if (!doctor.isOnline) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveChatScreen(
          doctorName: doctor.name,
          specialty: doctor.specialty,
          initials: doctor.initials,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        titleSpacing: 0,
        title: Text(
          'Konsultasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const BouncingScrollPhysics(),
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          return _buildDoctorCard(doctor);
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Card Dokter sesuai screenshot referensi
  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profil Dokter: Avatar inisial, Nama, Spesialisasi, Rating
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Inisial
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    doctor.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Detail Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: Color(0xFF00C48C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} ulasan)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Info Ketersediaan & Badge Status (Online / Offline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFCF8F8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Jam Praktik
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.availabilityLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E8E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.availabilityTime,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ],
                ),

                // Badge Status
                if (doctor.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F8E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C48C),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00B074),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Tombol Chat (Aktif jika Online, Disabled jika Offline)
          InkWell(
            onTap: doctor.isOnline ? () => _onChatPressed(doctor) : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: doctor.isOnline
                      ? const Color(0xFFF8BBD0)
                      : const Color(0xFFEBEBEB),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: doctor.isOnline
                        ? const Color(0xFF222222)
                        : const Color(0xFFBDBDBD),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: doctor.isOnline
                          ? const Color(0xFF222222)
                          : const Color(0xFFBDBDBD),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar matching the app theme
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFFF0F5),
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
            onTap: () {}, // Current tab
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
        isSelected ? const Color(0xFFD81B60) : const Color(0xFFF48FB1);

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
