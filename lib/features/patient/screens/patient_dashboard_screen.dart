import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultation_screen.dart';
import 'risk_check_screen.dart';

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
                  child: _selectedTabIndex == 0
                      ? _buildDashboardContent()
                      : const SizedBox.shrink(), // Placeholder kosong untuk tab lain
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
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiskCheckScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                  title: 'Konsultasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildServiceCard(
                  icon: const Icon(Icons.calendar_month_outlined, color: Colors.white, size: 28),
                  title: 'Kalender\nKesehatan',
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
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 125,
                child: _buildServiceCard(
                  icon: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
                  title: 'Menu\nPenunjang',
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
            value: 'AFIETA',
            valueColor: const Color(0xFFD32F2F),
          ),
          const SizedBox(height: 10),
          _buildHistoryTile(
            icon: Icons.show_chart_rounded,
            iconColor: const Color(0xFF616161),
            label: 'Average Glucose',
            value: 'FITRI',
            valueColor: const Color(0xFF141414),
          ),
          const SizedBox(height: 10),
          _buildHistoryTile(
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFF2E7D32),
            label: 'Lowest Glucose',
            value: 'AGATHA',
            valueColor: const Color(0xFF2E7D32),
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
  }) {
    return Container(
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
