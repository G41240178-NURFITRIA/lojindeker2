import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// Data Model diperbarui agar mendukung tampilan foto ke-1
class DoctorModel {
  final String id;
  final String name;
  final String initials;
  final String specialty;
  final String hospital;
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
    required this.hospital,
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
  final int _selectedBottomNavIndex = 1;

  // Warna sesuai sampel UI Foto ke-1 & ke-2
  static const Color _bgScreen = Color(0xFFF7EEEC);
  static const Color _avatarBg = Color(0xFFFCEAEA);
  static const Color _avatarText = Color(0xFF9E4044);
  static const Color _innerBoxBg = Color(0xFFFAF1F0);
  static const Color _greenOnlineBg = Color(0xFFD4F7E7);
  static const Color _greenText = Color(0xFF00B074);
  static const Color _navIconActive = Color(0xFFE56A6F);
  static const Color _navIconInactive = Color(0xFFEFB3B5);

  // Data Dokter dari Foto ke-2 yang disesuaikan ke UI Foto ke-1
  final List<DoctorModel> _doctors = const [
    DoctorModel(
      id: '1',
      name: 'dr. Afieta Putri, Sp.PD',
      initials: 'AP',
      specialty: 'Spesialis Penyakit Dalam & Endokrin',
      hospital: 'RS D-Care Sejahtera',
      rating: 4.9,
      reviewCount: 120,
      availabilityLabel: 'Tersedia Hari Ini',
      availabilityTime: '14:00 - 17:00',
      isOnline: true,
    ),
    DoctorModel(
      id: '2',
      name: 'dr. Hendra Wijaya, Sp.PD',
      initials: 'HW',
      specialty: 'Spesialis Penyakit Dalam',
      hospital: 'RS D-Care Sejahtera',
      rating: 4.8,
      reviewCount: 95,
      availabilityLabel: 'Praktik Hari Ini',
      availabilityTime: '09:00 - 14:00',
      isOnline: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgScreen,
      // AppBar diubah mengikuti Foto Ke-1
      appBar: AppBar(
        backgroundColor: _bgScreen,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        titleSpacing: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF1E1E1E),
            size: 32,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'Konsultasi',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF232323),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        physics: const BouncingScrollPhysics(),
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          return _buildDoctorCard(_doctors[index]);
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Desain Kartu Dokter Sesuai Foto Ke-1
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
          // 1. Profil Dokter (Avatar Inisial, Nama, Spesialis, Rating)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar Circle dengan Inisial Nama (Misal: AP / HW)
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
                      color: _avatarText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Detail Teks Dokter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8E8E8E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Rating & Ulasan (Foto 1)
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 17,
                          color: _greenText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          doctor.rating.toStringAsFixed(1),
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF262626),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${doctor.reviewCount} ulasan)',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
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

          const SizedBox(height: 16),

          // 2. Box Jadwal Praktik & Status (Foto 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _innerBoxBg,
              borderRadius: BorderRadius.circular(18),
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
                        color: const Color(0xFF989898),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.availabilityTime,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF262626),
                      ),
                    ),
                  ],
                ),
                if (doctor.isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _greenOnlineBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: _greenText,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _greenText,
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
                        color: const Color(0xFFC4C4C4),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. Tombol Chat di Bagian Bawah Kartu (Foto 1)
          InkWell(
            onTap: doctor.isOnline ? () {} : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: doctor.isOnline
                      ? const Color(0xFFE8E8E8)
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
                        ? const Color(0xFF333333)
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

  // Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: _bgScreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.home_outlined, size: 28, color: _navIconInactive),
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 26,
            color: _navIconActive,
          ),
          Icon(Icons.person_outline_rounded, size: 28, color: _navIconInactive),
          Icon(
            Icons.calendar_month_outlined,
            size: 26,
            color: _navIconInactive,
          ),
        ],
      ),
    );
  }
}
