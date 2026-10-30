import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/consultation_booking_service.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';
import '../../../core/widgets/in_app_camera_screen.dart';
import '../../../core/widgets/medical_document_viewer_screen.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_repository.dart';
import '../../auth/screens/landing_screen.dart';
import '../../patient/models/consultation_booking_model.dart';
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
  final String? patientPhotoUrl;
  final String? patientId;

  DoctorPatientChat({
    required this.id,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    this.glucoseNote = 'Gula Darah: 142 mg/dL (Stabil)',
    this.patientPhotoUrl,
    this.patientId,
  });
}

class DoctorDashboardScreen extends StatefulWidget {
  final String doctorName;
  final String? doctorId;

  const DoctorDashboardScreen({
    super.key,
    this.doctorName = 'dr. Yosua',
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
  // Data Informasi Praktik & SIP
  String _sipNumber = '';
  String _practicePlace = '';
  String _sipExpiry = '';
  String _education = '';
  String _experience = '';
  String? _doctorEmail;
  String? _resolvedDoctorUid;
  StreamSubscription<DocumentSnapshot>? _doctorProfileSubscription;

  // Data pasien terhubung real-time dengan Firestore
  List<DoctorPatientChat> _chats = [];
  StreamSubscription<List<RealtimeConsultationChat>>? _chatSubscription;

  // Jumlah pasien sebenarnya dari koleksi 'users' di Firestore (bukan dummy)
  int _totalPatientCount = 0;
  StreamSubscription<QuerySnapshot>? _patientCountSubscription;

  // Notifikasi booking konsultasi real-time dari pasien
  List<ConsultationBookingModel> _bookingNotifications = [];
  StreamSubscription<List<ConsultationBookingModel>>? _bookingNotificationsSub;

  // Set ID booking yang sudah dibaca oleh dokter
  final Set<String> _readBookingIds = {};

  // Hitung jumlah notifikasi booking yang belum dibaca (unread count)
  int get _unreadBookingCount => _bookingNotifications
      .where((b) => !b.isDoctorRead && !_readBookingIds.contains(b.id))
      .length;

  // Cache foto profil pasien real-time
  final Map<String, String> _patientPhotosCache = {};
  StreamSubscription<QuerySnapshot>? _patientPhotosSub;

  @override
  void initState() {
    super.initState();
    _doctorDisplayName = widget.doctorName;
    _doctorEmail = AuthService.instance.currentUser?.email;
    _initDoctorProfile();
    _subscribeToChats();
    _subscribeToPatientCount();
    _loadReadBookingState();
    _subscribeToBookingNotifications();
    _subscribeToPatientPhotos();
  }

  Future<void> _loadReadBookingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorUid = widget.doctorId ?? _resolvedDoctorUid ?? AuthService.instance.currentUser?.uid ?? 'default';
      final savedIds = prefs.getStringList('doctor_read_bookings_$doctorUid') ?? [];
      if (mounted) {
        setState(() {
          _readBookingIds.addAll(savedIds);
        });
      }
    } catch (e) {
      debugPrint('ℹ️ [_loadReadBookingState] $e');
    }
  }

