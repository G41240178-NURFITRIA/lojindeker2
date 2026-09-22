import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'edit_profile_screen.dart';
import 'account_settings_screen.dart';
import 'consultation_list_screen.dart';
import '../../auth/screens/landing_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientName;
  final VoidCallback? onBackToHome;
  final bool isTab;

  const PatientProfileScreen({
    super.key,
    this.patientName = 'Muhammad Nizam',
    this.onBackToHome,
    this.isTab = false,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  late String _currentName;

  static const Color _bgScreen = Color(0xFFFFF0F5);
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _darkRose = Color(0xFFD81B60);
  static const Color _cardBorder = Color(0xFFF8BBD0);
  static const Color _navIconInactive = Color(0xFFEFB3B5);
  static const Color _navIconActive = Color(0xFFD81B60);

  @override
  void initState() {
    super.initState();
    _currentName = widget.patientName;
  }

  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _darkRose,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Apakah Anda yakin ingin keluar dari akun Anda?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const LandingScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkRose,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'Yes, Logout',
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bantuan & Dukungan',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _darkRose,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.support_agent_rounded,
                  color: _primaryPink,
                  size: 28,
                ),
                title: Text(
                  'Customer Care D-Care',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Hubungi tim layanan 24/7 melalui WhatsApp atau Call Center',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF666666),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: _darkRose,
                ),
                onTap: () => Navigator.pop(ctx),
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.menu_book_rounded,
                  color: _primaryPink,
                  size: 28,
                ),
                title: Text(
                  'Panduan & FAQ Aplikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Pelajari cara menggunakan fitur monitoring, konsultasi, dan cek risiko',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF666666),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: _darkRose,
                ),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: _darkRose,
                    size: 20,
                  ),
                  onPressed: () {
                    if (widget.onBackToHome != null) {
                      widget.onBackToHome!();
                    } else if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    'My Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _darkRose,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile Avatar with Camera badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: _darkRose.withValues(alpha: 0.18),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/doctor_avatar.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _primaryPink,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 52,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 2,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _darkRose,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Patient Name
            Text(
              _currentName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141414),
              ),
            ),
            const SizedBox(height: 28),

            // 1. Profile (Edit Profile)
            _buildMenuItem(
              icon: Icons.person_outline_rounded,
              title: 'Profile',
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      patientName: _currentName,
                      onProfileUpdated: (newName) {
                        setState(() => _currentName = newName);
                      },
                    ),
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  setState(() => _currentName = result);
                }
              },
            ),
            const SizedBox(height: 14),

            // 2. Settings (Password Manager & Delete Account)
            _buildMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // 3. Help
            _buildMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Help',
              onTap: () => _showHelpDialog(context),
            ),
            const SizedBox(height: 14),

            // 4. Logout
            _buildMenuItem(
              icon: Icons.logout_rounded,
              title: 'Logout',
              onTap: () => _showLogoutBottomSheet(context),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (widget.isTab) {
      return Container(color: _bgScreen, child: content);
    }

    return Scaffold(
      backgroundColor: _bgScreen,
      body: content,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _cardBorder.withValues(alpha: 0.7),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryPink.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _darkRose, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF222222),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _darkRose,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 64,
      color: _bgScreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 28),
            color: _navIconInactive,
            onPressed: () {
              if (widget.onBackToHome != null) {
                widget.onBackToHome!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
            color: _navIconInactive,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationListScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, size: 28),
            color: _navIconActive,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, size: 26),
            color: _navIconInactive,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
