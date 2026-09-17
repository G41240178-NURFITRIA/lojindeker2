import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
                // Top Bar (Action icons on left, Profile greeting on right) - Static view
                _buildHeader(),

                // Content area
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildDashboardContent()
                      : const SizedBox.shrink(), // Belum berisi apa-apa untuk tab lain
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar (Hanya icon ini yang interaktif)
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
          // Left: 3 circular white action icons (Tampilan saja, tidak bisa ditekan)
          Row(
            children: [
              _buildCircleButton(Icons.notifications_none_rounded),
              const SizedBox(width: 8),
              _buildCircleButton(Icons.settings_outlined),
              const SizedBox(width: 8),
              _buildCircleButton(Icons.search_rounded),
            ],
          ),

          // Right: "Hi, WelcomeBack" and Avatar (Tampilan saja)
          Row(
            children: [
              Text(
                'Hi, WelcomeBack',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B2326),
                ),
              ),
              const SizedBox(width: 10),
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
                  // Small circular badge on bottom-right of avatar
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

  /// Circular Header Icon Widget (Static, tidak bisa ditekan)
  Widget _buildCircleButton(IconData icon) {
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

  /// Main Dashboard Content (Hanya tampilan / Static view, tidak bisa ditekan)
  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Manajemen User (Section Title)
          Text(
            'Manajemen User',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 14),

          // 2x2 Grid of Crimson Metric Cards (Tampilan saja)
          Row(
            children: [
              Expanded(
                child: _buildRedMetricCard(
                  iconWidget: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 28),
                  title: 'Total Pengguna',
                  value: '0',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRedMetricCard(
                  iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 28),
                  title: 'Total Dokter',
                  value: '0',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildRedMetricCard(
                  iconWidget: const _StethoscopeOutlineIcon(color: Colors.white, size: 28),
                  title: 'Konsultasi Hari ini',
                  value: '0',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildRedMetricCard(
                  iconWidget: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 28),
                  title: 'Cek Risiko AI',
                  value: '0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 2. Kelola Sistem (Section Title)
          Text(
            'Kelola Sistem',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 12),

          _buildManagementTile(
            iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 18),
            title: 'Kelola Dokter',
            subtitle: '0 dokter',
          ),
          const SizedBox(height: 10),
          _buildManagementTile(
            iconWidget: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
            title: 'Kelola Pengguna',
            subtitle: '0 dokter',
          ),
          const SizedBox(height: 10),
          _buildManagementTile(
            iconWidget: const _ArticlesOutlineIcon(color: Colors.white, size: 18),
            title: 'Kelola Artikel  Edukasi',
            subtitle: '0 dokter',
          ),

          const SizedBox(height: 24),

          // 3. Aktivitas Terbaru (Section Title)
          Text(
            'Aktivitas Terbaru',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActivityItem(
                  iconWidget: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 18),
                  title: 'Pengguna baru terdaftar',
                  subtitle: 'User dengan email rina@gmail.com',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: Color(0xFFEFE6E6)),
                ),
                _buildActivityItem(
                  iconWidget: const _DoctorOutlineIcon(color: Colors.white, size: 18),
                  title: 'Dokter baru ditambahkan',
                  subtitle: 'dr. Kaka Pratama',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  /// 2x2 Metric Card (Hanya tampilan / Static view)
  Widget _buildRedMetricCard({
    required Widget iconWidget,
    required String title,
    required String value,
  }) {
    return Container(
      height: 116,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 28,
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// System Management List Tile (Hanya tampilan / Static view)
  Widget _buildManagementTile({
    required Widget iconWidget,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFBA171E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F1F1F),
              ),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF1F1F1F),
            size: 22,
          ),
        ],
      ),
    );
  }

  /// Activity List Item (Hanya tampilan / Static view)
  Widget _buildActivityItem({
    required Widget iconWidget,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFBA171E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: iconWidget),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: const Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bottom Navigation Bar (4 Outline Icons - Hanya bagian ini yang dapat ditekan)
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFAF1F1), // Seamless flush blush tone
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
      onTap: () => setState(() => _selectedTabIndex = index),
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

/// Custom Stethoscope Outline Icon
class _StethoscopeOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _StethoscopeOutlineIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StethoscopeOutlinePainter(color: color),
    );
  }
}

class _StethoscopeOutlinePainter extends CustomPainter {
  final Color color;

  _StethoscopeOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Eartips
    canvas.drawCircle(Offset(w * 0.32, h * 0.18), 1.8, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(w * 0.68, h * 0.18), 1.8, Paint()..color = color..style = PaintingStyle.fill);

    // Binaural tubes curving to junction
    final path = Path();
    path.moveTo(w * 0.32, h * 0.18);
    path.cubicTo(w * 0.32, h * 0.42, w * 0.50, h * 0.46, w * 0.50, h * 0.56);

    final path2 = Path();
    path2.moveTo(w * 0.68, h * 0.18);
    path2.cubicTo(w * 0.68, h * 0.42, w * 0.50, h * 0.46, w * 0.50, h * 0.56);
    path.addPath(path2, Offset.zero);

    // Loop to chestpiece
    path.cubicTo(w * 0.50, h * 0.76, w * 0.82, h * 0.76, w * 0.82, h * 0.60);
    path.cubicTo(w * 0.82, h * 0.48, w * 0.70, h * 0.48, w * 0.70, h * 0.58);
    canvas.drawPath(path, paint);

    // Chestpiece (diaphragm)
    canvas.drawCircle(Offset(w * 0.70, h * 0.58), 2.5, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom Articles / Books Outline Icon
class _ArticlesOutlineIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _ArticlesOutlineIcon({required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _ArticlesOutlinePainter(color: color),
    );
  }
}

class _ArticlesOutlinePainter extends CustomPainter {
  final Color color;

  _ArticlesOutlinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Bookshelf line
    canvas.drawLine(Offset(w * 0.10, h * 0.85), Offset(w * 0.90, h * 0.85), paint);

    // Book 1
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.20, h * 0.22, w * 0.16, h * 0.63), const Radius.circular(2)),
      paint,
    );

    // Book 2
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.22, w * 0.16, h * 0.63), const Radius.circular(2)),
      paint,
    );

    // Book 3
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.64, h * 0.22, w * 0.16, h * 0.63), const Radius.circular(2)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
