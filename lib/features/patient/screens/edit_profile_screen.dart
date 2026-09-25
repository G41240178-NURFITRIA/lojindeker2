import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_image_service.dart';
import 'consultation_list_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final String patientName;
  final ValueChanged<String>? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    this.patientName = 'Pasien',
    this.onProfileUpdated,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;

  String? _selectedImagePath;
  String _accountUsername = '';

  static const Color _bgScreen = Color(0xFFFFF0F5);
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _darkRose = Color(0xFFD81B60);
  static const Color _inputFill = Color(0xFFFCE4EC);
  static const Color _inputBorder = Color(0xFFF8BBD0);
  static const Color _navIconInactive = Color(0xFFEFB3B5);
  static const Color _navIconActive = Color(0xFFD81B60);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patientName);
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _dobController = TextEditingController();
    _selectedImagePath = ProfileImageService().profileImagePath.value;
    _loadUserData();
  }

  void _loadUserData() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null && mounted) {
          final data = doc.data()!;
          setState(() {
            _accountUsername = data['username']?.toString() ?? '';
            if (_phoneController.text.isEmpty && data['phoneNumber'] != null) {
              _phoneController.text = data['phoneNumber'].toString();
            }
            if (_emailController.text.isEmpty) {
              _emailController.text = data['email']?.toString() ?? user.email ?? '';
            }
            if (_dobController.text.isEmpty && data['dob'] != null) {
              _dobController.text = data['dob'].toString();
            }
            final name = data['fullName'] ?? data['profileName'] ?? data['name'];
            if (name != null && name.toString().trim().isNotEmpty) {
              _nameController.text = name.toString().trim();
            }
          });
        }
      } catch (e) {
        debugPrint('Error loading user data in edit profile: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _showPhotoPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ganti Foto Profil',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _darkRose,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: _darkRose),
                  ),
                  title: Text(
                    'Pilih dari Galeri HP',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Gunakan foto dari galeri perangkat Anda',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF757575)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await ProfileImageService().pickImageFromGallery();
                    if (path != null) {
                      setState(() {
                        _selectedImagePath = path;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Foto berhasil dipilih dari galeri!',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: _darkRose),
                  ),
                  title: Text(
                    'Ambil Foto dengan Kamera',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Ambil potret langsung dari kamera ponsel',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF757575)),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final path = await ProfileImageService().pickImageFromCamera();
                    if (path != null) {
                      setState(() {
                        _selectedImagePath = path;
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Foto berhasil diambil dari kamera!',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (_selectedImagePath != null) ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                    ),
                    title: Text(
                      'Hapus Foto Kustom',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ProfileImageService().clearImage();
                      setState(() {
                        _selectedImagePath = null;
                      });
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

  void _handleUpdateProfile() async {
    final updatedName = _nameController.text.trim();
    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Username profil tidak boleh kosong',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: _darkRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    if (_selectedImagePath != null) {
      ProfileImageService().profileImagePath.value = _selectedImagePath;
    }

    // Simpan permanen perubahan Username Profil ke Firestore (TIDAK menyentuh username akun login)
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser != null) {
        final Map<String, dynamic> updateData = {
          'fullName': updatedName,
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (_phoneController.text.trim().isNotEmpty) {
          updateData['phoneNumber'] = _phoneController.text.trim();
        }
        if (_dobController.text.trim().isNotEmpty) {
          updateData['dob'] = _dobController.text.trim();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set(updateData, SetOptions(merge: true));

        await currentUser.updateDisplayName(updatedName);
      }
    } catch (e) {
      debugPrint('Error updating profile in Firestore: $e');
    }

    widget.onProfileUpdated?.call(updatedName);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profil berhasil diperbarui!',
          style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    Navigator.pop(context, updatedName);
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
          'Profile',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _darkRose,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: _darkRose, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with camera badge (Clickable to pick from gallery)
              Center(
                child: InkWell(
                  onTap: _showPhotoPickerOptions,
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
                              color: _darkRose.withValues(alpha: 0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _selectedImagePath != null &&
                                  File(_selectedImagePath!).existsSync()
                              ? Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _primaryPink,
                                      child: const Icon(Icons.person, color: Colors.white, size: 48),
                                    );
                                  },
                                )
                              : Image.asset(
                                  'assets/images/doctor_avatar.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: _primaryPink,
                                      child: const Icon(Icons.person, color: Colors.white, size: 48),
                                    );
                                  },
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 30,
                          height: 30,
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
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _showPhotoPickerOptions,
                  icon: const Icon(Icons.photo_library_outlined, size: 16, color: _darkRose),
                  label: Text(
                    'Pilih Foto dari Galeri',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _darkRose,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Username Akun (Hanya baca / login credential tetap)
              if (_accountUsername.isNotEmpty) ...[
                _buildFieldLabel('Username Akun (Login)'),
                const SizedBox(height: 6),
                _buildReadOnlyField(value: _accountUsername),
                const SizedBox(height: 16),
              ],

              // Username Profil
              _buildFieldLabel('Username Profil'),
              const SizedBox(height: 6),
              _buildInputField(controller: _nameController, hintText: 'Masukkan username profil'),
              const SizedBox(height: 16),

              // Phone Number
              _buildFieldLabel('Phone Number'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _phoneController,
                hintText: 'Masukkan nomor telepon',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email
              _buildFieldLabel('Email'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _emailController,
                hintText: 'Masukkan alamat email',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Date Of Birth
              _buildFieldLabel('Date Of Birth'),
              const SizedBox(height: 6),
              _buildInputField(
                controller: _dobController,
                hintText: 'DD / MM / YYYY',
                suffixIcon: Icons.calendar_today_outlined,
              ),
              const SizedBox(height: 32),

              // Update Profile Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleUpdateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: _primaryPink.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Update Profile',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    IconData? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _inputFill.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _inputBorder, width: 1.0),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF222222)),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF999999)),
          suffixIcon: suffixIcon != null
              ? Icon(suffixIcon, size: 18, color: const Color(0xFF777777))
              : null,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({required String value}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF616161),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(
            Icons.lock_outline_rounded,
            size: 18,
            color: Color(0xFF9E9E9E),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar (3 Ikon yang Berfungsi)
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: _bgScreen,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, size: 28),
            color: _navIconInactive,
            tooltip: 'Beranda',
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
            color: _navIconInactive,
            tooltip: 'Konsultasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConsultationListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, size: 28),
            color: _navIconActive,
            tooltip: 'Profil',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