  Future<void> _saveReadBookingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final doctorUid = widget.doctorId ?? _resolvedDoctorUid ?? AuthService.instance.currentUser?.uid ?? 'default';
      await prefs.setStringList('doctor_read_bookings_$doctorUid', _readBookingIds.toList());
    } catch (e) {
      debugPrint('ℹ️ [_saveReadBookingState] $e');
    }
  }

  void _markAllNotificationsAsRead() {
    final unreadIds = _bookingNotifications
        .where((b) => !b.isDoctorRead && !_readBookingIds.contains(b.id))
        .map((b) => b.id)
        .toList();

    if (unreadIds.isNotEmpty) {
      setState(() {
        _readBookingIds.addAll(unreadIds);
      });
      _saveReadBookingState();
      ConsultationBookingService.instance.markAllBookingsAsRead(unreadIds);
    }
  }

  void _subscribeToBookingNotifications() {
    _bookingNotificationsSub?.cancel();
    final effectiveUid = widget.doctorId ?? _resolvedDoctorUid ?? AuthService.instance.currentUser?.uid ?? '';
    final effectiveName = _doctorDisplayName.isNotEmpty ? _doctorDisplayName : widget.doctorName;
    _bookingNotificationsSub = ConsultationBookingService.instance
        .streamDoctorBookings(
          doctorId: effectiveUid,
          doctorName: effectiveName,
        )
        .listen((bookings) {
      if (!mounted) return;
      setState(() {
        _bookingNotifications = bookings;
      });
    });
  }

  void _subscribeToPatientPhotos() {
    _patientPhotosSub?.cancel();
    _patientPhotosSub = FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {
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
        _patientPhotosCache.clear();
        _patientPhotosCache.addAll(map);
      });
    });
  }

  void _openChatFromBooking(ConsultationBookingModel booking) async {
    Navigator.pop(context); // Tutup dialog notifikasi
    final effectiveUid = widget.doctorId ?? _resolvedDoctorUid ?? AuthService.instance.currentUser?.uid;
    final effectiveName = _doctorDisplayName.isNotEmpty ? _doctorDisplayName : widget.doctorName;

    final chatId = await ChatService.instance.getOrCreateChat(
      doctorName: effectiveName,
      doctorId: effectiveUid,
      doctorSpecialty: _doctorSpecialty,
      patientName: booking.patientName,
      glucoseNote: booking.complaint.isNotEmpty ? booking.complaint : 'Booking: ${booking.timeSlot} WIB',
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DoctorChatDetailScreen(
          chatId: chatId,
          doctorName: effectiveName,
          patientName: booking.patientName,
          initialMessage: booking.complaint.isNotEmpty
              ? 'Halo ${booking.patientName}, saya telah menerima jadwal booking konsultasi Anda pada ${booking.date} jam ${booking.timeSlot} WIB. Keluhan: "${booking.complaint}". Ada yang bisa saya bantu sekarang?'
              : 'Halo ${booking.patientName}, saya dokter Anda untuk sesi konsultasi jam ${booking.timeSlot} WIB. Silakan sampaikan keluhan Anda.',
          glucoseNote: booking.complaint.isNotEmpty ? booking.complaint : 'Jadwal Booking Terkonfirmasi',
        ),
      ),
    );
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectiveUid = widget.doctorId ?? AuthService.instance.currentUser?.uid ?? 'default';
      final cached = prefs.getString('doctor_schedule_$effectiveUid');
      if (cached != null && cached.isNotEmpty && mounted) {
        setState(() => _doctorSchedule = cached);
      }
    } catch (_) {}

    String? uid = widget.doctorId ?? AuthService.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) {
      _resolvedDoctorUid = uid;
      _subscribeToChats();
      _subscribeToBookingNotifications();
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
          // Field Informasi Praktik & SIP
          _sipNumber = (data['sipNumber'] as String? ?? '').trim();
          _practicePlace = (data['practicePlace'] as String? ?? '').trim();
          _sipExpiry = (data['sipExpiry'] as String? ?? '').trim();
          _education = (data['education'] as String? ?? '').trim();
          _experience = (data['experience'] as String? ?? '').trim();
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
    _bookingNotificationsSub?.cancel();
    _patientPhotosSub?.cancel();
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
    final newlyReadIds = _bookingNotifications
        .where((b) => !b.isDoctorRead && !_readBookingIds.contains(b.id))
        .map((b) => b.id)
        .toSet();

    _markAllNotificationsAsRead();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Grab handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softPinkCard,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
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
                            'Notifikasi Booking Pasien',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF141414),
                            ),
                          ),
                          if (_bookingNotifications.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (newlyReadIds.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${newlyReadIds.length} Baru',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Total ${_bookingNotifications.length}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 3),
                          Text(
                            'Jadwal konsultasi yang dibooking pasien secara real-time',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF757575)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),

              // Content List
              Expanded(
                child: _bookingNotifications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF0F5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_available_rounded,
                                  color: AppColors.primary,
                                  size: 38,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum Ada Booking Jadwal',
                                style: GoogleFonts.poppins(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ketika pasien memilih dan membooking jadwal konsultasi dengan Anda, notifikasi akan langsung muncul di sini secara real-time.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        itemCount: _bookingNotifications.length,
                        itemBuilder: (context, index) {
                          final booking = _bookingNotifications[index];
                          final isNew = newlyReadIds.contains(booking.id);
                          final patientPhoto = _patientPhotosCache[booking.patientId] ??
                              _patientPhotosCache[booking.patientName.toLowerCase().trim()];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isNew ? const Color(0xFFFFF0F5) : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isNew ? const Color(0xFFF48FB1) : const Color(0xFFEEEEEE),
                                width: isNew ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Avatar, Name, Status Badge
                                Row(
                                  children: [
                                    DoctorAvatarWidget(
                                      photoUrl: patientPhoto,
                                      size: 42,
                                      initials: booking.patientName.isNotEmpty ? booking.patientName[0] : null,
                                      backgroundColor: AppColors.primary,
                                      iconColor: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  booking.patientName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF212121),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (isNew)
                                                    Container(
                                                      margin: const EdgeInsets.only(right: 6),
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEF4444),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        'BARU',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.w800,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFE8F5E9),
                                                      borderRadius: BorderRadius.circular(10),
                                                      border: Border.all(color: const Color(0xFF81C784)),
                                                    ),
                                                    child: Text(
                                                      'Terkonfirmasi',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w600,
                                                        color: const Color(0xFF2E7D32),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Membooking jadwal konsultasi',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: const Color(0xFF757575),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Schedule Details Box
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFFFD1DC)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              booking.date,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF333333),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary),
                                          const SizedBox(width: 5),
                                          Text(
                                            '${booking.timeSlot} WIB',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (booking.complaint.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF888888)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  'Keluhan: "${booking.complaint}"',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: const Color(0xFF555555),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Action Buttons
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        elevation: 1,
                                      ),
                                      onPressed: () => _openChatFromBooking(booking),
                                      icon: const Icon(Icons.chat_rounded, size: 15),
                                      label: Text(
                                        'Buka Chat Pasien',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
        child: Row(
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
                    if (_unreadBookingCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '${_unreadBookingCount > 9 ? '9+' : _unreadBookingCount}',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
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
      ),
    );
  }

  /// 2 Summary Metric Cards (Total pasien & Chat belum dibaca dinamis)
  Widget _buildSummaryCards() {
    final totalPatients = _totalPatientCount;
    final unreadCount = _chats.fold<int>(0, (acc, chat) => acc + chat.unreadCount);

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
                DoctorAvatarWidget(
                  photoUrl: (chat.patientPhotoUrl != null && chat.patientPhotoUrl!.isNotEmpty)
                      ? chat.patientPhotoUrl
                      : (_patientPhotosCache[chat.patientId] ??
                          _patientPhotosCache[chat.name.toLowerCase().trim()]),
                  size: 42,
                  initials: chat.name.isNotEmpty ? chat.name[0] : null,
                  backgroundColor: AppColors.primary,
                  iconColor: Colors.white,
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
  /// Hanya menu 'Beranda' (index 0) dan 'Profil' (index 1).
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
      padding: const EdgeInsets.symmetric(horizontal: 56),
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
            label: 'Profil',
            icon: _selectedTabIndex == 1 ? Icons.account_circle_rounded : Icons.account_circle_outlined,
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
              title: 'Jadwal & Booking Pasien',
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

  /// Bottom Sheet untuk Mengubah Jadwal Konsultasi Dokter & Mengakses Jam Dibooking Pasien
  void _showEditScheduleBottomSheet() {
    final TextEditingController scheduleController =
        TextEditingController(text: _doctorSchedule);
    String selectedDays = 'Senin - Jumat';
    String selectedHours = '09:00 - 17:00';
    bool isSaving = false;
    int activeTab = 0; // 0: Atur Jadwal, 1: Jam Dibooking Pasien, 2: Per Tanggal
    // === STATE UNTUK TAB PER TANGGAL ===
    final now = DateTime.now();
    DateTime calDisplayedMonth = DateTime(now.year, now.month, 1);
    DateTime calSelectedDate = DateTime(now.year, now.month, now.day);
    Set<String> calSelectedSlots = {};
    bool isLoadingSlots = false;

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

    final effectiveDoctorId = _resolvedDoctorUid ??
        widget.doctorId ??
        AuthService.instance.currentUser?.uid ??
        '';
    final effectiveDoctorName = _doctorDisplayName.isNotEmpty
        ? _doctorDisplayName
        : widget.doctorName;

    bool hasInitializedSlots = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (!hasInitializedSlots) {
              hasInitializedSlots = true;
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                try {
                  final dateKey =
                      '${calSelectedDate.year.toString()}-${calSelectedDate.month.toString().padLeft(2, '0')}-${calSelectedDate.day.toString().padLeft(2, '0')}';
                  final snap = await FirebaseFirestore.instance
                      .collection('doctors')
                      .doc(effectiveDoctorId)
                      .collection('custom_slots')
                      .doc(dateKey)
                      .get();
                  final data = snap.data();
                  final slots = (data != null && data['slots'] is List)
                      ? Set<String>.from((data['slots'] as List).map((e) => e.toString()))
                      : <String>{};
                  if (ctx.mounted) {
                    setModalState(() {
                      calSelectedSlots = slots;
                      isLoadingSlots = false;
                    });
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    setModalState(() => isLoadingSlots = false);
                  }
                }
              });
            }

            void updateCombinedText(String days, String hours) {
              setModalState(() {
                selectedDays = days;
                selectedHours = hours;
                scheduleController.text = '$days ($hours)';
              });
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: StreamBuilder<List<ConsultationBookingModel>>(
                stream: ConsultationBookingService.instance.streamAllDoctorBookings(
                  doctorId: effectiveDoctorId,
                  doctorName: effectiveDoctorName,
                ),
                builder: (context, bookingSnap) {
                  final bookings = bookingSnap.data ?? [];
                  final bookingCount = bookings.length;

                  return Column(
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
                      const SizedBox(height: 16),

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
                                  'Jadwal & Booking Pasien',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF212121),
                                  ),
                                ),
                                Text(
                                  'Kelola jam praktik & pantau slot yang dibooking pasien',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF9E9E9E),
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tab Switcher Bar: Atur Jadwal vs Jam Dibooking Pasien
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F7),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => activeTab = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: activeTab == 0
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: activeTab == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_month_outlined,
                                        size: 16,
                                        color: activeTab == 0
                                            ? AppColors.primary
                                            : const Color(0xFF757575),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Atur Jadwal',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: activeTab == 0
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: activeTab == 0
                                                ? AppColors.primary
                                                : const Color(0xFF757575),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setModalState(() => activeTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: activeTab == 1
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: activeTab == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.access_time_filled_rounded,
                                        size: 16,
                                        color: activeTab == 1
                                            ? AppColors.primary
                                            : const Color(0xFF757575),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Jam Dibooking',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12.5,
                                            fontWeight: activeTab == 1
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            color: activeTab == 1
                                                ? AppColors.primary
                                                : const Color(0xFF757575),
                                          ),
                                        ),
                                      ),
                                      if (bookingCount > 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '$bookingCount',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),                      // Tab Content
                      Flexible(
                        child: SingleChildScrollView(
                          child: activeTab == 0
                              ? _buildScheduleSettingsTabContent(
                                  scheduleController: scheduleController,
                                  selectedDays: selectedDays,
                                  selectedHours: selectedHours,
                                  bookingCount: bookingCount,
                                  bookings: bookings,
                                  onSwitchToBookingsTab: () =>
                                      setModalState(() => activeTab = 1),
                                  updateCombinedText: updateCombinedText,
                                  calDisplayedMonth: calDisplayedMonth,
                                  calSelectedDate: calSelectedDate,
                                  calSelectedSlots: calSelectedSlots,
                                  isLoadingSlots: isLoadingSlots,
                                  onMonthChanged: (newMonth) =>
                                      setModalState(() => calDisplayedMonth = newMonth),
                                  onDateChanged: (newDate) async {
                                    setModalState(() {
                                      calSelectedDate = newDate;
                                      calSelectedSlots = {};
                                      isLoadingSlots = true;
                                    });
                                    try {
                                      final dateKey =
                                          '${newDate.year.toString()}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';
                                      final snap = await FirebaseFirestore.instance
                                          .collection('doctors')
                                          .doc(effectiveDoctorId)
                                          .collection('custom_slots')
                                          .doc(dateKey)
                                          .get();
                                      final data = snap.data();
                                      final slots = (data != null && data['slots'] is List)
                                          ? Set<String>.from((data['slots'] as List).map((e) => e.toString()))
                                          : <String>{};
                                      setModalState(() {
                                        calSelectedSlots = slots;
                                        isLoadingSlots = false;
                                      });
                                    } catch (_) {
                                      setModalState(() => isLoadingSlots = false);
                                    }
                                  },
                                  onSlotToggled: (slot, availableSlots) async {
                                    final currentChosen = Set<String>.from(calSelectedSlots);
                                    if (currentChosen.contains(slot)) {
                                      currentChosen.remove(slot);
                                    } else {
                                      currentChosen.add(slot);
                                    }

                                    setModalState(() => calSelectedSlots = currentChosen);
                                    final dateKey =
                                        '${calSelectedDate.year.toString()}-${calSelectedDate.month.toString().padLeft(2, '0')}-${calSelectedDate.day.toString().padLeft(2, '0')}';
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('doctors')
                                          .doc(effectiveDoctorId)
                                          .collection('custom_slots')
                                          .doc(dateKey)
                                          .set({
                                        'slots': currentChosen.toList()..sort(),
                                        'updatedAt': FieldValue.serverTimestamp(),
                                      });
                                    } catch (e) {
                                      debugPrint('Error saving slot: $e');
                                    }
                                  },
                                )
                              : _buildDoctorBookedSlotsTabContent(
                                  ctx: ctx,
                                  bookings: bookings,
                                  effectiveDoctorName: effectiveDoctorName,
                                  bottomSheetContext: bottomSheetContext,
                                ),
                        ),
                      ),

                      // Tombol Batal & Simpan (tab 0) atau Tutup (tab 2)
                      if (activeTab == 2) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(bottomSheetContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
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
                      if (activeTab == 0) ...[
                        const SizedBox(height: 12),
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
                                        final newSchedule = scheduleController.text.trim();
                                        final messenger = ScaffoldMessenger.of(context);
                                        if (newSchedule.isEmpty) {
                                          messenger.showSnackBar(
                                            const SnackBar(
                                              content: Text('Teks jadwal tidak boleh kosong.'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );
                                          return;
                                        }

                                        setModalState(() => isSaving = true);

                                        try {
                                          String? targetUid = _resolvedDoctorUid ??
                                              widget.doctorId ??
                                              AuthService.instance.currentUser?.uid;

                                          if (targetUid != null && targetUid.isNotEmpty) {
                                            await UserRepository.instance.updateDoctorSchedule(
                                              targetUid,
                                              newSchedule,
                                            );
                                          } else {
                                            final snap = await FirebaseFirestore.instance
                                                .collection('doctors')
                                                .where('fullName', isEqualTo: widget.doctorName)
                                                .limit(1)
                                                .get();
                                            if (snap.docs.isNotEmpty) {
                                              await snap.docs.first.reference.update({
                                                'schedule': newSchedule,
                                                'updatedAt': FieldValue.serverTimestamp(),
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
                                            messenger.showSnackBar(
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
                                                        'Jadwal dokter berhasil diperbarui & otomatis sinkron ke booking pasien.',
                                                        style: GoogleFonts.poppins(fontSize: 12.5),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor: const Color(0xFF2E7D32),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                margin: const EdgeInsets.all(16),
                                              ),
                                            );
                                          }
                                        } catch (err) {
                                          setModalState(() => isSaving = false);
                                          try {
                                            final prefs = await SharedPreferences.getInstance();
                                            final fallbackUid = _resolvedDoctorUid ?? widget.doctorId ?? AuthService.instance.currentUser?.uid ?? 'default';
                                            await prefs.setString('doctor_schedule_' + fallbackUid, newSchedule);
                                          } catch (_) {}
                                          if (mounted) {
                                            setState(() => _doctorSchedule = newSchedule);
                                          }
                                          if (bottomSheetContext.mounted) {
                                            Navigator.pop(bottomSheetContext);
                                          }
                                          if (mounted) {
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Jadwal diperbarui! (Sinkronisasi cloud: terapkan Rules di Firebase Console).',
                                                  style: GoogleFonts.poppins(fontSize: 12),
                                                ),
                                                backgroundColor: const Color(0xFFE65100),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                margin: const EdgeInsets.all(16),
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
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  /// Tab Konten: Pengaturan Hari & Jam Praktik Dokter
  Widget _buildScheduleSettingsTabContent({
    required TextEditingController scheduleController,
    required String selectedDays,
    required String selectedHours,
    required int bookingCount,
    required List<ConsultationBookingModel> bookings,
    required VoidCallback onSwitchToBookingsTab,
    required Function(String, String) updateCombinedText,
    required DateTime calDisplayedMonth,
    required DateTime calSelectedDate,
    required Set<String> calSelectedSlots,
    required bool isLoadingSlots,
    required Function(DateTime) onMonthChanged,
    required Function(DateTime) onDateChanged,
    required Function(String, List<String>) onSlotToggled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kartu status sinkronisasi real-time
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.softPinkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.softPinkBorder.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.sync_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Perubahan jam & hari praktik dokter otomatis menyelaraskan slot ketersediaan di halaman booking pasien secara langsung.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF4A4A4A),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF424242),
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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : const Color(0xFF424242),
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
        const SizedBox(height: 18),

        // Teks Format Jadwal
        Text(
          'Teks Format Jadwal',
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
        const SizedBox(height: 22),

        // ═════════════════════════════════════════════════════════════════════
        // BAGIAN: PILIH TANGGAL & ATUR JAM PRAKTIK (PERSIS GAMBAR 2)
        // ═════════════════════════════════════════════════════════════════════
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih tanggal',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
              ),
            ),
            Text(
              'Kalender Praktik',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Widget Kalender Kartu Putih Persis Gambar 2
        _buildDoctorCalendarCard(
          displayedMonth: calDisplayedMonth,
          selectedDate: calSelectedDate,
          onMonthChanged: onMonthChanged,
          onDateChanged: onDateChanged,
        ),

        const SizedBox(height: 20),

        // Header Pilihan Jam + Tanggal Terpilih
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pilih jam',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF212121),
              ),
            ),
            Text(
              _formatDateLabelForDoctor(calSelectedDate),
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid 4 Kolom Pilihan Jam Persis Gambar 2
        _buildDoctorTimeSlotsGrid(
          selectedHours: selectedHours,
          selectedSlots: calSelectedSlots,
          selectedDate: calSelectedDate,
          bookings: bookings,
          isLoadingSlots: isLoadingSlots,
          onSlotToggled: onSlotToggled,
        ),

        const SizedBox(height: 22),

        // ─── KARTU AKSES JAM DIBOOKING PASIEN LANGSUNG ──────────────────────
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 22),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bookings.isNotEmpty
                ? const Color(0xFFFFF7F9)
                : const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: bookings.isNotEmpty
                  ? AppColors.softPinkBorder
                  : const Color(0xFFE8E8E8),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: bookings.isNotEmpty
                          ? AppColors.primary
                          : const Color(0xFF757575),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.access_time_filled_rounded,
                        color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jam yang Telah Dibooking Pasien',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF212121),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bookings.isNotEmpty
                          ? AppColors.softPinkCard
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: bookings.isNotEmpty
                            ? AppColors.primary
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${bookings.length} Terisi',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: bookings.isNotEmpty
                            ? AppColors.primary
                            : const Color(0xFF757575),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (bookings.isEmpty) ...[
                Text(
                  'Belum ada pasien yang membooking jam konsultasi ini. Seluruh slot jam praktik dokter saat ini masih terbuka dan dapat dipesan pasien.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF616161),
                    height: 1.4,
                  ),
                ),
              ] else ...[
                Text(
                  'Slot jam konsultasi yang sudah dipesan pasien (terkoneksi real-time):',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF616161),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: bookings.take(6).map((b) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule,
                              size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            '${b.dateKey} • ${b.timeSlot}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${b.patientName.split(' ').first})',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: const Color(0xFF616161),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (bookings.length > 6) ...[
                  const SizedBox(height: 4),
                  Text(
                    '+ ${bookings.length - 6} booking lainnya',
                    style: GoogleFonts.poppins(
                        fontSize: 10.5, color: const Color(0xFF9E9E9E)),
                  ),
                ],
                const SizedBox(height: 10),
                InkWell(
                  onTap: onSwitchToBookingsTab,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat Rincian Pasien & Keluhan Lengkap',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: Format tanggal untuk header dokter
  // ─────────────────────────────────────────────────────────────────────────
  String _formatDateLabelForDoctor(DateTime date) {
    const dayNames = ['','Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
    const monthNames = [
      '', 'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    final dayName = dayNames[date.weekday];
    return '$dayName, ${date.day} ${monthNames[date.month]}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: Widget Kalender Dokter (Persis Gambar 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorCalendarCard({
    required DateTime displayedMonth,
    required DateTime selectedDate,
    required Function(DateTime) onMonthChanged,
    required Function(DateTime) onDateChanged,
  }) {
    const Color headerPink = Color(0xFFE5406C);
    const Color selectedSlotPink = Color(0xFFE52865);
    const Color textDark = Color(0xFF222222);
    const Color textGrey = Color(0xFF757575);

    const monthNames = [
      '', 'Januari','Februari','Maret','April','Mei','Juni',
      'Juli','Agustus','September','Oktober','November','Desember'
    ];
    const weekTitles = ['Min','Sen','Sel','Rab','Kam','Jum','Sab'];

    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekdayOffset = DateTime(year, month, 1).weekday % 7;

    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final bool canGoPreviousMonth = !displayedMonth.isBefore(DateTime(todayMidnight.year, todayMidnight.month, 1));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bulan & Navigasi < >
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: canGoPreviousMonth
                    ? () => onMonthChanged(DateTime(displayedMonth.year, displayedMonth.month - 1, 1))
                    : null,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: canGoPreviousMonth ? const Color(0xFFFDECEF) : const Color(0xFFF5F5F5),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: canGoPreviousMonth ? headerPink : const Color(0xFFC7C7C7),
                    ),
                  ),
                ),
              ),
              Text(
                '${monthNames[month]} $year',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
              InkWell(
                onTap: () => onMonthChanged(DateTime(displayedMonth.year, displayedMonth.month + 1, 1)),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFDECEF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: headerPink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Header Hari (Min, Sen, Sel, Rab, Kam, Jum, Sab)
          Row(
            children: weekTitles.map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textGrey,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Grid Tanggal 7 Kolom
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ((firstWeekdayOffset + daysInMonth) > 35) ? 42 : 35,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - firstWeekdayOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(year, month, dayNumber);
              final isSelected = selectedDate.year == cellDate.year &&
                  selectedDate.month == cellDate.month &&
                  selectedDate.day == cellDate.day;
              final isPast = cellDate.isBefore(todayMidnight);

              return InkWell(
                onTap: isPast ? null : () => onDateChanged(cellDate),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? selectedSlotPink : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isPast ? const Color(0xFFC7C7C7) : textDark),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helper: Grid 4 Kolom Pilihan Jam Dokter (Persis Gambar 2)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDoctorTimeSlotsGrid({
    required String selectedHours,
    required Set<String> selectedSlots,
    required DateTime selectedDate,
    required List<ConsultationBookingModel> bookings,
    required bool isLoadingSlots,
    required Function(String, List<String>) onSlotToggled,
  }) {
    List<String> generateSlots(String hoursRange) {
      try {
        final parts = hoursRange.split(' - ');
        if (parts.length < 2) return [];
        final startParts = parts[0].trim().split(':');
        final endParts = parts[1].trim().split(':');
        int startH = int.parse(startParts[0]);
        int startM = int.parse(startParts[1]);
        int endH = int.parse(endParts[0]);
        int endM = int.parse(endParts[1]);

        final slots = <String>[];
        int curH = startH, curM = startM;
        while (curH < endH || (curH == endH && curM < endM)) {
          if (!(curH == 12 || (curH == 11 && curM == 30))) {
            slots.add('${curH.toString().padLeft(2, '0')}:${curM.toString().padLeft(2, '0')}');
          }
          curM += 30;
          if (curM >= 60) { curM -= 60; curH += 1; }
        }
        return slots;
      } catch (_) {
        return ['08:00','08:30','09:00','09:30','10:00','10:30','11:00','11:30','13:00','13:30','14:00','14:30','15:00','15:30','16:00','16:30'];
      }
    }

    final slots = generateSlots(selectedHours);

    if (isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
        ),
      );
    }

    final dateKey =
        '${selectedDate.year.toString()}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        const spacing = 8.0;
        final itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: 10,
              children: slots.map((slot) {
                // Cek apakah slot ini sudah berhasil dibooking pasien pada tanggal ini
                final isBookedByPatient = bookings.any((b) =>
                    b.dateKey.trim() == dateKey &&
                    b.timeSlot.trim() == slot &&
                    b.status.toLowerCase() != 'cancelled');

                // Cek apakah slot ini ditandai/dipilih oleh dokter sebagai sudah dipilih / tutup
                final isChosenByDoctor = selectedSlots.contains(slot);

                // Slot sudah dipilih jika dibooking pasien ATAU dipilih dokter
                final isChosen = isBookedByPatient || isChosenByDoctor;

                return SizedBox(
                  width: itemWidth,
                  height: 38,
                  child: InkWell(
                    onTap: isBookedByPatient
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Jam $slot sudah berhasil dibooking oleh pasien.'),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : () => onSlotToggled(slot, slots),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        // JIKA SUDAH DIPILIH: WARNA ABU-ABU SEBAGAI PENANDA
                        // JIKA BELUM DIPILIH: WARNA PUTIH BORDER PINK
                        color: isChosen ? const Color(0xFFF2F3F5) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isChosen ? const Color(0xFFDCDFE4) : const Color(0xFFF5B5C8),
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        slot,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: isChosen ? FontWeight.w600 : FontWeight.w500,
                          color: isChosen ? const Color(0xFF90949C) : const Color(0xFF222222),
                          decoration: isChosen ? TextDecoration.lineThrough : null,
                          decorationColor: const Color(0xFF90949C),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            // Penanda / Legend Status Warna
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFF5B5C8), width: 1.2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Tersedia',
                  style: GoogleFonts.poppins(fontSize: 10.5, color: const Color(0xFF616161)),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F5),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFDCDFE4), width: 1.2),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Sudah Dipilih (Abu-abu)',
                  style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF757575)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Klik jam untuk memilih atau mengubah status ketersediaan. Otomatis tersinkron.',
              style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF9E9E9E)),
            ),
          ],
        );
      },
    );
  }

  /// Tab Konten: Daftar Jam yang Telah Dibooking oleh Pasien
  Widget _buildDoctorBookedSlotsTabContent({
    required BuildContext ctx,
    required List<ConsultationBookingModel> bookings,
    required String effectiveDoctorName,
    required BuildContext bottomSheetContext,
  }) {
    if (bookings.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softPinkCard,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_available_rounded,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Belum Ada Jam Dibooking',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saat pasien memilih jam konsultasi melalui fitur booking, detail jam, tanggal, dan nama pasien akan otomatis tampil di sini secara real-time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF757575),
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar Booking Aktif (${bookings.length})',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF333333),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Real-Time',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: bookings.length,
          separatorBuilder: (_, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final b = bookings[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.softPinkBorder.withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Time badge, Date, and Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.alarm_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${b.timeSlot} WIB',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.date,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF424242),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Terkonfirmasi',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Row 2: Patient Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.softPinkCard,
                        child: const Icon(
                          Icons.person_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          b.patientName,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF212121),
                          ),
                        ),
                      ),
                      if (b.totalAmount != null)
                        Text(
                          'Rp ${b.totalAmount}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF757575),
                          ),
                        ),
                    ],
                  ),

                  // Row 3: Complaint (if any)
                  if (b.complaint.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFECECEC)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Keluhan: "${b.complaint}"',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF616161),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Action Buttons: Mulai Chat Pasien & Batalkan Sesi
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => DoctorChatDetailScreen(
                                  doctorName: effectiveDoctorName,
                                  patientName: b.patientName,
                                  patientId: b.patientId,
                                  initialMessage:
                                      'Halo ${b.patientName}, saya $effectiveDoctorName. Jadwal konsultasi Anda jam ${b.timeSlot} (${b.date}) telah saya konfirmasi. Apakah ada keluhan lanjutan yang ingin disampaikan?',
                                  glucoseNote: b.complaint.isNotEmpty
                                      ? 'Keluhan: ${b.complaint}'
                                      : 'Pasien Konsultasi Booking',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_rounded, size: 15),
                          label: Text(
                            'Buka Chat Pasien',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (dCtx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              title: Text(
                                'Batalkan Booking?',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                'Apakah Anda yakin ingin membatalkan slot jam ${b.timeSlot} untuk pasien ${b.patientName}?',
                                style: GoogleFonts.poppins(fontSize: 12.5),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: Text(
                                    'Kembali',
                                    style: GoogleFonts.poppins(
                                        color: const Color(0xFF757575)),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'Batalkan',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await ConsultationBookingService.instance
                                  .cancelBooking(b.id);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Booking slot jam ${b.timeSlot} berhasil dibatalkan.',
                                      style: GoogleFonts.poppins(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Gagal membatalkan: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Batalkan',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Bottom Sheet untuk Informasi Praktik & SIP (editable)
  void _showPracticeInfoBottomSheet() {
    final doctorName = _doctorDisplayName.isNotEmpty
        ? _doctorDisplayName
        : widget.doctorName;

    // Controllers
    final sipCtrl = TextEditingController(text: _sipNumber);
    final placeCtrl = TextEditingController(text: _practicePlace);
    final expiryCtrl = TextEditingController(text: _sipExpiry);
    final eduCtrl = TextEditingController(text: _education);
    final expCtrl = TextEditingController(text: _experience);

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> saveData() async {
              setSheetState(() => isSaving = true);
              final uid = _resolvedDoctorUid ??
                  widget.doctorId ??
                  AuthService.instance.currentUser?.uid;
              if (uid == null || uid.isEmpty) {
                setSheetState(() => isSaving = false);
                return;
              }
              try {
                await FirebaseFirestore.instance
                    .collection('doctors')
                    .doc(uid)
                    .set({
                  'sipNumber': sipCtrl.text.trim(),
                  'practicePlace': placeCtrl.text.trim(),
                  'sipExpiry': expiryCtrl.text.trim(),
                  'education': eduCtrl.text.trim(),
                  'experience': expCtrl.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));

                setState(() {
                  _sipNumber = sipCtrl.text.trim();
                  _practicePlace = placeCtrl.text.trim();
                  _sipExpiry = expiryCtrl.text.trim();
                  _education = eduCtrl.text.trim();
                  _experience = expCtrl.text.trim();
                });

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Informasi Praktik & SIP berhasil disimpan.',
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: Colors.white),
                        ),
                        backgroundColor: const Color(0xFF2E7D32),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                }
              } catch (e) {
                setSheetState(() => isSaving = false);
                if (ctx.mounted) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Gagal menyimpan: $e',
                          style: GoogleFonts.poppins(
                              fontSize: 12.5, color: Colors.white),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            }

            InputDecoration fieldDecoration(String label, String hint) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                labelStyle: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFF9E9E9E)),
                hintStyle: GoogleFonts.poppins(
                    fontSize: 12, color: const Color(0xFFBDBDBD)),
                filled: true,
                fillColor: const Color(0xFFFFF0F5),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD1DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD1DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              );
            }

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
                                'Edit data verifikasi medis dan lisensi dokter',
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
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

                    // Read-only: Nama Lengkap
                    _buildPracticeInfoItem(
                      icon: Icons.person_rounded,
                      label: 'Nama Lengkap',
                      value: doctorName,
                    ),
                    // Read-only: Spesialisasi
                    _buildPracticeInfoItem(
                      icon: Icons.medical_services_rounded,
                      label: 'Spesialisasi',
                      value: _doctorSpecialty,
                    ),

                    const SizedBox(height: 6),
                    Text(
                      'Data yang dapat diedit:',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Editable fields
                    TextField(
                      controller: sipCtrl,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: fieldDecoration(
                          'Nomor SIP', 'cth: 446.1/128/SIP-D/2022'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: placeCtrl,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: fieldDecoration(
                          'Tempat Praktik', 'cth: RS D-Care Sejahtera'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expiryCtrl,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: fieldDecoration(
                          'Masa Berlaku SIP',
                          'cth: 01 Januari 2022 - 31 Desember 2027'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: eduCtrl,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: fieldDecoration('Pendidikan Terakhir',
                          'cth: Fakultas Kedokteran UI'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: expCtrl,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: fieldDecoration(
                          'Pengalaman', 'cth: 8+ Tahun Praktik Klinis'),
                    ),
                    const SizedBox(height: 20),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              side: const BorderSide(
                                  color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Tutup',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving ? null : saveData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.6),
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Simpan',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
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
                  value.isNotEmpty ? value : '-',
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
    final activeDoctorName = _doctorDisplayName.trim().isNotEmpty
        ? _doctorDisplayName.trim()
        : (widget.doctorName.trim().isNotEmpty ? widget.doctorName.trim() : 'dr. Yosua');
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
          'Apakah Anda yakin ingin keluar dari akun $activeDoctorName?',
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
  final String? patientId;

  const DoctorChatDetailScreen({
    super.key,
    this.chatId,
    required this.doctorName,
    required this.patientName,
    required this.initialMessage,
    required this.glucoseNote,
    this.patientId,
  });

  @override
  State<DoctorChatDetailScreen> createState() => _DoctorChatDetailScreenState();
}

class _DoctorChatDetailScreenState extends State<DoctorChatDetailScreen> {
  String? _patientPhoto;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<List<RealtimeChatMessage>>? _msgSubscription;
  StreamSubscription<DocumentSnapshot>? _chatDocSubscription;
  String? _activeChatId;

  // Manajemen Timer Konsultasi 25 Menit
  Timer? _countdownTimer;
  DateTime? _expiresAt;
  Duration _remainingDuration = const Duration(minutes: 25);
  bool _isConsultationEnded = false;
  bool _hasShownEndedDialog = false;

  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadPatientPhoto();
    _activeChatId = widget.chatId;
    if (_activeChatId != null && _activeChatId!.isNotEmpty) {
      _bindChatSession(_activeChatId!);
    } else {
      _ensureChatId();
    }
  }

  Future<void> _ensureChatId() async {
    try {
      final id = await ChatService.instance.getOrCreateChatForDoctor(
        doctorName: widget.doctorName,
        patientName: widget.patientName,
        patientId: widget.patientId,
        glucoseNote: widget.glucoseNote,
      );
      if (!mounted) return;
      setState(() {
        _activeChatId = id;
      });
      _bindChatSession(id);
    } catch (e) {
      debugPrint('⚠️ Error initializing doctor chat ID: $e');
    }
  }

  void _bindChatSession(String cid) {
    _msgSubscription?.cancel();
    _chatDocSubscription?.cancel();

    ChatService.instance.markAsReadByDoctor(cid);
    _msgSubscription = ChatService.instance
        .streamMessages(cid)
        .listen((items) {
      if (!mounted) return;
      final currentUid = ChatService.instance.currentUid ?? '';
      setState(() {
        _messages = items
            .where((m) =>
                !m.isDeletedFor('doctor') &&
                (currentUid.isEmpty || !m.isDeletedFor(currentUid)))
            .map((m) => {
                  'id': m.id,
                  'text': m.text,
                  'isDoctor': m.isDoctor,
                  'isSystem': m.isSystem,
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

    // Pantau dokumen chat untuk status konsultasi & batas durasi 25 menit
    _chatDocSubscription = FirebaseFirestore.instance
        .collection('consultation_chats')
        .doc(cid)
        .snapshots()
        .listen((chatDoc) {
      if (!mounted) return;
      if (chatDoc.exists && chatDoc.data() != null) {
        final data = chatDoc.data()!;
        final status = data['status']?.toString() ?? 'active';
        final expTs = data['expiresAt'] as Timestamp?;
        final createdTs = data['createdAt'] as Timestamp?;
        DateTime? expDt = expTs?.toDate();
        if (expDt == null && createdTs != null) {
          expDt = createdTs.toDate().add(const Duration(minutes: 25));
        }

        if (expDt != null) {
          _expiresAt = expDt;
          final isTimeExpired = DateTime.now().isAfter(expDt);
          final ended = (status == 'ended' || isTimeExpired);

          if (ended != _isConsultationEnded) {
            setState(() {
              _isConsultationEnded = ended;
            });
          }

          if (ended) {
            _remainingDuration = Duration.zero;
            _countdownTimer?.cancel();
            _showConsultationEndedNotification();
          } else {
            _startCountdownTimer();
          }
        }
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    if (_expiresAt == null || _isConsultationEnded) return;

    void updateRemaining() {
      if (!mounted) return;
      final now = DateTime.now();
      final diff = _expiresAt!.difference(now);
      if (diff.isNegative || diff.inSeconds <= 0) {
        _countdownTimer?.cancel();
        setState(() {
          _remainingDuration = Duration.zero;
          _isConsultationEnded = true;
        });
        if (widget.chatId != null && widget.chatId!.isNotEmpty) {
          ChatService.instance.endConsultation(widget.chatId!);
        }
        _showConsultationEndedNotification();
      } else {
        setState(() {
          _remainingDuration = diff;
        });
      }
    }

    updateRemaining();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      updateRemaining();
    });
  }

  void _showConsultationEndedNotification() {
    if (_hasShownEndedDialog || !mounted) return;
    _hasShownEndedDialog = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF8BBD0), width: 2),
                ),
                child: const Icon(
                  Icons.timer_off_rounded,
                  color: Color(0xFFD81B60),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Waktu Konsultasi Berakhir',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Durasi konsultasi 25 menit dengan pasien ${widget.patientName} telah selesai. Ruang percakapan otomatis ditutup.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF616161),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _chatDocSubscription?.cancel();
    _msgSubscription?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadPatientPhoto() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("fullName", isEqualTo: widget.patientName)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty && mounted) {
        final p = snap.docs.first.data()["photoUrl"]?.toString();
        if (p != null && p.isNotEmpty) {
          setState(() => _patientPhoto = p);
          return;
        }
      }
      final snapUser = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: widget.patientName.toLowerCase().trim())
          .limit(1)
          .get();
      if (snapUser.docs.isNotEmpty && mounted) {
        final p = snapUser.docs.first.data()["photoUrl"]?.toString();
        if (p != null && p.isNotEmpty) {
          setState(() => _patientPhoto = p);
        }
      }
    } catch (_) {}
  }

  void _sendMessage({
    String? customText,
    String type = 'text',
    String? attachmentData,
    String? attachmentName,
    String? attachmentSize,
  }) async {
    if (_isConsultationEnded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sesi konsultasi 25 menit telah berakhir. Anda tidak dapat mengirim pesan lagi.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    final text = (customText ?? _msgController.text).trim();
    if (text.isEmpty && attachmentData == null) return;

    if (customText == null) {
      _msgController.clear();
    }

    if (_activeChatId == null || _activeChatId!.isEmpty) {
      await _ensureChatId();
    }

    if (_activeChatId != null && _activeChatId!.isNotEmpty) {
      try {
        await ChatService.instance.sendMessage(
          chatId: _activeChatId!,
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

  Future<void> _openCameraFlow() async {
    try {
      final resultBase64 = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => const InAppCameraScreen(
            title: 'Kamera Medis Dokter',
            subtitle: 'Arahkan kamera ke berkas medis atau kondisi fisik pasien',
          ),
        ),
      );

      if (resultBase64 != null && resultBase64.isNotEmpty) {
        final bytes = base64Decode(resultBase64);
        final sizeKb = (bytes.lengthInBytes / 1024).round();
        final sizeStr = sizeKb > 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
            : '$sizeKb KB';

        _sendMessage(
          type: 'image',
          attachmentData: resultBase64,
          attachmentName:
              'Foto_Medis_${DateTime.now().millisecondsSinceEpoch}.jpg',
          attachmentSize: sizeStr,
        );
      }
    } catch (e) {
      debugPrint('⚠️ Error in camera flow: $e');
      _pickAndSendImage(ImageSource.camera);
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
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    colors: const [Color(0xFFFF5252), Color(0xFFFF1744)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _openCameraFlow();
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
                  'Hapus Pesan',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  'Hapus pesan ini dari percakapan',
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
    if (messageId.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Hapus Pesan?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pesan ini?',
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              setState(() {
                _messages.removeWhere((m) => m['id'] == messageId);
              });
              if (widget.chatId != null && widget.chatId!.isNotEmpty) {
                try {
                  await ChatService.instance.deleteMessage(
                    chatId: widget.chatId!,
                    messageId: messageId,
                  );
                } catch (e) {
                  debugPrint('Error delete message: $e');
                }
              }
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Pesan berhasil dihapus', style: GoogleFonts.poppins()),
                  backgroundColor: const Color(0xFF333333),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text('Hapus', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
            DoctorAvatarWidget(
              photoUrl: _patientPhoto,
              size: 38,
              initials: widget.patientName.isNotEmpty ? widget.patientName[0] : null,
              border: Border.all(color: Colors.white, width: 1.5),
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              iconColor: Colors.white,
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
          _buildDoctorTimerBanner(),
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
                final isDoctor = (m['isDoctor'] as bool?) ?? false;
                return _buildMessageBubble(m, isDoctor);
              },
            ),
          ),
          _isConsultationEnded
              ? _buildLockedDoctorInputBanner()
              : _buildInputBar(),
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
    final String type = (m['type'] as String?) ?? 'text';
    final bool isSystem = (m['isSystem'] as bool?) ?? (type == 'system');
    final String text = (m['text'] as String?) ?? '';

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF8BBD0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 16, color: Color(0xFFD81B60)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF880E4F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isRead = (m['read'] as bool?) ?? false;
    final String? attachmentData = m['attachmentData'] as String?;
    final String? attachmentName = m['attachmentName'] as String?;
    final String? attachmentSize = m['attachmentSize'] as String?;

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

  Widget _buildDoctorTimerBanner() {
    final minutes = _remainingDuration.inMinutes;
    final seconds = _remainingDuration.inSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final isWarning = !_isConsultationEnded && _remainingDuration.inMinutes < 5;

    if (_isConsultationEnded) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: const BoxDecoration(
          color: Color(0xFFFCE4EC),
          border: Border(bottom: BorderSide(color: Color(0xFFF8BBD0), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_rounded, size: 16, color: Color(0xFFD81B60)),
            const SizedBox(width: 8),
            Text(
              'Sesi Konsultasi Berakhir (Batas 25 Menit)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF880E4F),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF3E0) : const Color(0xFFFFF0F5),
        border: Border(
          bottom: BorderSide(
            color: isWarning ? const Color(0xFFFFCC80) : const Color(0xFFF8BBD0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.timer_outlined,
            size: 16,
            color: isWarning ? const Color(0xFFE65100) : AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            isWarning
                ? 'Sisa Waktu Konsultasi: $timeStr (Hampir Habis)'
                : 'Sisa Waktu Konsultasi: $timeStr',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isWarning ? const Color(0xFFE65100) : const Color(0xFF880E4F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedDoctorInputBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: const Color(0xFFFCE4EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFF48FB1)),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Color(0xFFD81B60),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sesi Konsultasi Telah Selesai',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF880E4F),
                    ),
                  ),
                  Text(
                    'Waktu konsultasi 25 menit bersama pasien telah habis.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFFAD1457),
                    ),
                  ),
                ],
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
              // Spacer penyeimbang tombol kembali agar judul tetap berada di tengah
              const SizedBox(width: 48),
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
