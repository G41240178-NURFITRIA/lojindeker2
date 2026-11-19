import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/session_config.dart';
import 'notification_service.dart';

/// Layanan Latar Belakang (Android Foreground Service) D-Care.
/// Mempertahankan koneksi Firestore chat saat aplikasi di-minimize atau recent apps di-swipe,
/// sehingga notifikasi chat tetap tembus selama sesi 2 menit belum kedaluwarsa.
class AppBackgroundService {
  AppBackgroundService._internal();
  static final AppBackgroundService instance = AppBackgroundService._internal();

  static const String _kBgActiveUserId = 'dcare_bg_active_user_id';
  static const String _kBgActiveUserRole = 'dcare_bg_active_user_role'; // 'pasien' | 'doctor'
  static const String _kBgActiveUserName = 'dcare_bg_active_user_name';

  bool _isServiceConfigured = false;

  /// Inisialisasi konfigurasi background service saat main()
  Future<void> initialize() async {
    if (kIsWeb) return; // Background service tidak digunakan pada Web
    if (_isServiceConfigured) return;

    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'dcare_background_keepalive',
        initialNotificationTitle: 'D-Care Siaga Latar Belakang',
        initialNotificationContent: 'Memantau pesan masuk (sesi aktif 2 menit)...',
        foregroundServiceNotificationId: 99999,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    _isServiceConfigured = true;
  }

  /// Aktifkan pemantauan background untuk pengguna saat ini
  Future<void> startKeepAlive({
    required String uid,
    required String role, // 'pasien' | 'doctor'
    String? name,
  }) async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBgActiveUserId, uid);
      await prefs.setString(_kBgActiveUserRole, role);
      if (name != null) {
        await prefs.setString(_kBgActiveUserName, name);
      }

      final service = FlutterBackgroundService();
      final isRunning = await service.isRunning();
      if (!isRunning) {
        await service.startService();
      } else {
        service.invoke('updateUser', {
          'uid': uid,
          'role': role,
          'name': name ?? '',
        });
      }
    } catch (e) {
      debugPrint('⚠️ [AppBackgroundService] startKeepAlive error: $e');
    }
  }

  /// Hentikan layanan latar belakang (misalnya saat logout atau sesi 2 menit habis)
  Future<void> stopKeepAlive() async {
    if (kIsWeb) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBgActiveUserId);
      await prefs.remove(_kBgActiveUserRole);
      await prefs.remove(_kBgActiveUserName);

      final service = FlutterBackgroundService();
      service.invoke('stopService');
    } catch (e) {
      debugPrint('⚠️ [AppBackgroundService] stopKeepAlive error: $e');
    }
  }
}

/// Fungsi latar belakang yang dieksekusi di Isolate terpisah oleh Android OS
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final notificationService = NotificationService();
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  String? currentUid = prefs.getString('dcare_bg_active_user_id');
  String? currentRole = prefs.getString('dcare_bg_active_user_role');
  String? currentName = prefs.getString('dcare_bg_active_user_name');

  StreamSubscription? chatSubscription;
  final Map<String, String> lastKnownMessages = {};
  bool isFirstSnapshot = true;

  void startFirestoreStream() {
    chatSubscription?.cancel();
    if (currentUid == null || currentUid.isEmpty) return;

    isFirstSnapshot = true;

    chatSubscription = FirebaseFirestore.instance
        .collection('consultation_chats')
        .snapshots()
        .listen((snapshot) {
      final myUid = currentUid ?? '';
      final myRole = currentRole ?? 'pasien';

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final docPatientId = data['patientId']?.toString() ?? '';
        final docDoctorId = data['doctorId']?.toString() ?? '';

        final bool isMyChat = (myRole == 'pasien' && docPatientId == myUid) ||
            (myRole == 'doctor' && docDoctorId == myUid);

        if (!isMyChat) continue;

        final unread = myRole == 'pasien'
            ? ((data['unreadCountForPatient'] as num?)?.toInt() ?? 0)
            : ((data['unreadCountForDoctor'] as num?)?.toInt() ?? 0);

        final lastMsg = data['lastMessage']?.toString() ?? '';
        final lastSenderRole = data['lastSenderRole']?.toString() ?? '';
        final previousMsg = lastKnownMessages[doc.id];

        final isFromOpposite = (myRole == 'pasien' && lastSenderRole == 'doctor') ||
            (myRole == 'doctor' && lastSenderRole == 'pasien');

        if (!isFirstSnapshot && isFromOpposite && unread > 0 && lastMsg.isNotEmpty && lastMsg != previousMsg) {
          if (myRole == 'pasien') {
            final docDoctorName = data['doctorName']?.toString() ?? 'Dokter';
            notificationService.showDoctorReplyNotification(
              id: doc.id.hashCode,
              doctorName: docDoctorName,
              message: lastMsg,
            );
          } else {
            final docPatientName = data['patientName']?.toString() ?? 'Pasien';
            notificationService.showPatientMessageNotification(
              id: doc.id.hashCode,
              patientName: docPatientName,
              message: lastMsg,
            );
          }
        }

        lastKnownMessages[doc.id] = lastMsg;
      }

      isFirstSnapshot = false;
    }, onError: (_) {});
  }

  startFirestoreStream();

  // Timer pengecekan durasi sesi 2 menit (120 detik)
  // Menghitung selisih waktu sejak aplikasi terakhir aktif / masuk background
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    final updatedPrefs = await SharedPreferences.getInstance();
    final bgTimeMs = updatedPrefs.getInt('dcare_session_background_entered_at');
    final lastActiveMs = updatedPrefs.getInt('dcare_session_last_active_at');
    final referenceMs = bgTimeMs ?? lastActiveMs;

    if (referenceMs != null) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final diffSeconds = (nowMs - referenceMs) ~/ 1000;
      final maxTimeoutSeconds = SessionConfig.backgroundTimeout.inSeconds; // 120 detik

      if (diffSeconds >= maxTimeoutSeconds) {
        // Sesi 2 menit telah habis -> matikan service latar belakang
        chatSubscription?.cancel();
        timer.cancel();
        service.stopSelf();
        return;
      }
    }
  });

  service.on('updateUser').listen((event) {
    if (event != null) {
      currentUid = event['uid'] as String?;
      currentRole = event['role'] as String?;
      currentName = event['name'] as String?;
      startFirestoreStream();
    }
  });

  service.on('stopService').listen((_) {
    chatSubscription?.cancel();
    service.stopSelf();
  });
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  return true;
}
