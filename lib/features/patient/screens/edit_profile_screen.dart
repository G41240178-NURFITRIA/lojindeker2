import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileScreen extends StatefulWidget {
  final String patientName;
  final ValueChanged<String>? onProfileUpdated;

  const EditProfileScreen({
    super.key,
    this.patientName = 'Muhammad Nizam',
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
    _phoneController = TextEditingController(text: '+123 567 89000');
    _emailController = TextEditingController(text: 'johndoe@example.com');
    _dobController = TextEditingController(text: '15 / 08 / 1995');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _handleUpdateProfile() {
    final updatedName = _nameController.text.trim();
    if (updatedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nama tidak boleh kosong',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: _darkRose,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    widget.onProfileUpdated?.call(updatedName);

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
              // Avatar with camera badge
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _darkRose.withValues(alpha: 0.15),
                            blurRadius: 10,
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
              const SizedBox(height: 24),

              // Full Name
              _buildFieldLabel('Full Name'),
              const SizedBox(height: 6),
              _buildInputField(controller: _nameController, hintText: 'Masukkan nama lengkap'),
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
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 26),
            color: _navIconInactive,
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.person_rounded, size: 28),
            color: _navIconActive,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined, size: 26),
            color: _navIconInactive,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
