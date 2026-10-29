import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';
import 'doctor_dashboard_screen.dart';

class DoctorAllChatsScreen extends StatefulWidget {
  final String doctorName;
  final List<DoctorPatientChat> chats;
  final Function(DoctorPatientChat) onChatOpen;
  final bool showBackButton;

  const DoctorAllChatsScreen({
    super.key,
    required this.doctorName,
    required this.chats,
    required this.onChatOpen,
    this.showBackButton = true,
  });

  @override
  State<DoctorAllChatsScreen> createState() => _DoctorAllChatsScreenState();
}

class _DoctorAllChatsScreenState extends State<DoctorAllChatsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Cache foto profil pasien real-time dari Firestore koleksi users
  final Map<String, String> _patientPhotos = {};
  StreamSubscription<QuerySnapshot>? _usersSub;

  @override
  void initState() {
    super.initState();
    _subscribeToUserPhotos();
  }

  void _subscribeToUserPhotos() {
    _usersSub = FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {
      if (!mounted) return;
      final map = <String, String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final photo = data['photoUrl']?.toString() ?? '';
        if (photo.trim().isNotEmpty) {
          map[doc.id] = photo.trim();
          final username = data['username']?.toString().toLowerCase().trim();
          if (username != null && username.isNotEmpty) {
            map[username] = photo.trim();
          }
          final fullName = data['fullName']?.toString().toLowerCase().trim();
          if (fullName != null && fullName.isNotEmpty) {
            map[fullName] = photo.trim();
          }
        }
      }
      setState(() {
        _patientPhotos.clear();
        _patientPhotos.addAll(map);
      });
    });
  }

  List<DoctorPatientChat> get _filteredChats {
    if (_searchQuery.trim().isEmpty) return widget.chats;
    return widget.chats
        .where(
          (c) =>
              c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.message.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softPinkBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        elevation: 0,
        title: Text(
          'Semua Pesan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFFF06292),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Container(
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
                    color: Color(0xFFF06292),
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
          ),
          Expanded(
            child: _buildChatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    final list = _filteredChats;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _buildChatItem(list[index]);
      },
    );
  }

  Widget _buildChatItem(DoctorPatientChat chat) {
    // Ambil foto profil dari properti chat atau dari cache user Firestore
    final resolvedPhoto = (chat.patientPhotoUrl != null && chat.patientPhotoUrl!.isNotEmpty)
        ? chat.patientPhotoUrl
        : (_patientPhotos[chat.patientId] ??
            _patientPhotos[chat.name.toLowerCase().trim()]);

    return Container(
      margin: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.softPinkCard.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onChatOpen(chat);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                DoctorAvatarWidget(
                  photoUrl: resolvedPhoto,
                  size: 42,
                  initials: chat.name.isNotEmpty ? chat.name[0] : null,
                  backgroundColor: AppColors.primary,
                  iconColor: Colors.white,
                ),
                const SizedBox(width: 12),
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
}
