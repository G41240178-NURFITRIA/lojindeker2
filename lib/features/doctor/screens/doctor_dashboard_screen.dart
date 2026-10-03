import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/auth_service.dart';
import '../../auth/screens/landing_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'doctor_all_chats_screen.dart';
import 'doctor_prescription_note_screen.dart';

/// Model chat pasien untuk dashboard dokter
class DoctorPatientChat {
  final String id;
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String glucoseNote;

  DoctorPatientChat({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    this.glucoseNote = 'Gula Darah: 142 mg/dL (Stabil)',
  });
}

class DoctorDashboardScreen extends StatefulWidget {
  final String doctorName;

  const DoctorDashboardScreen({
    super.key,
    this.doctorName = 'Dr. Kaka Pratama',
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedTabIndex = 0; // 0: Beranda, 1: Profil (Chat dan Pasien telah dihapus)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data pasien persis seperti pada desain gambar referensi
  late List<DoctorPatientChat> _chats;

  @override
  void initState() {
    super.initState();
    _chats = [
      DoctorPatientChat(
        id: '1',
        name: 'Widyatna Dwi',
        message: 'Baik dok, saya sudah minum obatnya.',
        time: '14:02',
        unreadCount: 2,
        glucoseNote: 'Gula Darah Puasa: 118 mg/dL',
      ),
      DoctorPatientChat(
        id: '2',
        name: 'Afista Putri K.',
        message: 'Baik dok, terima kasih banyak.',
        time: 'Kemarin',
        unreadCount: 0,
        glucoseNote: 'Gula Darah 2 Jam PP: 135 mg/dL',
      ),
      DoctorPatientChat(
        id: '3',
        name: 'Yosua Gunadiel',
        message: 'Hasil gula darah saya naik lagi dok.',
        time: 'Senin',
        unreadCount: 1,
        glucoseNote: 'Gula Darah Sewaktu: 210 mg/dL (Perlu Evaluasi)',
      ),
      DoctorPatientChat(
        id: '4',
        name: 'Rina Maharani',
        message: 'Siap dok, akan saya coba.',
        time: 'Minggu',
        unreadCount: 0,
        glucoseNote: 'Gula Darah Puasa: 124 mg/dL',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DoctorPatientChat> get _filteredChats {
    if (_searchQuery.trim().isEmpty) return _chats;
    return _chats
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.message.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.softPinkCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Notifikasi Dokter',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141414),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationRow(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Pesan Baru dari Pasien',
              desc: 'Widyatna Dwi mengirim 2 pesan baru mengenai obatnya.',
              time: '14:02',
            ),
            const SizedBox(height: 12),
            _buildNotificationRow(
              icon: Icons.warning_amber_rounded,
              title: 'Peringatan Gula Darah',
              desc: 'Yosua Gunadiel melaporkan kenaikan gula darah 210 mg/dL.',
              time: 'Senin',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Tutup',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationRow({
    required IconData icon,
    required String title,
    required String desc,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.softPinkBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF141414),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 9.5,
                  color: const Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openChat(DoctorPatientChat chat) {
    // Reset unread count
    setState(() {
      final index = _chats.indexWhere((c) => c.id == chat.id);
      if (index != -1) {
        _chats[index] = DoctorPatientChat(
          id: chat.id,
          name: chat.name,
          message: chat.message,
          time: chat.time,
          unreadCount: 0,
          glucoseNote: chat.glucoseNote,
        );
      }
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorChatDetailScreen(
          doctorName: widget.doctorName,
          patientName: chat.name,
          initialMessage: chat.message,
          glucoseNote: chat.glucoseNote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4F7), // Match the light background from screenshot
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_selectedTabIndex == 0) return _buildDashboardBody();
    if (_selectedTabIndex == 1) {
      return DoctorAllChatsScreen(
        doctorName: widget.doctorName,
        chats: _chats,
        onChatOpen: _openChat,
        showBackButton: false,
      );
    }
    return _buildProfileTab();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'Selamat pagi ☀️';
    } else if (hour < 15) {
      return 'Selamat siang 🌤️';
    } else if (hour < 18) {
      return 'Selamat sore ⛅';
    } else {
      return 'Selamat malam 🌙';
    }
  }

  /// Dashboard Home Content (Persis Referensi)
  Widget _buildDashboardBody() {
    return Stack(
      children: [
        // Background Shapes (Top Right Circles)
        Positioned(
          top: -80,
          right: -40,
          child: Container(
            width: 250,
            height: 250,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE0E8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: -20,
          right: -80,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD1DC).withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
        
        // Main Content
        Column(
          children: [
            // 1. Top Header
            _buildHeader(),

            // 2. Scrollable Body Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // 2 Summary Metric Cards (Total pasien: 128 & Chat belum dibaca: 5)
                    _buildSummaryCards(),

                    const SizedBox(height: 18),

                    // Section Header: "Pesan terbaru" & "Lihat semua"
                    _buildSectionHeader(),

                    const SizedBox(height: 10),

                    // Daftar pesan pasien
                    _buildChatList(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 1. Top Header (Sesuai dengan screenshot)
  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: 22,
        ),
        child: Column(
          children: [
            // Top Row: Notification Bell, Greeting + Name, Avatar
            Row(
              children: [
                // Notification Bell
                InkWell(
                  onTap: _showNotificationDialog,
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFFD1DC),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: Color(0xFF141414),
                          size: 26,
                        ),
                        Positioned(
                          top: 12,
                          right: 14,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(),
                
                // Greeting & Doctor Name
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getGreeting(),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.doctorName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: const Color(0xFF141414),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 14),
                
                // Avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search Bar: "Cari pasien..."
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFF06292),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: const Color(0xFF212121),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari pasien...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: const Color(0xFF9E9E9E),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2 Summary Metric Cards (Total pasien: 128 & Chat belum dibaca: 5)
  Widget _buildSummaryCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Total Pasien: 128
          Expanded(
            child: _buildMetricCard(
              icon: Icons.people_outline_rounded,
              value: '128',
              label: 'Total pasien',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Total 128 pasien terdaftar dalam pemantauan Dr. Kaka.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),

          // Chat Belum Dibaca: 5
          Expanded(
            child: _buildMetricCard(
              icon: Icons.chat_bubble_outline_rounded,
              value: '5',
              label: 'Chat belum dibaca',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Terdapat 5 pesan konsultasi baru menunggu respons.',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.softPinkBorder.withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Soft pink circular icon container
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.softPinkCard,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),

            // Number & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF757575),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Section Header: "Pesan terbaru" & "Lihat semua"
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pesan terbaru',
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
            ),
          ),
          InkWell(
            onTap: () {
              if (_searchQuery.isNotEmpty) {
                _searchController.clear();
                setState(() => _searchQuery = '');
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DoctorAllChatsScreen(
                    doctorName: widget.doctorName,
                    chats: _chats,
                    onChatOpen: _openChat,
                  ),
                ),
              ).then((_) {
                // Refresh state when coming back if needed
                setState(() {});
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Lihat semua',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chat List items (Kartu soft pink persis seperti pada gambar referensi)
  Widget _buildChatList() {
    final list = _filteredChats.where((chat) => chat.unreadCount > 0).toList();

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Pasien "$_searchQuery" tidak ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: list.map((chat) => _buildChatItem(chat)).toList(),
    );
  }

  Widget _buildChatItem(DoctorPatientChat chat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.softPinkCard.withValues(alpha: 0.65), // Soft Pink Card Tint
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openChat(chat),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Soft Pink circle avatar with white person icon
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),

                // Name and Last Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.name,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chat.message,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF616161),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Timestamp & Unread Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat.time,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF757575),
                      ),
                    ),
                    if (chat.unreadCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${chat.unreadCount}',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ] else
                      const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 4. Bottom Navigation Bar:
  /// Sesuai permintaan pengguna: Menu Chat dan Pasien dihapus!
  /// Hanya menyisakan menu 'Beranda' dan 'Profil'.
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEF2), // Soft pink bottom nav background
        border: Border(
          top: BorderSide(
            color: AppColors.softPinkBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            label: 'Beranda',
            icon: _selectedTabIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
          ),
          _buildNavItem(
            index: 1,
            label: 'Chat',
            icon: _selectedTabIndex == 1 ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded,
          ),
          _buildNavItem(
            index: 2,
            label: 'Profil',
            icon: _selectedTabIndex == 2 ? Icons.account_circle_rounded : Icons.account_circle_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTabIndex == index;

    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // White Pill Container for selected icon (persis gaya referensi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFF757575),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? AppColors.primary
                  : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  /// Profil Tab untuk Dokter
  Widget _buildProfileTab() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedTabIndex = 0),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: AppColors.primary,
                ),
                Text(
                  'Profil Dokter',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(width: 48), // Balance spacing
              ],
            ),
            const SizedBox(height: 16),

            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.softPinkBorder.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Badge
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.softPinkCard,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: 46,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    widget.doctorName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  Text(
                    'Spesialis Penyakit Dalam (Sp.PD)',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SIP: 446.1/128/SIP-D/2022 â€¢ RS D-Care Sejahtera',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildProfileStat('128', 'Pasien'),
                      Container(
                        height: 28,
                        width: 1,
                        color: AppColors.softPinkBorder,
                      ),
                      _buildProfileStat('8+ Thn', 'Pengalaman'),
                      Container(
                        height: 28,
                        width: 1,
                        color: AppColors.softPinkBorder,
                      ),
                      _buildProfileStat('4.9 â­', 'Rating'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Settings & Action Menu List
            _buildProfileMenuItem(
              icon: Icons.badge_outlined,
              title: 'Informasi Praktik & SIP',
              subtitle: 'Data verifikasi medis dan lisensi dokter',
              onTap: () {},
            ),
            _buildProfileMenuItem(
              icon: Icons.schedule_outlined,
              title: 'Jadwal Konsultasi Online',
              subtitle: 'Senin - Jumat (09:00 - 17:00)',
              onTap: () {},
            ),
            _buildProfileMenuItem(
              icon: Icons.security_outlined,
              title: 'Keamanan & Kata Sandi',
              subtitle: 'Ganti password dan keamanan akun',
              onTap: () {},
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Pusat Bantuan & Panduan Medis',
              subtitle: 'Pedoman penanganan pasien diabetes D-Care',
              onTap: () {},
            ),

            const SizedBox(height: 14),

            // Logout Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary, width: 1.2),
                color: Colors.white,
              ),
              child: InkWell(
                onTap: _showLogoutConfirmDialog,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keluar dari Akun Dokter',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF757575),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.softPinkBorder.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.softPinkCard,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF212121),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: const Color(0xFF757575),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  void _showLogoutConfirmDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Konfirmasi Keluar',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF141414),
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun Dr. Kaka Pratama?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF666666),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF757575),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Detail Chat Dokter & Pasien (Soft Pink Theme)
class DoctorChatDetailScreen extends StatefulWidget {
  final String doctorName;
  final String patientName;
  final String initialMessage;
  final String glucoseNote;

  const DoctorChatDetailScreen({
    super.key,
    required this.doctorName,
    required this.patientName,
    required this.initialMessage,
    required this.glucoseNote,
  });

  @override
  State<DoctorChatDetailScreen> createState() => _DoctorChatDetailScreenState();
}

class _DoctorChatDetailScreenState extends State<DoctorChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTyping = false;

  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'text': 'Selamat siang, dok. Gula darah saya pagi ini 118 mg/dL.',
        'isDoctor': false,
        'time': '14:02',
      },
      {
        'text': 'Selamat siang. Itu sudah dalam batas normal. Obatnya sudah diminum?',
        'isDoctor': true,
        'time': '14:05',
        'read': true,
      },
      {
        'text': 'Baik dok, saya sudah minum obatnya.',
        'isDoctor': false,
        'time': '14:06',
      },
      {
        'text': 'Baik. Lanjutkan pola makannya dan cek lagi besok pagi ya.',
        'isDoctor': true,
        'time': '14:08',
        'read': true,
      },
    ];
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'text': text,
        'isDoctor': true,
        'time': timeStr,
        'read': false,
      });
      _msgController.clear();
      _showTyping = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTyping = false);
    });
  }

  void _openPatientHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientHistoryScreen(
          patientName: widget.patientName,
          glucoseNote: widget.glucoseNote,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.patientName,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF69FF97),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Online',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openPatientHistory,
            icon: const Icon(Icons.description_outlined, color: Colors.white, size: 24),
            tooltip: 'Riwayat Pasien',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              itemCount: _messages.length + 2,
              itemBuilder: (ctx, idx) {
                if (idx == 0) return _buildDateSeparator('Hari ini');
                if (idx == _messages.length + 1) {
                  return _showTyping ? _buildTypingIndicator() : const SizedBox.shrink();
                }
                final m = _messages[idx - 1];
                final isDoctor = m['isDoctor'] as bool;
                return _buildMessageBubble(m, isDoctor);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppColors.softPinkBorder, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF9E9E9E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppColors.softPinkBorder, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, bool isDoctor) {
    final bool isRead = (m['read'] as bool?) ?? false;
    return Align(
      alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 10,
          left: isDoctor ? 60 : 0,
          right: isDoctor ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDoctor ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isDoctor ? 16 : 4),
            bottomRight: Radius.circular(isDoctor ? 4 : 16),
          ),
          border: isDoctor
              ? null
              : Border.all(color: AppColors.softPinkBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isDoctor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              m['text'] as String,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: isDoctor ? Colors.white : const Color(0xFF212121),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  m['time'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: isDoctor
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF9E9E9E),
                  ),
                ),
                if (isDoctor) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13,
                    color: isRead
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.softPinkBorder, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) => _BouncingDot(delay: i * 200)),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.softPinkBorder.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.softPinkCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.softPinkBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.softPinkBorder, width: 1),
                ),
                child: TextField(
                  controller: _msgController,
                  style: GoogleFonts.poppins(fontSize: 13),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF9E9E9E),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _sendMessage,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8DA1), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Animated bouncing dot untuk typing indicator
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _BouncingDot extends StatefulWidget {
  final int delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Riwayat Pasien Screen
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class PatientHistoryScreen extends StatefulWidget {
  final String patientName;
  final String glucoseNote;

  const PatientHistoryScreen({
    super.key,
    required this.patientName,
    required this.glucoseNote,
  });

  @override
  State<PatientHistoryScreen> createState() => _PatientHistoryScreenState();
}

class _PatientHistoryScreenState extends State<PatientHistoryScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Semua', 'Hasil lab', 'Resep obat'];
  final List<Map<String, dynamic>> _customVisits = [];
  final List<Map<String, dynamic>> _customResepList = [];

  Future<void> _openPrescriptionNoteScreen() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => DoctorPrescriptionNoteScreen(
          patientName: widget.patientName,
          rmNumber: 'RM-2026-0812',
          age: '28 thn',
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      final List<String> meds = List<String>.from(result['medications'] ?? []);
      final String note = result['note'] ?? '';
      final String status = result['status'] ?? 'Terkontrol baik';

      setState(() {
        if (meds.isNotEmpty) {
          _customResepList.insert(0, {
            'date': 'Hari ini',
            'items': meds,
          });
        }
        if (note.isNotEmpty || meds.isNotEmpty) {
          _customVisits.insert(0, {
            'date': 'Hari ini',
            'status': status,
            'statusColor': status == 'Terkontrol baik'
                ? const Color(0xFF4CAF50)
                : const Color(0xFFFF9800),
            'doctorName': 'dr. Saya (Dokter)',
            'hospital': 'Poli Penyakit Dalam, RS D-Care',
            'vitalItems': const [
              _VitalItem('Gula darah puasa', '110 mg/dL'),
              _VitalItem('Gula darah 2 jam PP', '140 mg/dL'),
              _VitalItem('HbA1c', '6.4%'),
              _VitalItem('Tekanan darah', '120/80 mmHg'),
            ],
            'prescriptions': meds,
            'doctorNote': note.isNotEmpty ? note : 'Tidak ada catatan tambahan.',
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Resep & catatan berhasil disimpan ke riwayat.',
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPatientCard(),
                  const SizedBox(height: 14),
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  _buildCatatanHeader(),
                  const SizedBox(height: 14),
                  _buildVisitSectionHeader(),
                  const SizedBox(height: 10),
                  if (_selectedTab == 0 || _selectedTab == 1) ...[
                    ..._customVisits.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ExpandableVisitCard(
                            date: v['date'],
                            status: v['status'],
                            statusColor: v['statusColor'],
                            doctorName: v['doctorName'],
                            hospital: v['hospital'],
                            vitalItems: v['vitalItems'] as List<_VitalItem>,
                            prescriptions: v['prescriptions'] as List<String>,
                            doctorNote: v['doctorNote'],
                            initiallyExpanded: true,
                          ),
                        )),
                    _ExpandableVisitCard(
                      date: '20 Mei 2026',
                      status: 'Terkontrol baik',
                      statusColor: const Color(0xFF4CAF50),
                      doctorName: 'dr. Ariena Putri, Sp.PD',
                      hospital: 'Poli Penyakit Dalam dan Endokrin, RS D-Care',
                      vitalItems: const [
                        _VitalItem('Gula darah puasa', '108 mg/dL'),
                        _VitalItem('Gula darah 2 jam PP', '135 mg/dL'),
                        _VitalItem('HbA1c', '6.2%'),
                        _VitalItem('Tekanan darah', '120/80 mmHg'),
                        _VitalItem('Berat badan', '68 kg'),
                      ],
                      prescriptions: const [
                        'Metformin HCl 500 mg (2x1 sesudah makan)',
                        'Vitamin B Complex (1x1 pagi)',
                      ],
                      doctorNote:
                          'Kadar gula darah stabil dalam target. Pasien disiplin diet dan olahraga. Jadwal kontrol berikutnya: 20 Juni 2026.',
                      initiallyExpanded: true,
                    ),
                    const SizedBox(height: 12),
                    _ExpandableVisitCard(
                      date: '18 April 2026',
                      status: 'Evaluasi dosis',
                      statusColor: const Color(0xFFFF9800),
                      doctorName: 'dr. Hendra Wijaya, Sp.PD',
                      hospital: 'Poli Penyakit Dalam, RS D-Care',
                      vitalItems: const [
                        _VitalItem('Gula darah puasa', '142 mg/dL'),
                        _VitalItem('Gula darah 2 jam PP', '198 mg/dL'),
                        _VitalItem('HbA1c', '7.1%'),
                        _VitalItem('Tekanan darah', '128/84 mmHg'),
                        _VitalItem('Berat badan', '69 kg'),
                      ],
                      prescriptions: const [
                        'Metformin HCl 500 mg (3x1 sesudah makan)',
                        'Glibenclamide 5 mg (1x1 pagi)',
                      ],
                      doctorNote:
                          'Gula darah belum terkontrol optimal. Dosis Metformin ditingkatkan. Anjuran kurangi konsumsi karbohidrat sederhana.',
                      initiallyExpanded: false,
                    ),
                  ],
                  if (_selectedTab == 2) _buildResepList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF8BBD0), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: AppColors.primary, size: 20),
              ),
              Expanded(
                child: Text(
                  'Riwayat pasien',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Mengunduh riwayat sebagai PDF...',
                          style: GoogleFonts.poppins()),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.download_outlined,
                    color: AppColors.primary, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8DA1), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.patientName,
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Diabetes mellitus tipe 2',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'RM-2024-0127',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPatientStat('Usia', '45 thn'),
              _buildStatDividerV(),
              _buildPatientStat('Gender', 'Wanita'),
              _buildStatDividerV(),
              _buildPatientStat('Gol. darah', 'O+'),
              _buildStatDividerV(),
              _buildPatientStat('Status', 'Rutin kontrol'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDividerV() {
    return Container(
      height: 28,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softPinkBorder, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF757575),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCatatanHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softPinkBorder, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.softPinkCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.note_alt_outlined,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Catatan dokter',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.softPinkCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '2 catatan',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat kunjungan medis',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF212121),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.softPinkCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '2 catatan',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResepList() {
    return Column(
      children: [
        ..._customResepList.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildResepCard(
                date: r['date'],
                items: r['items'] as List<String>,
              ),
            )),
        _buildResepCard(
          date: '20 Mei 2026',
          items: const [
            'Metformin HCl 500 mg (2x1 sesudah makan)',
            'Vitamin B Complex (1x1 pagi)',
          ],
        ),
        const SizedBox(height: 12),
        _buildResepCard(
          date: '18 April 2026',
          items: const [
            'Metformin HCl 500 mg (3x1 sesudah makan)',
            'Glibenclamide 5 mg (1x1 pagi)',
          ],
        ),
      ],
    );
  }

  Widget _buildResepCard({required String date, required List<String> items}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.softPinkBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Resep • $date',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: const Color(0xFF424242)),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.softPinkBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => _openPrescriptionNoteScreen(),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8DA1), AppColors.primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Tulis resep dan catatan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Data model vital sign item
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _VitalItem {
  final String label;
  final String value;
  const _VitalItem(this.label, this.value);
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
/// Kartu kunjungan expandable
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ExpandableVisitCard extends StatefulWidget {
  final String date;
  final String status;
  final Color statusColor;
  final String doctorName;
  final String hospital;
  final List<_VitalItem> vitalItems;
  final List<String> prescriptions;
  final String doctorNote;
  final bool initiallyExpanded;

  const _ExpandableVisitCard({
    required this.date,
    required this.status,
    required this.statusColor,
    required this.doctorName,
    required this.hospital,
    required this.vitalItems,
    required this.prescriptions,
    required this.doctorNote,
    required this.initiallyExpanded,
  });

  @override
  State<_ExpandableVisitCard> createState() => _ExpandableVisitCardState();
}

class _ExpandableVisitCardState extends State<_ExpandableVisitCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _animCtrl;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _expanded ? 1 : 0,
    );
    _expandAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _animCtrl.forward() : _animCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softPinkBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softPinkCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.date,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF212121),
                          ),
                        ),
                        Text(
                          widget.doctorName,
                          style: GoogleFonts.poppins(
                              fontSize: 11.5, color: const Color(0xFF616161)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.status,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: widget.statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: AppColors.softPinkBorder, thickness: 1, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Text(
                    widget.hospital,
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: const Color(0xFF9E9E9E)),
                  ),
                ),
                _buildExpandSection(
                  icon: Icons.monitor_heart_outlined,
                  title: 'Tanda vital dan glukosa',
                  child: Column(
                    children: widget.vitalItems.map((v) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(v.label,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF616161))),
                            Text(v.value,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF212121))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _buildExpandSection(
                  icon: Icons.medication_outlined,
                  title: 'Resep obat',
                  child: Column(
                    children: widget.prescriptions.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6, right: 8),
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle),
                            ),
                            Expanded(
                              child: Text(p,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF424242))),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                _buildExpandSection(
                  icon: Icons.note_outlined,
                  title: 'Catatan dokter dan anjuran',
                  isLast: true,
                  child: Text(
                    widget.doctorNote,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF424242),
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandSection({
    required IconData icon,
    required String title,
    required Widget child,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, isLast ? 14 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

