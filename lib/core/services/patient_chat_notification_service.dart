import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/patient/screens/live_chat_screen.dart';
import 'notification_service.dart';
import 'session_service.dart';

/// Service untuk menangani notifikasi balasan chat dokter bagi pasien.
/// - Menghitung jumlah pesan belum dibaca secara real-time untuk menampilkan titik merah (red dot).
/// - Menembakkan notifikasi lokal sistem HP (muncul saat app di luar / background selama ada sesi login).
/// - Menampilkan banner notifikasi melayang di dalam aplikasi (In-App Floating Notification).
class PatientChatNotificationService {
  PatientChatNotificationService._internal();
  static final PatientChatNotificationService instance =
      PatientChatNotificationService._internal();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSubscription;
  String? _currentPatientUid;

  /// ID chat yang saat ini sedang aktif dibuka oleh pasien (agar tidak memicu notif berulang)
  String? activeChatId;

  /// Notifier total pesan dokter yang belum dibaca pasien (untuk indikator titik merah)
  final ValueNotifier<int> unreadTotalNotifier = ValueNotifier<int>(0);

  /// Notifier map unread count per doctor ID & nama dokter
  final ValueNotifier<Map<String, int>> unreadDoctorMapNotifier =
      ValueNotifier<Map<String, int>>({});

  final Map<String, String> _lastKnownMessages = {};
  bool _isFirstSnapshot = true;
  OverlayEntry? _currentInAppBanner;
  Timer? _bannerAutoDismissTimer;

  /// Mulai memantau percakapan pasien saat login
  void startListening(String patientUid) {
    if (_currentPatientUid == patientUid && _chatSubscription != null) {
      return;
    }

    stopListening();
    _currentPatientUid = patientUid;
    _isFirstSnapshot = true;

    _chatSubscription = FirebaseFirestore.instance
        .collection('consultation_chats')
        .where('patientId', isEqualTo: patientUid)
        .snapshots()
        .listen(
      (snapshot) {
        _handleChatSnapshot(snapshot);
      },
      onError: (err) {
        debugPrint('⚠️ [PatientChatNotificationService] Error stream: $err');
      },
    );
  }

  void _handleChatSnapshot(
      QuerySnapshot<Map<String, dynamic>> snapshot) {
    int totalUnread = 0;
    final Map<String, int> doctorMap = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final unread = (data['unreadCountForPatient'] as num?)?.toInt() ?? 0;
      totalUnread += unread;

      final doctorId = data['doctorId']?.toString() ?? '';
      final doctorName = data['doctorName']?.toString() ?? '';

      if (doctorId.isNotEmpty) {
        doctorMap[doctorId] = (doctorMap[doctorId] ?? 0) + unread;
      }
      if (doctorName.isNotEmpty) {
        doctorMap[doctorName.toLowerCase().trim()] =
            (doctorMap[doctorName.toLowerCase().trim()] ?? 0) + unread;
      }

      final lastMsg = data['lastMessage']?.toString() ?? '';
      final lastSenderRole = data['lastSenderRole']?.toString() ?? '';
      final previousMsg = _lastKnownMessages[doc.id];

      // Jika bukan snapshot pertama kali load dan ada pesan baru dari dokter
      if (!_isFirstSnapshot) {
        if (lastSenderRole == 'doctor' &&
            unread > 0 &&
            lastMsg.isNotEmpty &&
            lastMsg != previousMsg) {
          // Hanya beri notifikasi jika user tidak sedang membuka chat ini
          if (activeChatId != doc.id) {
            final docDoctorName =
                data['doctorName']?.toString() ?? 'Dokter Spesialis';
            final docSpecialty = data['doctorSpecialty']?.toString() ??
                'Spesialis Penyakit Dalam';
            final docDoctorId = data['doctorId']?.toString();

            // 1. Notifikasi Sistem HP (Status Bar / Background / Minimize)
            NotificationService().showDoctorReplyNotification(
              id: doc.id.hashCode,
              doctorName: docDoctorName,
              message: lastMsg,
            );

            // 2. Notifikasi Melayang di Dalam Aplikasi (In-App Banner)
            showInAppNotification(
              doctorName: docDoctorName,
              doctorSpecialty: docSpecialty,
              message: lastMsg,
              doctorId: docDoctorId,
            );
          }
        }
      }

      _lastKnownMessages[doc.id] = lastMsg;
    }

    _isFirstSnapshot = false;
    unreadTotalNotifier.value = totalUnread;
    unreadDoctorMapNotifier.value = doctorMap;
  }

  /// Hentikan pemantauan saat pasien logout
  void stopListening() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _currentPatientUid = null;
    _isFirstSnapshot = true;
    _lastKnownMessages.clear();
    unreadTotalNotifier.value = 0;
    unreadDoctorMapNotifier.value = {};
    _dismissInAppNotification();
  }

  /// Menampilkan In-App Floating Notification Banner di bagian atas layar
  void showInAppNotification({
    required String doctorName,
    required String doctorSpecialty,
    required String message,
    String? doctorId,
  }) {
    final navContext = SessionService.navigatorKey.currentContext;
    if (navContext == null) return;

    _dismissInAppNotification();

    final overlayState = SessionService.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentInAppBanner = OverlayEntry(
      builder: (ctx) => _InAppDoctorChatBanner(
        doctorName: doctorName,
        doctorSpecialty: doctorSpecialty,
        message: message,
        onTap: () {
          _dismissInAppNotification();
          final currentCtx = SessionService.navigatorKey.currentContext;
          if (currentCtx != null) {
            Navigator.push(
              currentCtx,
              MaterialPageRoute(
                builder: (_) => LiveChatScreen(
                  doctorName: doctorName,
                  specialty: doctorSpecialty,
                  doctorId: doctorId,
                ),
              ),
            );
          }
        },
        onDismiss: _dismissInAppNotification,
      ),
    );

    overlayState.insert(_currentInAppBanner!);

    // Otomatis tutup banner setelah 4.5 detik
    _bannerAutoDismissTimer?.cancel();
    _bannerAutoDismissTimer = Timer(const Duration(milliseconds: 4500), () {
      _dismissInAppNotification();
    });
  }

  void _dismissInAppNotification() {
    _bannerAutoDismissTimer?.cancel();
    _bannerAutoDismissTimer = null;
    try {
      _currentInAppBanner?.remove();
    } catch (_) {}
    _currentInAppBanner = null;
  }
}

/// Widget banner notifikasi melayang di atas layar
class _InAppDoctorChatBanner extends StatefulWidget {
  final String doctorName;
  final String doctorSpecialty;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppDoctorChatBanner({
    required this.doctorName,
    required this.doctorSpecialty,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppDoctorChatBanner> createState() => _InAppDoctorChatBannerState();
}

class _InAppDoctorChatBannerState extends State<_InAppDoctorChatBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _closeWithAnim() {
    _animController.reverse().then((_) => widget.onDismiss());
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.up,
            onDismissed: (_) => widget.onDismiss(),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFF48FB1),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon / Avatar Dokter dengan Badge Dot
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFCE4EC),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Color(0xFFD81B60),
                            size: 22,
                          ),
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),

                    // Konten Pesan
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.doctorName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF212121),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'Baru saja',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  color: const Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.message,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF424242),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Tutup
                    GestureDetector(
                      onTap: _closeWithAnim,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Color(0xFF757575),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
