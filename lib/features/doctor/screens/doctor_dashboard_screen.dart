import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';
import '../../../core/widgets/in_app_camera_screen.dart';
import '../../../core/widgets/medical_document_viewer_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_repository.dart';
import '../../auth/screens/landing_screen.dart';
import 'doctor_all_chats_screen.dart';
import 'doctor_change_password_screen.dart';
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
  final String? doctorId;

  const DoctorDashboardScreen({
    super.key,
    this.doctorName = 'Dr. Kaka Pratama',
    this.doctorId,
  });

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  int _selectedTabIndex = 0; // 0: Beranda, 1: Profil (Chat dan Pasien telah dihapus)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Data profil dokter dari Firestore
  String _doctorSchedule = 'Senin - Jumat (09:00 - 17:00)';
  String _doctorDisplayName = '';
  String _doctorSpecialty = 'Spesialis Penyakit Dalam (Sp.PD)';
  String? _doctorPhotoUrl;
  String? _doctorEmail;
  String? _resolvedDoctorUid;
  StreamSubscription<DocumentSnapshot>? _doctorProfileSubscription;

  // Data pasien terhubung real-time dengan Firestore
  List<DoctorPatientChat> _chats = [];
  StreamSubscription<List<RealtimeConsultationChat>>? _chatSubscription;

  // Jumlah pasien sebenarnya dari koleksi 'users' di Firestore (bukan dummy)
  int _totalPatientCount = 0;
  StreamSubscription<QuerySnapshot>? _patientCountSubscription;

  @override
  void initState() {
    super.initState();
    _doctorDisplayName = widget.doctorName;
    _doctorEmail = AuthService.instance.currentUser?.email;
    _initDoctorProfile();
    _subscribeToChats();
    _subscribeToPatientCount();
  }

  void _subscribeToChats() {
    _chatSubscription?.cancel();
    final effectiveUid = widget.doctorId ?? _resolvedDoctorUid ?? AuthService.instance.currentUser?.uid;
    final effectiveName = _doctorDisplayName.isNotEmpty ? _doctorDisplayName : widget.doctorName;
    _chatSubscription = ChatService.instance
        .streamDoctorChats(
          doctorName: effectiveName,
          doctorId: effectiveUid,
        )
        .listen((realtimeChats) {
      if (!mounted) return;
      setState(() {
        _chats = realtimeChats.map((c) => c.toDoctorPatientChat()).toList();
      });
    });
  }

  void _initDoctorProfile() async {
    String? uid = widget.doctorId ?? AuthService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _resolvedDoctorUid = uid;
      _subscribeToChats();
      _listenToDoctorProfile(uid);
      return;
    }

    // Fallback: cari dokter berdasarkan nama di Firestore
    try {
      final snap = await FirebaseFirestore.instance
          .collection('doctors')
          .where('fullName', isEqualTo: widget.doctorName)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        _resolvedDoctorUid = doc.id;
        _subscribeToChats();
        _listenToDoctorProfile(doc.id);
      } else {
        final allDocs = await FirebaseFirestore.instance
            .collection('doctors')
            .limit(1)
            .get();
        if (allDocs.docs.isNotEmpty) {
          final doc = allDocs.docs.first;
          _resolvedDoctorUid = doc.id;
          _subscribeToChats();
          _listenToDoctorProfile(doc.id);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error init doctor profile: $e');
    }
  }

  void _listenToDoctorProfile(String uid) {
    _doctorProfileSubscription?.cancel();
    _doctorProfileSubscription = FirebaseFirestore.instance
        .collection('doctors')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final previousName = _doctorDisplayName;
        setState(() {
          if (data['schedule'] != null &&
              (data['schedule'] as String).trim().isNotEmpty) {
            _doctorSchedule = data['schedule'] as String;
          }
          if (data['fullName'] != null &&
              (data['fullName'] as String).trim().isNotEmpty) {
            _doctorDisplayName = data['fullName'] as String;
          }
          if (data['specialization'] != null &&
              (data['specialization'] as String).trim().isNotEmpty) {
            _doctorSpecialty = data['specialization'] as String;
          }
          if (data['photoUrl'] != null) {
            final photo = data['photoUrl'] as String;
            _doctorPhotoUrl = photo.trim().isNotEmpty ? photo : null;
          }
          if (data['email'] != null &&
              (data['email'] as String).trim().isNotEmpty) {
            _doctorEmail = data['email'] as String;
          }
        });
        if (previousName != _doctorDisplayName) {
          _subscribeToChats();
        }
      }
    });
  }

  /// Perbarui foto profil dokter di Firestore (koleksi doctors & consultation_chats)
  Future<void> _updateDoctorPhoto(String? newPhotoUrl) async {
    final uid = _resolvedDoctorUid ?? widget.doctorId ?? AuthService.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ID dokter tidak ditemukan. Gagal memperbarui foto.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDark,
        ),
      );
      return;
    }

    try {
      // 1. Simpan ke koleksi doctors/{uid}
      await FirebaseFirestore.instance.collection('doctors').doc(uid).set({
        'photoUrl': newPhotoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Simpan juga ke koleksi users/{uid} jika ada
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photoUrl': newPhotoUrl ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).catchError((_) {});

      // 3. Sinkronkan ke consultation_chats terkait agar live chat pasien langsung terupdate
      final effectiveName = _doctorDisplayName.isNotEmpty ? _doctorDisplayName : widget.doctorName;
      final chatsByName = await FirebaseFirestore.instance
          .collection('consultation_chats')
          .where('doctorName', isEqualTo: effectiveName)
          .get();
      for (final doc in chatsByName.docs) {
        doc.reference.update({
          'doctorPhotoUrl': newPhotoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }

      final chatsById = await FirebaseFirestore.instance
          .collection('consultation_chats')
          .where('doctorId', isEqualTo: uid)
          .get();
      for (final doc in chatsById.docs) {
        doc.reference.update({
          'doctorPhotoUrl': newPhotoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }

      setState(() {
        _doctorPhotoUrl = newPhotoUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newPhotoUrl != null
                ? 'Foto profil dokter berhasil diperbarui!'
                : 'Foto profil dokter berhasil dihapus.',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error update doctor photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menyimpan foto: $e',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Ambil gambar dari galeri atau kamera
  Future<void> _pickDoctorImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = file.mimeType ?? 'image/jpeg';
        final dataUri = 'data:$mimeType;base64,$base64String';
        await _updateDoctorPhoto(dataUri);
      }
    } catch (e) {
      debugPrint('⚠️ Error picking doctor image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil foto: $e',
            style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.white),
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Dialog pemilihan preset avatar dokter
  void _showPresetAvatarsDialog() {
    final presets = [
      {
        'title': 'Dr. Ryan (Jas Medis)',
        'url': 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=300&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Dr. Sarah (Stetoskop)',
        'url': 'https://images.unsplash.com/photo-1594824813689-53e77864f7b6?w=300&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Dr. Jas Putih',
        'url': 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=300&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Dr. Spesialis',
        'url': 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=300&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Dr. Senior',
        'url': 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=300&auto=format&fit=crop&q=80',
      },
      {
        'title': 'Dr. Konsultan',
        'url': 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=300&auto=format&fit=crop&q=80',
      },
    ];

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  'Pilih Avatar Dokter Siap Pakai',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                Text(
                  'Pilih avatar profesional yang mewakili profil dokter Anda',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: presets.length,
                  itemBuilder: (context, index) {
                    final item = presets[index];
                    final isSelected = _doctorPhotoUrl == item['url'];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _updateDoctorPhoto(item['url']);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.softPinkCard : const Color(0xFFF9F9F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image.network(
                                item['url']!,
                                width: 54,
                                height: 54,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 54,
                                  height: 54,
                                  color: AppColors.softPinkCard,
                                  child: const Icon(Icons.person, color: AppColors.primary),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['title']!,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.primary : const Color(0xFF424242),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Bottom sheet menu ubah foto profil dokter
  void _showChangeDoctorPhotoBottomSheet() {
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
                  'Ubah Foto Profil Dokter',
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto ini akan ditampilkan di profil Anda dan di ruang chat konsultasi pasien.',
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
                      color: AppColors.softPinkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Pilih dari Galeri / File',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Pilih foto dari galeri atau komputer Anda',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDoctorImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softPinkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Ambil Foto dengan Kamera',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Gunakan kamera untuk mengambil potret langsung',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDoctorImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF2E7D32)),
                  ),
                  title: Text(
                    'Pilih Avatar Siap Pakai',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Gunakan salah satu avatar dokter profesional',
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPresetAvatarsDialog();
                  },
                ),
                if (_doctorPhotoUrl != null && _doctorPhotoUrl!.isNotEmpty) ...[
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
                    onTap: () {
                      Navigator.pop(ctx);
                      _updateDoctorPhoto(null);
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

  /// Subscribe ke koleksi 'users' di Firestore untuk mendapatkan jumlah pasien
  /// yang sesungguhnya (bukan dummy), secara real-time.
  void _subscribeToPatientCount() {
    _patientCountSubscription?.cancel();
    _patientCountSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _totalPatientCount = snapshot.docs.length;
      });
    }, onError: (e) {
      debugPrint('⚠️ Error subscribing to patient count: $e');
    });
  }

  @override
  void dispose() {
    _doctorProfileSubscription?.cancel();
    _chatSubscription?.cancel();
    _patientCountSubscription?.cancel();
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
    ChatService.instance.markAsReadByDoctor(chat.id);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorChatDetailScreen(
          chatId: chat.id,
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
                DoctorAvatarWidget(
                  photoUrl: _doctorPhotoUrl,
                  size: 54,
                  backgroundColor: AppColors.primary,
                  iconColor: Colors.white,
                  onTap: () {
                    setState(() => _selectedTabIndex = 1);
                  },
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

  /// 2 Summary Metric Cards (Total pasien & Chat belum dibaca dinamis)
  Widget _buildSummaryCards() {
    final totalPatients = _totalPatientCount;
    final unreadCount = _chats.fold<int>(0, (sum, chat) => sum + chat.unreadCount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Total Pasien
          Expanded(
            child: _buildMetricCard(
              icon: Icons.people_outline_rounded,
              value: '$totalPatients',
              label: 'Total pasien',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Total $totalPatients pasien terdaftar dalam pemantauan.',
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

          // Chat Belum Dibaca
          Expanded(
            child: _buildMetricCard(
              icon: Icons.chat_bubble_outline_rounded,
              value: '$unreadCount',
              label: 'Chat belum dibaca',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Terdapat $unreadCount pesan konsultasi baru menunggu respons.',
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
                      height: 1.2,
                    ),
                    maxLines: 2,
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
    List<DoctorPatientChat> list;
    if (_searchQuery.trim().isNotEmpty) {
      list = _filteredChats;
    } else {
      final unread = _chats.where((chat) => chat.unreadCount > 0).toList();
      list = unread.isNotEmpty ? unread : _chats;
    }

    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.chat_bubble_outline_rounded,
                size: 44,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.trim().isNotEmpty
                    ? 'Pasien "$_searchQuery" tidak ditemukan'
                    : 'Belum ada pesan konsultasi baru',
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
                  // Avatar with Badge & Change Photo Trigger
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DoctorAvatarWidget(
                        photoUrl: _doctorPhotoUrl,
                        size: 88,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 2.8,
                        ),
                        onTap: _showChangeDoctorPhotoBottomSheet,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: InkWell(
                          onTap: _showChangeDoctorPhotoBottomSheet,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tombol Ubah Foto Profil
                  InkWell(
                    onTap: _showChangeDoctorPhotoBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.softPinkBorder,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.edit_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ubah Foto Profil',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    _doctorDisplayName.isNotEmpty
                        ? _doctorDisplayName
                        : widget.doctorName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  Text(
                    _doctorSpecialty,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
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
                      _buildProfileStat('$_totalPatientCount', 'Pasien'),
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
              onTap: _showPracticeInfoBottomSheet,
            ),
            _buildProfileMenuItem(
              icon: Icons.schedule_outlined,
              title: 'Jadwal Konsultasi Online',
              subtitle: _doctorSchedule,
              onTap: _showEditScheduleBottomSheet,
            ),
            _buildProfileMenuItem(
              icon: Icons.security_outlined,
              title: 'Keamanan & Kata Sandi',
              subtitle: 'Ganti password dan keamanan akun',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorChangePasswordScreen(
                      doctorEmail: _doctorEmail ?? AuthService.instance.currentUser?.email ?? '',
                      doctorName: _doctorDisplayName.isNotEmpty
                          ? _doctorDisplayName
                          : widget.doctorName,
                    ),
                  ),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.help_outline_rounded,
              title: 'Pusat Bantuan & Panduan Medis',
              subtitle: 'Pedoman penanganan pasien diabetes D-Care',
              onTap: _showHelpCenterBottomSheet,
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

  /// Bottom Sheet untuk Mengubah Jadwal Konsultasi Dokter
  void _showEditScheduleBottomSheet() {
    final TextEditingController scheduleController =
        TextEditingController(text: _doctorSchedule);
    String selectedDays = 'Senin - Jumat';
    String selectedHours = '09:00 - 17:00';
    bool isSaving = false;

    // Deteksi preset hari dari teks yang ada
    if (_doctorSchedule.contains('Senin - Sabtu')) {
      selectedDays = 'Senin - Sabtu';
    } else if (_doctorSchedule.contains('Senin - Kamis')) {
      selectedDays = 'Senin - Kamis';
    } else if (_doctorSchedule.contains('Setiap Hari')) {
      selectedDays = 'Setiap Hari';
    } else if (_doctorSchedule.contains('Senin - Jumat')) {
      selectedDays = 'Senin - Jumat';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void updateCombinedText(String days, String hours) {
              setModalState(() {
                selectedDays = days;
                selectedHours = hours;
                scheduleController.text = '$days ($hours)';
              });
            }

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.softPinkCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.edit_calendar_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ubah Jadwal Konsultasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212121),
                                ),
                              ),
                              Text(
                                'Jadwal akan langsung otomatis terlihat oleh pasien',
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Label Pilihan Hari
                    Text(
                      'Pilih Hari Ketersediaan',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Senin - Jumat',
                        'Senin - Sabtu',
                        'Senin - Kamis',
                        'Setiap Hari',
                      ].map((dayOption) {
                        final isSelected = selectedDays == dayOption;
                        return ChoiceChip(
                          label: Text(
                            dayOption,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF424242),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF7F7F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE5E5E5),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              updateCombinedText(dayOption, selectedHours);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Label Pilihan Jam
                    Text(
                      'Pilih Jam Praktik',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        '08:00 - 16:00',
                        '09:00 - 17:00',
                        '10:00 - 18:00',
                        '13:00 - 20:00',
                      ].map((hourOption) {
                        final isSelected = selectedHours == hourOption;
                        return ChoiceChip(
                          label: Text(
                            hourOption,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF424242),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF7F7F8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE5E5E5),
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              updateCombinedText(selectedDays, hourOption);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Tombol Kustom Jam dengan TimePicker
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? start = await showTimePicker(
                          context: ctx,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                          helpText: 'PILIH JAM MULAI',
                        );
                        if (start == null || !ctx.mounted) return;

                        final TimeOfDay? end = await showTimePicker(
                          context: ctx,
                          initialTime: const TimeOfDay(hour: 17, minute: 0),
                          helpText: 'PILIH JAM SELESAI',
                        );
                        if (end == null || !ctx.mounted) return;

                        String formatTime(TimeOfDay t) =>
                            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                        final customHour =
                            '${formatTime(start)} - ${formatTime(end)}';
                        updateCombinedText(selectedDays, customHour);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.softPinkCard,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.softPinkBorder,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pilih Jam Lainnya (TimePicker)',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Teks Hasil / Edit Manual
                    Text(
                      'Teks Format Jadwal (Dapat Diedit Manual)',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: scheduleController,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF212121),
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF9F9FA),
                        hintText: 'Contoh: Senin - Jumat (09:00 - 17:00)',
                        prefixIcon: const Icon(
                          Icons.schedule_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons (Batal & Simpan)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(bottomSheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              side: const BorderSide(
                                color: Color(0xFFD0D0D0),
                              ),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF616161),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final newSchedule =
                                        scheduleController.text.trim();
                                    if (newSchedule.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Teks jadwal tidak boleh kosong.'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }

                                    setModalState(() => isSaving = true);

                                    try {
                                      // Ambil UID dokter
                                      String? targetUid = _resolvedDoctorUid ??
                                          widget.doctorId ??
                                          AuthService.instance.currentUser?.uid;

                                      if (targetUid != null &&
                                          targetUid.isNotEmpty) {
                                        await UserRepository.instance
                                            .updateDoctorSchedule(
                                          targetUid,
                                          newSchedule,
                                        );
                                      } else {
                                        // Update berdasarkan nama jika UID tidak terdeteksi
                                        final snap = await FirebaseFirestore
                                            .instance
                                            .collection('doctors')
                                            .where('fullName',
                                                isEqualTo: widget.doctorName)
                                            .limit(1)
                                            .get();
                                        if (snap.docs.isNotEmpty) {
                                          await snap.docs.first.reference
                                              .update({
                                            'schedule': newSchedule,
                                            'updatedAt':
                                                FieldValue.serverTimestamp(),
                                          });
                                        }
                                      }

                                      if (mounted) {
                                        setState(() {
                                          _doctorSchedule = newSchedule;
                                        });
                                      }

                                      if (bottomSheetContext.mounted) {
                                        Navigator.pop(bottomSheetContext);
                                      }

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Row(
                                              children: [
                                                const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    'Jadwal dokter berhasil diperbarui & otomatis sinkron ke akun pasien.',
                                                    style: GoogleFonts.poppins(
                                                        fontSize: 12.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            backgroundColor:
                                                const Color(0xFF2E7D32),
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    } catch (err) {
                                      setModalState(() => isSaving = false);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Gagal menyimpan jadwal: $err'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Simpan Jadwal',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Bottom Sheet untuk Informasi Praktik & SIP
  void _showPracticeInfoBottomSheet() {
    final doctorName = _doctorDisplayName.isNotEmpty
        ? _doctorDisplayName
        : widget.doctorName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.badge_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informasi Praktik & SIP',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212121),
                            ),
                          ),
                          Text(
                            'Data verifikasi medis dan lisensi dokter',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Verified Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Dokter terverifikasi & lisensi aktif',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Info Items
                _buildPracticeInfoItem(
                  icon: Icons.person_rounded,
                  label: 'Nama Lengkap',
                  value: doctorName,
                ),
                _buildPracticeInfoItem(
                  icon: Icons.medical_services_rounded,
                  label: 'Spesialisasi',
                  value: _doctorSpecialty,
                ),
                _buildPracticeInfoItem(
                  icon: Icons.assignment_rounded,
                  label: 'Nomor SIP',
                  value: '446.1/128/SIP-D/2022',
                ),
                _buildPracticeInfoItem(
                  icon: Icons.local_hospital_rounded,
                  label: 'Tempat Praktik',
                  value: 'RS D-Care Sejahtera',
                ),
                _buildPracticeInfoItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Masa Berlaku SIP',
                  value: '01 Januari 2022 - 31 Desember 2027',
                ),
                _buildPracticeInfoItem(
                  icon: Icons.school_rounded,
                  label: 'Pendidikan Terakhir',
                  value: 'Fakultas Kedokteran Universitas Indonesia',
                ),
                _buildPracticeInfoItem(
                  icon: Icons.work_history_rounded,
                  label: 'Pengalaman',
                  value: '8+ Tahun Praktik Klinis',
                ),

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPracticeInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.softPinkCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom Sheet untuk Pusat Bantuan & Panduan Medis
  void _showHelpCenterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(bottomSheetContext).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pusat Bantuan & Panduan',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF212121),
                            ),
                          ),
                          Text(
                            'Pedoman penanganan pasien diabetes',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Section: Panduan Medis
                Text(
                  'Panduan Medis Diabetes',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 12),

                _buildHelpItem(
                  icon: Icons.bloodtype_rounded,
                  title: 'Target Gula Darah',
                  description:
                      'Gula darah puasa: 80–130 mg/dL\nGula darah 2 jam setelah makan: <180 mg/dL\nHbA1c target: <7%',
                  color: const Color(0xFFE53935),
                ),
                _buildHelpItem(
                  icon: Icons.medication_rounded,
                  title: 'Panduan Pemberian Obat',
                  description:
                      'Metformin: Dosis awal 500mg 1-2x/hari\nGlimepiride: 1-2mg 1x/hari sebelum makan\nInsulin: Sesuaikan dosis berdasarkan HbA1c',
                  color: const Color(0xFF1E88E5),
                ),
                _buildHelpItem(
                  icon: Icons.restaurant_rounded,
                  title: 'Panduan Nutrisi Pasien',
                  description:
                      'Karbohidrat: 45-65% dari total kalori\nProtein: 15-20% dari total kalori\nLemak: 20-25% dari total kalori\nSerat: Minimal 25g/hari',
                  color: const Color(0xFF43A047),
                ),
                _buildHelpItem(
                  icon: Icons.warning_amber_rounded,
                  title: 'Tanda Bahaya Hipoglikemia',
                  description:
                      'Gula darah <70 mg/dL\nGejala: Gemetar, berkeringat, pusing, bingung\nPenanganan: Berikan 15-20g glukosa cepat',
                  color: const Color(0xFFFF9800),
                ),

                const SizedBox(height: 16),

                // Section: Bantuan Aplikasi
                Text(
                  'Bantuan Aplikasi D-Care',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 12),

                _buildHelpItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Konsultasi Online',
                  description:
                      'Gunakan fitur chat untuk konsultasi real-time dengan pasien. Rekam medis akan otomatis tersedia di sidebar chat.',
                  color: AppColors.primary,
                ),
                _buildHelpItem(
                  icon: Icons.description_outlined,
                  title: 'Resep & Catatan Medis',
                  description:
                      'Buat resep dan catatan medis melalui ikon resep di halaman chat. Data otomatis tersimpan di rekam medis pasien.',
                  color: const Color(0xFF7B1FA2),
                ),
                _buildHelpItem(
                  icon: Icons.support_agent_rounded,
                  title: 'Hubungi Tim Support',
                  description:
                      'Email: support@dcare.co.id\nWhatsApp: +62 812-3456-7890\nJam operasional: Senin - Jumat (08:00 - 17:00)',
                  color: const Color(0xFF00897B),
                ),

                const SizedBox(height: 20),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(bottomSheetContext),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    height: 1.5,
                    color: const Color(0xFF616161),
                  ),
                ),
              ],
            ),
          ),
        ],
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
  final String? chatId;
  final String doctorName;
  final String patientName;
  final String initialMessage;
  final String glucoseNote;

  const DoctorChatDetailScreen({
    super.key,
    this.chatId,
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
  StreamSubscription<List<RealtimeChatMessage>>? _msgSubscription;

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    if (widget.chatId != null && widget.chatId!.isNotEmpty) {
      ChatService.instance.markAsReadByDoctor(widget.chatId!);
      _msgSubscription = ChatService.instance
          .streamMessages(widget.chatId!)
          .listen((items) {
        if (!mounted) return;
        setState(() {
          _messages = items
              .map((m) => {
                    'id': m.id,
                    'text': m.text,
                    'isDoctor': m.isDoctor,
                    'time': m.time,
                    'read': m.isRead,
                    'type': m.type,
                    'attachmentData': m.attachmentData,
                    'attachmentName': m.attachmentName,
                    'attachmentSize': m.attachmentSize,
                  })
              .toList();
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 40,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _msgSubscription?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({
    String? customText,
    String type = 'text',
    String? attachmentData,
    String? attachmentName,
    String? attachmentSize,
  }) async {
    final text = (customText ?? _msgController.text).trim();
    if (text.isEmpty && attachmentData == null) return;

    if (customText == null) {
      _msgController.clear();
    }

    if (widget.chatId != null && widget.chatId!.isNotEmpty) {
      try {
        await ChatService.instance.sendMessage(
          chatId: widget.chatId!,
          text: text,
          senderRole: 'doctor',
          senderName: widget.doctorName,
          type: type,
          attachmentData: attachmentData,
          attachmentName: attachmentName,
          attachmentSize: attachmentSize,
        );
      } catch (e) {
        debugPrint('⚠️ Error sending doctor message: $e');
      }
    }
  }

  /// Tampilkan Bottom Sheet Lampiran ala WhatsApp
  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    colors: const [Color(0xFFFF5252), Color(0xFFFF1744)],
                    onTap: () async {
                      Navigator.pop(ctx);
                      final resultBase64 = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InAppCameraScreen(
                            title: 'Kamera Dokter D-Care',
                            subtitle: 'Arahkan kamera ke resep atau dokumen medis',
                          ),
                        ),
                      );
                      if (resultBase64 != null && resultBase64.isNotEmpty) {
                        _sendMessage(
                          type: 'image',
                          attachmentData: resultBase64,
                          attachmentName:
                              'Foto_Resep_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          attachmentSize: '120 KB',
                        );
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    colors: const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Dokumen',
                    colors: const [Color(0xFF42A5F5), Color(0xFF1976D2)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _showDocumentPickerSheet();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.medical_services_rounded,
                    label: 'Hasil Lab',
                    colors: const [Color(0xFF26A69A), Color(0xFF00897B)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendLabSummaryAttachment();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF424242),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 65,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final sizeKb = (bytes.lengthInBytes / 1024).round();
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '$sizeKb KB';

      if (!mounted) return;
      _showImagePreviewDialog(
        bytes: bytes,
        base64String: base64String,
        fileName: picked.name,
        fileSize: sizeStr,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog({
    required Uint8List bytes,
    required String base64String,
    required String fileName,
    required String fileSize,
  }) {
    final captionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kirim Foto ($fileSize)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: captionController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tambah keterangan foto...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final caption = captionController.text.trim();
                          Navigator.pop(ctx);
                          _sendMessage(
                            customText: caption,
                            type: 'image',
                            attachmentData: base64String,
                            attachmentName: fileName,
                            attachmentSize: fileSize,
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        label: Text(
                          'Kirim',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDocumentPickerSheet() {
    final docs = [
      {
        'title': 'Hasil_Pemeriksaan_Lab_Glukosa.pdf',
        'desc': 'Hasil tes gula darah puasa & HbA1c resmi laboratorium',
        'size': '245 KB',
        'icon': Icons.picture_as_pdf_rounded,
        'color': const Color(0xFFE53935),
      },
      {
        'title': 'Surat_Rujukan_Klinis_SpPD.pdf',
        'desc': 'Rujukan konsultasi lanjutan poli penyakit dalam',
        'size': '180 KB',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF1E88E5),
      },
      {
        'title': 'Resep_Obat_Resmi_D-Care.pdf',
        'desc': 'Salinan resep metformin & glimepiride elektronik',
        'size': '120 KB',
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF43A047),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softPinkCard,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insert_drive_file_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Dokumen Medis',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      Text(
                        'Kirim berkas PDF atau rekam medis',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...docs.map((d) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (d['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        d['icon'] as IconData,
                        color: d['color'] as Color,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      d['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    subtitle: Text(
                      '${d['desc']} • ${d['size']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: const Icon(Icons.send_rounded,
                        color: AppColors.primary, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendMessage(
                        customText: 'Lampiran: ${d['title']}',
                        type: 'document',
                        attachmentName: d['title'] as String,
                        attachmentSize: d['size'] as String,
                        attachmentData: 'mock_pdf_content',
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final resultBase64 = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InAppCameraScreen(
                        title: 'Pindai Berkas Medis',
                        subtitle: 'Posisikan dokumen atau resep di dalam bingkai',
                      ),
                    ),
                  );
                  if (resultBase64 != null && resultBase64.isNotEmpty) {
                    _sendMessage(
                      type: 'image',
                      attachmentData: resultBase64,
                      attachmentName:
                          'Dokumen_Scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      attachmentSize: '120 KB',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                    color: AppColors.softPinkCard.withValues(alpha: 0.35),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.document_scanner_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Foto / Scan Dokumen Fisik',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendLabSummaryAttachment() {
    final note = widget.glucoseNote.isNotEmpty
        ? widget.glucoseNote
        : 'Gula Darah: 110 mg/dL (Terkontrol)';
    _sendMessage(
      customText: '📊 Ringkasan Hasil Lab:\n$note\nTanggal: Hari ini\nStatus: Terverifikasi oleh Dokter',
      type: 'document',
      attachmentName: 'Ringkasan_Hasil_Lab_${widget.patientName.replaceAll(' ', '_')}.pdf',
      attachmentSize: '95 KB',
      attachmentData: 'mock_lab_pdf',
    );
  }

  void _openFullScreenImage(Uint8List bytes, String? name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              name ?? 'Foto',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(bytes),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetailModal(Map<String, dynamic> m) {
    final name = (m['attachmentName'] as String?) ?? 'Dokumen.pdf';
    final size = (m['attachmentSize'] as String?) ?? '150 KB';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE53935), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ukuran: $size • Format Dokumen PDF Terenkripsi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalDocumentViewerScreen(
                          documentTitle: name,
                          patientName: widget.patientName,
                          doctorName: widget.doctorName,
                          fileSize: size,
                          glucoseSummary: widget.glucoseNote,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                  label: Text(
                    'Unduh & Buka Dokumen',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
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

  void _showMessageOptions(Map<String, dynamic> m) {
    final String messageId = m['id'] as String? ?? '';
    final String text = (m['text'] as String?) ?? '';
    final String? attachmentName = m['attachmentName'] as String?;
    final String type = (m['type'] as String?) ?? 'text';

    final String displayText = text.isNotEmpty
        ? text
        : (attachmentName ?? (type == 'image' ? 'Lampiran Foto' : 'Lampiran'));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.softPinkBorder),
                ),
                child: Text(
                  displayText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF424242),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (text.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded, color: Color(0xFF424242), size: 20),
                  ),
                  title: Text(
                    'Salin Teks',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Teks disalin ke clipboard', style: GoogleFonts.poppins()),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (text.isNotEmpty) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                title: Text(
                  'Hapus Pesan untuk Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  'Pesan akan terhapus dari riwayat dokter dan pasien',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(messageId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    if (messageId.isEmpty || widget.chatId == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Hapus Pesan?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Pesan ini akan dihapus secara permanen untuk Anda dan pasien.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ChatService.instance.deleteMessage(
                  chatId: widget.chatId!,
                  messageId: messageId,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesan berhasil dihapus', style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF333333),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus pesan: $e', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Hapus untuk Semua', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllMessages() {
    if (widget.chatId == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Bersihkan Percakapan?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Semua riwayat percakapan akan dihapus untuk Anda dan pasien. Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ChatService.instance.clearAllMessages(widget.chatId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seluruh percakapan berhasil dibersihkan', style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF333333),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membersihkan percakapan: $e', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Bersihkan Semua', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'clear') {
                _confirmClearAllMessages();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Bersihkan Percakapan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              itemCount: _messages.isEmpty ? 2 : _messages.length + 1,
              itemBuilder: (ctx, idx) {
                if (idx == 0) return _buildDateSeparator('Hari ini');
                if (_messages.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Center(
                      child: Text(
                        'Belum ada pesan dalam sesi konsultasi ini.\nKetik pesan di bawah untuk membalas pasien.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF757575),
                          height: 1.45,
                        ),
                      ),
                    ),
                  );
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
    final String type = (m['type'] as String?) ?? 'text';
    final String? attachmentData = m['attachmentData'] as String?;
    final String? attachmentName = m['attachmentName'] as String?;
    final String? attachmentSize = m['attachmentSize'] as String?;
    final String text = (m['text'] as String?) ?? '';

    Uint8List? imageBytes;
    if (type == 'image' && attachmentData != null && attachmentData.isNotEmpty) {
      try {
        imageBytes = base64Decode(attachmentData);
      } catch (_) {}
    }

    return Align(
      alignment: isDoctor ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showMessageOptions(m),
        onSecondaryTap: () => _showMessageOptions(m),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 10,
            left: isDoctor ? 50 : 0,
            right: isDoctor ? 0 : 50,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              // Lampiran Foto
              if (type == 'image' && imageBytes != null) ...[
                GestureDetector(
                  onTap: () => _openFullScreenImage(imageBytes!, attachmentName),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      constraints: const BoxConstraints(
                        maxHeight: 200,
                        maxWidth: 240,
                      ),
                      color: Colors.black12,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Image.memory(imageBytes, fit: BoxFit.cover),
                          Container(
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.fullscreen_rounded,
                                color: Colors.white, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Lampiran Dokumen
              if (type == 'document') ...[
                InkWell(
                  onTap: () => _showDocumentDetailModal(m),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDoctor
                          ? Colors.white.withValues(alpha: 0.18)
                          : const Color(0xFFF5F5F7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDoctor
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFFE53935),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                attachmentName ?? 'Dokumen.pdf',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDoctor
                                      ? Colors.white
                                      : const Color(0xFF212121),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${attachmentSize ?? "PDF"} • Ketuk untuk buka',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: isDoctor
                                      ? Colors.white.withValues(alpha: 0.8)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Pesan Teks
              if (text.isNotEmpty)
                Text(
                  text,
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
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _showMessageOptions(m),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 14,
                        color: isDoctor
                            ? Colors.white.withValues(alpha: 0.75)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            InkWell(
              onTap: _showAttachmentBottomSheet,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.softPinkCard,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
              ),
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

