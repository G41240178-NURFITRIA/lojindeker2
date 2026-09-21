import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultation_list_screen.dart';
import 'medical_records_screen.dart';
import 'ai_risk_history_screen.dart';
import 'support_menu_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  final String patientName;

  const PatientDashboardScreen({
    super.key,
    this.patientName = 'Muhammad Nizam',
  });

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1F1), // Soft blush background
      body: Stack(
        children: [
          // Decorative soft curved organic shape at top right
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEED5D7).withValues(alpha: 0.8),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header (Static view, tidak bisa ditekan)
                _buildHeader(),

                // Scrollable Content
                Expanded(
                  child: _buildSelectedTabContent(),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (Hanya icon ini yang dapat ditekan)
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Top Header Bar (Hanya tampilan / Static view)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: 3 circular action icons (Tampilan saja)
          Row(
            children: [
              _buildCircleIcon(Icons.notifications_none_rounded),
              const SizedBox(width: 8),
              _buildCircleIcon(Icons.settings_outlined),
              const SizedBox(width: 8),
              _buildCircleIcon(Icons.search_rounded),
            ],
          ),

          // Right: "Hi, WelcomeBack", Patient Name, and Avatar (Tampilan saja)
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hi, WelcomeBack',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8B2326),
                    ),
                  ),
                  Text(
                    widget.patientName,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/doctor_avatar.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFB51419),
                            child: const Icon(Icons.person, color: Colors.white, size: 24),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(
                        Icons.medical_services_rounded,
                        size: 9,
                        color: Color(0xFFB51419),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIcon(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEADBDB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 18,
        color: const Color(0xFF333333),
      ),
    );
  }

  /// Dashboard Content 
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Layanan Utama
          Text(
            'Layanan Utama',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 14),

          // (Cek Risiko, Konsultasi, Kalender Kesehatan)
          Row(
            children: [
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  title: 'Cek Risiko',
                  onTap: () => _showFeatureDialog(
                    'Cek Risiko Diabetes',
                    'Fitur skrining dan kalkulator risiko diabetes melitus untuk mendeteksi dini komplikasi dan memantau gaya hidup sehat.',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                  title: 'Konsultasi',
                  onTap: () => setState(() => _selectedTabIndex = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 28),
                  title: 'Kalender\nKesehatan',
                  onTap: () => setState(() => _selectedTabIndex = 3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // (Rekam Medis, Menu Penunjang)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 125,
                child: _buildServiceCard(
                  icon: const Icon(Icons.folder_shared_outlined, color: Colors.white, size: 28),
                  title: 'Rekam\nMedis',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AiRiskHistoryScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 125,
                child: _buildServiceCard(
                  icon: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                  title: 'Menu\nPenunjang',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SupportMenuScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Status Kesehatan Anda
          Text(
            'Status Kesehatan Anda',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Resiko Diabetes : ',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                    children: [
                      TextSpan(
                        text: 'Rendah',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2E7D32), // Green
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Berdasarkan pemeriksaan terakhir',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '20 Mei 2026',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. History
          Text(
            'History',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 12),

          _buildHistoryTile(
            icon: Icons.trending_up_rounded,
            iconColor: const Color(0xFFD32F2F),
            label: 'Highest Glucose',
<<<<<<< HEAD
            value: 'AFIETA',
=======
            value: '165',
>>>>>>> 34c68eb7c602b00ce37c6fbbb2e3425bcfce2210
            valueColor: const Color(0xFFD32F2F),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHistoryTile(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF616161),
            label: 'Average Glucose',
            value: '128',
            valueColor: const Color(0xFF141414),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          _buildHistoryTile(
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Lowest Glucose',
            value: '78',
            valueColor: const Color(0xFF2E7D32),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GlucoseHistoryScreen()),
              );
            },
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// Service Card 
  Widget _buildServiceCard({
    required Widget icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 106,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF8F0D12),
                Color(0xFFBA171E),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8F0D12).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 32,
                child: Center(child: icon),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// History Tile 
  Widget _buildHistoryTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF424242),
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  text: value,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor,
                  ),
                  children: [
                    TextSpan(
                      text: ' mg/dL',
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
        ),
      ),
    );
  }

  /// Bottom Navigation Bar 
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFAF1F1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined),
          _buildNavItem(1, Icons.chat_bubble_outline_rounded),
          _buildNavItem(2, Icons.person_outline_rounded),
          _buildNavItem(3, Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? const Color(0xFFBA171E) : const Color(0xFFD65C62);

    return InkWell(
<<<<<<< HEAD
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ConsultationScreen(),
            ),
          );
        } else {
          setState(() => _selectedTabIndex = index);
        }
      },
