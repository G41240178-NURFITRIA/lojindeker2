import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Color Palette disesuaikan dengan gambar UI 1 & 2
  static const Color _bgScreen = Color(0xFFECE3DF); // Background krem/pink soft
  static const Color _darkRose = Color(
    0xFFC84B53,
  ); // Merah/pink tua teks avatar & tombol
  static const Color _avatarBg = Color(
    0xFFF9EAEB,
  ); // Background lingkaran avatar
  static const Color _cardInnerBg = Color(
    0xFFFAF5F5,
  ); // Background box jam praktik
  static const Color _iconInactive = Color(
    0xFFEF9A9A,
  ); // Pink soft icon bottom nav

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
      backgroundColor: _bgScreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF2B2B2B),
            size: 32,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        titleSpacing: -4,
        title: Text(
          'Konsultasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2B2B2B),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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

  /// Card Dokter persis sesuai screenshot 1
  Widget _buildDoctorCard(DoctorModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profil Dokter (Avatar, Nama, Spesialisasi, Rating)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Inisial Soft Pink
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: _avatarBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    doctor.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _darkRose,
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
                    const SizedBox(height: 2),
                    Text(
                      doctor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Color(0xFF00C48C),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} ulasan)',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Info Ketersediaan & Badge Status (Online / Offline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _cardInnerBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.availabilityLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.availabilityTime,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D2D2D),
                      ),
                    ),
                  ],
                ),

                // Status Badge
                if (doctor.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4F7E7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF00C48C),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
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
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Offline',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. Tombol Chat
          InkWell(
            onTap: doctor.isOnline ? () => _onChatPressed(doctor) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: doctor.isOnline
                      ? const Color(0xFFF0E0E0)
                      : const Color(0xFFF2F2F2),
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
                        ? const Color(0xFF4A4A4A)
                        : const Color(0xFFCCCCCC),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chat',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: doctor.isOnline
                          ? const Color(0xFF333333)
                          : const Color(0xFFCCCCCC),
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

  /// Bottom Navigation Bar soft pink
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68,
      decoration: const BoxDecoration(color: _bgScreen),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.home_outlined,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
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
    final color = isSelected ? _darkRose : _iconInactive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 26, color: color),
      ),
    );
  }
}
