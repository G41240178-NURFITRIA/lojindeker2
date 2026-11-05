import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../features/doctor/screens/doctor_dashboard_screen.dart';
import 'notification_service.dart';
import 'session_service.dart';

/// Service untuk menangani notifikasi pesan masuk dari pasien bagi dokter.
/// - Menembakkan notifikasi lokal sistem HP (muncul saat dokter keluar aplikasi / background / layar mati).
/// - Menampilkan banner notifikasi melayang di dalam aplikasi (In-App Floating Banner) saat dokter di layar lain.
class DoctorChatNotificationService {
  DoctorChatNotificationService._internal();
  static final DoctorChatNotificationService instance =
      DoctorChatNotificationService._internal();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSubscription;
  String? _currentDoctorUid;
  String? _currentDoctorName;

  /// ID chat yang saat ini sedang dibuka oleh dokter (agar tidak memicu notifikasi berulang di chat aktif)
  String? activeChatId;

  /// Notifier total pesan pasien yang belum dibaca dokter (untuk badge/titik merah)
  final ValueNotifier<int> unreadTotalNotifier = ValueNotifier<int>(0);

  final Map<String, String> _lastKnownMessages = {};
  bool _isFirstSnapshot = true;
  OverlayEntry? _currentInAppBanner;
  Timer? _bannerAutoDismissTimer;

  /// Mulai memantau percakapan dokter saat login
  void startListening(String doctorUid, {String? doctorName}) {
    if (_currentDoctorUid == doctorUid &&
        _chatSubscription != null &&
        (_currentDoctorName == doctorName || doctorName == null)) {
      return;
    }

    stopListening();
    _currentDoctorUid = doctorUid;
    _currentDoctorName = doctorName;
    _isFirstSnapshot = true;

    _chatSubscription = FirebaseFirestore.instance
        .collection('consultation_chats')
        .snapshots()
        .listen(
      (snapshot) {
        _handleChatSnapshot(snapshot);
      },
      onError: (err) {
        debugPrint('⚠️ [DoctorChatNotificationService] Error stream: $err');
      },
    );
  }

  void _handleChatSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    int totalUnread = 0;
    final dUid = _currentDoctorUid ?? '';
    final dName = (_currentDoctorName ?? '').trim().toLowerCase();
    final cleanDName = dName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final docDoctorId = (data['doctorId'] ?? '').toString().trim();
      final docDoctorName =
          (data['doctorName'] ?? '').toString().trim().toLowerCase();
      final cleanDocDName =
          docDoctorName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

      // Verifikasi apakah chat ini ditujukan kepada dokter saat ini
      bool isMyChat = false;
      if (dUid.isNotEmpty && docDoctorId.isNotEmpty && docDoctorId == dUid) {
        isMyChat = true;
      } else if (cleanDName.isNotEmpty && cleanDocDName.isNotEmpty) {
        if (cleanDocDName.contains(cleanDName) ||
            cleanDName.contains(cleanDocDName)) {
          isMyChat = true;
        }
      }

      if (!isMyChat) continue;

      final unread = (data['unreadCountForDoctor'] as num?)?.toInt() ?? 0;
      totalUnread += unread;

      final lastMsg = data['lastMessage']?.toString() ?? '';
      final lastSenderRole = data['lastSenderRole']?.toString() ?? '';
      final previousMsg = _lastKnownMessages[doc.id];

      // Jika bukan snapshot pertama kali load dan ada pesan baru dari pasien
      if (!_isFirstSnapshot) {
        if (lastSenderRole == 'pasien' &&
            unread > 0 &&
            lastMsg.isNotEmpty &&
            lastMsg != previousMsg) {
          final lifecycle = WidgetsBinding.instance.lifecycleState;
          final bool isAppInBackground =
              lifecycle != null && lifecycle != AppLifecycleState.resumed;
          final bool isCurrentChatOpen =
              (activeChatId != null && activeChatId == doc.id);

          final patientName =
              data['patientName']?.toString().trim().isNotEmpty == true
                  ? data['patientName'].toString().trim()
                  : 'Pasien';
          final patientId = data['patientId']?.toString();
          final glucoseNote = data['glucoseNote']?.toString() ?? '';

          // 1. Notifikasi Sistem HP (Status Bar / Background / Minimize / Keluar Aplikasi)
          // Selalu tembakkan jika dokter keluar aplikasi atau tidak sedang membuka chat itu
          if (isAppInBackground || !isCurrentChatOpen) {
            NotificationService().showPatientMessageNotification(
              id: doc.id.hashCode,
              patientName: patientName,
              message: lastMsg,
            );
          }

          // 2. Notifikasi Melayang di Dalam Aplikasi (In-App Banner)
          // Hanya tampilkan jika aplikasi sedang aktif dibuka (foreground) dan tidak di dalam chat itu
          if (!isAppInBackground && !isCurrentChatOpen) {
            showInAppNotification(
              chatId: doc.id,
              patientName: patientName,
              doctorName: _currentDoctorName ?? 'Dokter',
              message: lastMsg,
              patientId: patientId,
              glucoseNote: glucoseNote,
            );
          }
        }
      }

      _lastKnownMessages[doc.id] = lastMsg;
    }

    _isFirstSnapshot = false;
    unreadTotalNotifier.value = totalUnread;
  }

  /// Hentikan pemantauan saat dokter logout
  void stopListening() {
    _chatSubscription?.cancel();
    _chatSubscription = null;
    _currentDoctorUid = null;
    _currentDoctorName = null;
    _isFirstSnapshot = true;
    _lastKnownMessages.clear();
    unreadTotalNotifier.value = 0;
    _dismissInAppNotification();
  }

  /// Menampilkan In-App Floating Notification Banner di bagian atas layar dokter
  void showInAppNotification({
    required String chatId,
    required String patientName,
    required String doctorName,
    required String message,
    String? patientId,
    String? glucoseNote,
  }) {
    final navContext = SessionService.navigatorKey.currentContext;
    if (navContext == null) return;

    _dismissInAppNotification();

    final overlayState = SessionService.navigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _currentInAppBanner = OverlayEntry(
      builder: (ctx) => _InAppPatientChatBanner(
        patientName: patientName,
        message: message,
        onTap: () {
          _dismissInAppNotification();
          final currentCtx = SessionService.navigatorKey.currentContext;
          if (currentCtx != null) {
            Navigator.push(
              currentCtx,
              MaterialPageRoute(
                builder: (_) => DoctorChatDetailScreen(
                  chatId: chatId,
                  doctorName: doctorName,
                  patientName: patientName,
                  initialMessage: message,
                  glucoseNote: (glucoseNote != null && glucoseNote.isNotEmpty)
                      ? glucoseNote
                      : 'Kondisi Pasien Terkontrol',
                  patientId: patientId,
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

/// Widget banner notifikasi melayang di atas layar dokter
class _InAppPatientChatBanner extends StatefulWidget {
  final String patientName;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppPatientChatBanner({
    required this.patientName,
    required this.message,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppPatientChatBanner> createState() =>
      _InAppPatientChatBannerState();
}

class _InAppPatientChatBannerState extends State<_InAppPatientChatBanner>
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
                    // Icon / Avatar Pasien dengan Badge Dot
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
                            Icons.person_rounded,
                            color: Color(0xFFD81B60),
                            size: 24,
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
                                  widget.patientName,
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
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F5F5),
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

