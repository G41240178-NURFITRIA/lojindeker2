import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/profile_image_service.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';

import 'edit_profile_screen.dart';
import 'account_settings_screen.dart';
import 'consultation_list_screen.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/landing_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  final String patientName;
  final VoidCallback? onBackToHome;
  final ValueChanged<String>? onProfileUpdated;
  final VoidCallback? onLogout;
  final bool isTab;

  const PatientProfileScreen({
    super.key,
    this.patientName = 'Pasien',
    this.onBackToHome,
    this.onProfileUpdated,
    this.onLogout,
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

  @override
  void didUpdateWidget(covariant PatientProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientName != widget.patientName) {
      _currentName = widget.patientName;
    }
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
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (widget.onLogout != null) {
                            widget.onLogout!();
                            return;
                          }
                          await AuthService.instance.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) => const LandingScreen(),
                              ),
                              (route) => false,
                            );
                          }
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

  void _showPhotoPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto ini akan ditampilkan di profil dan di ruang pesan konsultasi dokter.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: _darkRose),
                  ),
                  title: Text(
                    'Pilih dari Galeri / File',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Pilih foto dari galeri atau komputer Anda',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await ProfileImageService().pickImageFromGallery();
                    if (path != null) {
                      await ProfileImageService().saveProfilePhoto(path, displayName: _currentName);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Foto profil berhasil diperbarui!',
                              style: GoogleFonts.poppins(fontSize: 12.5),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: _darkRose),
                  ),
                  title: Text(
                    'Ambil Foto dengan Kamera',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Gunakan kamera untuk mengambil potret langsung',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await ProfileImageService().pickImageFromCamera();
                    if (path != null) {
                      await ProfileImageService().saveProfilePhoto(path, displayName: _currentName);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Foto profil berhasil diambil & disimpan!',
                              style: GoogleFonts.poppins(fontSize: 12.5),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.face_retouching_natural_rounded, color: _darkRose),
                  ),
                  title: Text(
                    'Pilih Avatar Karakter',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Pilih avatar ilustrasi kesehatan',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetAvatarsDialog(context);
                  },
                ),
                if (ProfileImageService().hasCustomImage()) ...[
                  const Divider(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F)),
                    ),
                    title: Text(
                      'Hapus Foto Profil',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                    subtitle: Text(
                      'Kembalikan avatar profil ke ikon bawaan',
                      style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                    ),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ProfileImageService().clearImage(displayName: _currentName);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Foto profil berhasil dihapus.',
                              style: GoogleFonts.poppins(fontSize: 12.5),
                            ),
                            backgroundColor: _darkRose,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPresetAvatarsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Pilih Avatar Karakter',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: _darkRose),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: ProfileImageService.presetAvatars.length,
            itemBuilder: (context, index) {
              final avatar = ProfileImageService.presetAvatars[index];
              return InkWell(
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  final url = avatar['url']!;
                  await ProfileImageService().saveProfilePhoto(url, displayName: _currentName);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Avatar "${avatar['title']}" berhasil diterapkan!',
                          style: GoogleFonts.poppins(fontSize: 12.5),
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(40),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _cardBorder, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatar['url']!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: _darkRose),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(color: _darkRose, fontWeight: FontWeight.w600),
            ),
          ),
        ],
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
            InkWell(
              onTap: () => _showPhotoPickerOptions(context),
              borderRadius: BorderRadius.circular(50),
              child: Stack(
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
                    child: ValueListenableBuilder<String?>(
                      valueListenable: ProfileImageService().profileImagePath,
                      builder: (context, imagePath, _) {
                        return DoctorAvatarWidget(
                          photoUrl: imagePath,
                          size: 96,
                          initials: _currentName.isNotEmpty ? _currentName[0] : null,
                          backgroundColor: _primaryPink,
                          iconColor: Colors.white,
                        );
                      },
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
                        widget.onProfileUpdated?.call(newName);
                      },
                    ),
                  ),
                );
                if (result != null && result.isNotEmpty) {
                  setState(() => _currentName = result);
                  widget.onProfileUpdated?.call(result);
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
              } else {
                Navigator.of(context).popUntil((route) => route.isFirst);
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
        ],
      ),
    );
  }
}