=======
      onTap: () => setState(() => _selectedTabIndex = index),
>>>>>>> 34c68eb7c602b00ce37c6fbbb2e3425bcfce2210
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 26,
          color: color,
        ),
<<<<<<< HEAD
=======
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildConsultationTab();
      case 2:
        return _buildProfileTab();
      case 3:
        return _buildCalendarTab();
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildConsultationTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Konsultasi Dokter',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
          ),
          const SizedBox(height: 6),
          Text(
            'Hubungi dokter spesialis untuk evaluasi kondisi diabetes Anda.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          _buildDoctorCard(
            name: 'dr. Afieta Putri, Sp.PD',
            speciality: 'Spesialis Penyakit Dalam & Endokrin',
            hospital: 'RS D-Care Sejahtera',
            status: 'Online',
            statusColor: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: 12),
          _buildDoctorCard(
            name: 'dr. Hendra Wijaya, Sp.PD',
            speciality: 'Spesialis Penyakit Dalam',
            hospital: 'RS D-Care Sejahtera',
            status: 'Praktik Hari Ini',
            statusColor: const Color(0xFF1976D2),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard({
    required String name,
    required String speciality,
    required String hospital,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF1F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_rounded, color: Color(0xFFBA171E), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
                ),
                Text(
                  speciality,
                  style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFBA171E), fontWeight: FontWeight.w500),
                ),
                Text(
                  hospital,
                  style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profil Pasien',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBA171E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.patientName,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
                ),
                Text(
                  'No. RM: RM-2026-0812',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF757575)),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),
                _buildProfileRow('Jenis Kelamin', 'Laki-laki'),
                _buildProfileRow('Usia', '28 Tahun'),
                _buildProfileRow('Golongan Darah', 'O+'),
                _buildProfileRow('Diagnosis', 'Diabetes Melitus Tipe 2'),
                _buildProfileRow('Fasilitas Kesehatan', 'RS D-Care Sejahtera'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MedicalRecordsScreen(patientName: widget.patientName),
                  ),
                );
              },
              icon: const Icon(Icons.folder_shared_outlined, color: Color(0xFFBA171E)),
              label: Text(
                'Buka Rekam Medis Lengkap',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFFBA171E)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFFBA171E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF666666))),
          Text(value, style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF141414))),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kalender Kesehatan',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF141414)),
          ),
          const SizedBox(height: 6),
          Text(
            'Jadwal kontrol rutin dan pengingat konsumsi obat harian.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFAF1F1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.event_available_rounded, color: Color(0xFFBA171E), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kontrol Rutin Dokter', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text('20 Juni 2026 • 09:00 WIB', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFFBA171E), fontWeight: FontWeight.w600)),
                          Text('Poli Penyakit Dalam - dr. Afieta Putri, Sp.PD', style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFAF1F1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.medication_rounded, color: Color(0xFFBA171E), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Minum Metformin HCl 500 mg', style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w700)),
                          Text('Setiap Hari (07:00 & 19:00) • Sesudah Makan', style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureDialog(String title, String desc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF8F0D12)),
        ),
        content: Text(
          desc,
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF424242)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: GoogleFonts.poppins(color: const Color(0xFFBA171E), fontWeight: FontWeight.w600)),
          ),
        ],
>>>>>>> 34c68eb7c602b00ce37c6fbbb2e3425bcfce2210
      ),
    );
  }
}

/// Custom Doctor Outline Icon
class _DoctorOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _DoctorOutlineIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoctorOutlinePainter(color: color),
    );
  }
}

class _DoctorOutlinePainter extends CustomPainter {
  final Color color;

  _DoctorOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Doctor head
    canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.20, paint);

    // Doctor shoulders/torso
    final bodyPath = Path();
    bodyPath.moveTo(w * 0.15, h * 0.90);
    bodyPath.cubicTo(w * 0.15, h * 0.60, w * 0.35, h * 0.55, w * 0.50, h * 0.55);
    bodyPath.cubicTo(w * 0.65, h * 0.55, w * 0.85, h * 0.60, w * 0.85, h * 0.90);
    canvas.drawPath(bodyPath, paint);

    // Stethoscope loop around neck
    final stethPath = Path();
    stethPath.moveTo(w * 0.38, h * 0.55);
    stethPath.cubicTo(w * 0.38, h * 0.72, w * 0.62, h * 0.72, w * 0.62, h * 0.55);
    stethPath.moveTo(w * 0.50, h * 0.68);
    stethPath.lineTo(w * 0.50, h * 0.80);
    canvas.drawPath(stethPath, paint..strokeWidth = 1.4);

    // Stethoscope bell
    canvas.drawCircle(Offset(w * 0.50, h * 0.82), 1.8, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
