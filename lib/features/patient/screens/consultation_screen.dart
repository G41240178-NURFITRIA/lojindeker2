import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'doctor_chat_screen.dart';

class DoctorConsultationModel {
  final String id;
  final String name;
  final String initials;
  final String specialty;
  final double rating;
  final int reviewCount;
  final String availabilityLabel;
  final String availabilityTime;
  final bool isOnline;

  const DoctorConsultationModel({
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

class ConsultationScreen extends StatefulWidget {
  const ConsultationScreen({super.key});

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  final int _selectedTabIndex = 1; // 1 = Chat / Konsultasi

  final List<DoctorConsultationModel> _doctors = const [
    DoctorConsultationModel(
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
    DoctorConsultationModel(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECEB), // Warm soft blush background
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar / Header (< Konsultasi)
            _buildHeader(context),

            // Doctor list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _doctors.length,
                itemBuilder: (context, index) {
                  return _buildDoctorCard(context, _doctors[index]);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  /// Top Header Bar matching "< Konsultasi"
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: Color(0xFF141414),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Konsultasi',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
        ],
      ),
    );
  }

  /// Doctor Card
  Widget _buildDoctorCard(BuildContext context, DoctorConsultationModel doctor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Section: Avatar + Doctor Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular avatar with initials
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFDECEE), // Soft pastel pink/peach
                ),
                child: Center(
                  child: Text(
                    doctor.initials,
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8B2326), // Brand deep red
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Doctor details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2429),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doctor.specialty,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFF00C48C), // Vibrant green star
                          size: 19,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F2429),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} ulasan)',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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

          // 2. Middle Section: Schedule & Online/Offline status box
          Container(
            margin: const EdgeInsets.only(top: 18, bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Availability info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.availabilityLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      doctor.availabilityTime,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2429),
                      ),
                    ),
                  ],
                ),

                // Status Badge (Online / Offline)
                doctor.isOnline
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5F8E6),
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
                    : Container(
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
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
              ],
            ),
          ),

          // 3. Bottom Section: Chat Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorChatScreen(
                      doctorName: doctor.name,
                      initials: doctor.initials,
                      specialty: doctor.specialty,
                      isOnline: doctor.isOnline,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: doctor.isOnline
                        ? const Color(0xFFE2E4E8)
                        : const Color(0xFFE8EBEF),
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
                          ? const Color(0xFF374151)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chat',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: doctor.isOnline
                            ? const Color(0xFF374151)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar matching the bottom navigation bar in the screenshot
  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFFF6ECEB),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context,
            index: 0,
            icon: Icons.home_outlined,
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          _buildNavItem(
            context,
            index: 1,
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {}, // Already on Chat / Consultation
          ),
          _buildNavItem(
            context,
            index: 2,
            icon: Icons.person_outline_rounded,
            onTap: () {},
          ),
          _buildNavItem(
            context,
            index: 3,
            icon: Icons.calendar_month_outlined,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = _selectedTabIndex == index;
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
