import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/screens/login_screen.dart';

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
  int _selectedTabIndex = 0; // 0: Beranda, 1: Profil (Chat dan Pasien dihapus)
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
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Color(0xFFD81B60),
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
                color: const Color(0xFFD81B60),
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
            color: const Color(0xFFFFF0F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD81B60)),
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
    // Reset unread count for demo
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
      backgroundColor: const Color(0xFFFFF0F5), // Soft Pink Background
      body: _selectedTabIndex == 0 ? _buildDashboardBody() : _buildProfileTab(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Dashboard Home Content
  Widget _buildDashboardBody() {
    return Column(
      children: [
        // 1. Top Curved Magenta Header (Sapaan, Nama Dokter, Bell & Search Bar)
        _buildHeader(),

        // 2. Scrollable Body Content
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // 2 Summary Metric Cards (Total pasien & Chat belum dibaca)
                _buildSummaryCards(),

                const SizedBox(height: 18),

                // Section Header: "Pesan terbaru" & "Lihat semua"
                _buildSectionHeader(),

                const SizedBox(height: 10),

                // List of Chat Cards
                _buildChatList(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 1. Top Curved Magenta Header
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFD81B60), // Magenta / Deep Rose brand color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
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
              // Top Row: Avatar, Greeting + Name, Notification Bell
              Row(
                children: [
                  // White circular avatar with outline doctor/person icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFFD81B60),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Greeting & Doctor Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat pagi,',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          widget.doctorName,
                          style: GoogleFonts.poppins(
                            fontSize: 18.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell with Badge Dot
                  InkWell(
                    onTap: _showNotificationDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Search Bar: "Cari pasien..."
              Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFFD81B60),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
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
                          padding: EdgeInsets.symmetric(horizontal: 10),
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
      ),
    );
  }

  /// 2 Summary Metric Cards (Total pasien & Chat belum dibaca)
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
                    backgroundColor: const Color(0xFFD81B60),
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
                    backgroundColor: const Color(0xFFD81B60),
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
            color: const Color(0xFFF8BBD0).withValues(alpha: 0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD81B60).withValues(alpha: 0.04),
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
                color: Color(0xFFFCE4EC),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFD81B60),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Menampilkan seluruh daftar riwayat pesan pasien.',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: const Color(0xFFD81B60),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Lihat semua',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFD81B60),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chat List items (Soft Pink Cards with patient name, message, time, unread badge)
  Widget _buildChatList() {
    final list = _filteredChats;

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: const Color(0xFFD81B60).withValues(alpha: 0.5),
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
        color: const Color(0xFFFCE4EC).withValues(alpha: 0.65), // Soft Pink tint
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
                // Pink circle avatar with white person icon
                const CircleAvatar(
                  radius: 21,
                  backgroundColor: Color(0xFFD81B60),
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
                          color: Color(0xFFD81B60),
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
  /// Sesuai permintaan: Chat dan Pasien dihapus, sisakan HANYA Beranda dan Profil!
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFFFDEEF2), // Soft pink background matching reference
        border: Border(
          top: BorderSide(
            color: const Color(0xFFF8BBD0).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            label: 'Beranda',
            icon: Icons.home_outlined,
          ),
          _buildNavItem(
            index: 1,
            label: 'Profil',
            icon: Icons.account_circle_outlined,
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
          // White Pill Container for selected icon (matching the screenshot style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFD81B60).withValues(alpha: 0.08),
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
                  ? const Color(0xFFD81B60)
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
                  ? const Color(0xFFD81B60)
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
                  color: const Color(0xFFD81B60),
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
                  color: const Color(0xFFF8BBD0).withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD81B60).withValues(alpha: 0.05),
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
                          color: const Color(0xFFFCE4EC),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFD81B60),
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFFD81B60),
                          size: 46,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFD81B60),
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
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SIP: 446.1/128/SIP-D/2022 • RS D-Care Sejahtera',
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
                        color: const Color(0xFFF8BBD0),
                      ),
                      _buildProfileStat('8+ Thn', 'Pengalaman'),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFF8BBD0),
                      ),
                      _buildProfileStat('4.9 ⭐', 'Rating'),
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
                border: Border.all(color: const Color(0xFFD81B60), width: 1.2),
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
                        color: Color(0xFFD81B60),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Keluar dari Akun Dokter',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD81B60),
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
          color: const Color(0xFFF8BBD0).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFCE4EC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFD81B60), size: 22),
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
            const Icon(Icons.logout_rounded, color: Color(0xFFD81B60)),
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
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD81B60),
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

/// Detail Chat Dokter & Pasien
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

  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        'text':
            'Halo ${widget.patientName}, bagaimana kondisi fisik dan kadar gula darah Anda hari ini?',
        'isDoctor': true,
        'time': '13:45',
      },
      {
        'text': widget.initialMessage,
        'isDoctor': false,
        'time': '14:02',
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

    setState(() {
      _messages.add({
        'text': text,
        'isDoctor': true,
        'time': '14:05',
      });
      _msgController.clear();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD81B60),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFFD81B60), size: 22),
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
                  Text(
                    widget.glucoseNote,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.9),
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
      body: Column(
        children: [
          // Banner Status Pasien
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFFCE4EC),
            child: Row(
              children: [
                const Icon(
                  Icons.monitor_heart_outlined,
                  size: 18,
                  color: Color(0xFFD81B60),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Catatan Medis: ${widget.glucoseNote}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD81B60),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message Bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (ctx, idx) {
                final m = _messages[idx];
                final isDoctor = m['isDoctor'] as bool;

                return Align(
                  alignment:
                      isDoctor ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDoctor
                          ? const Color(0xFFD81B60)
                          : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isDoctor ? 16 : 4),
                        bottomRight: Radius.circular(isDoctor ? 4 : 16),
                      ),
                      border: isDoctor
                          ? null
                          : Border.all(
                              color: const Color(0xFFF8BBD0),
                              width: 1,
                            ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isDoctor
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['text'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: isDoctor ? Colors.white : const Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          m['time'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: isDoctor
                                ? Colors.white.withValues(alpha: 0.8)
                                : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFF8BBD0).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFF8BBD0),
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: _msgController,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan resep atau anjuran medis...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sendMessage,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD81B60),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
}
