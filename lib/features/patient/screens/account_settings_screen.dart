import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'password_manager_screen.dart';
import '../../auth/screens/landing_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  static const Color _bgScreen = Color(0xFFFFF0F5);
  static const Color _darkRose = Color(0xFFD81B60);
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _cardBorder = Color(0xFFF8BBD0);

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          'Hapus Akun',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC62828),
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun Anda secara permanen? Data rekam medis dan riwayat kesehatan akan dihapus.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF777777)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Ya, Hapus',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _darkRose,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _darkRose,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Password Manager
              _buildSettingsTile(
                icon: Icons.vpn_key_outlined,
                title: 'Password Manager',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PasswordManagerScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Delete Account
              _buildSettingsTile(
                icon: Icons.person_remove_outlined,
                title: 'Delete Account',
                isDestructive: true,
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final textColor = isDestructive ? const Color(0xFFC62828) : const Color(0xFF222222);
    final iconColor = isDestructive ? const Color(0xFFC62828) : _darkRose;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder.withValues(alpha: 0.7), width: 1),
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
                decoration: BoxDecoration(
                  color: isDestructive
                      ? const Color(0xFFFFEBEE)
                      : const Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive ? const Color(0xFFC62828) : _darkRose,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
