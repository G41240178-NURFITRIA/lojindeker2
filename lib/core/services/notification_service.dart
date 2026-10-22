import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // v22: initialize() — first arg adalah named `settings:`
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {},
      );

      if (Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
        await androidImpl?.requestExactAlarmsPermission();

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'medication_alarm_channel',
          'Alarm Minum Obat',
          description: 'Alarm harian pengingat jadwal minum obat diabetes',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImpl?.createNotificationChannel(channel);

        const AndroidNotificationChannel doctorChatChannel =
            AndroidNotificationChannel(
          'doctor_chat_channel',
          'Pesan Konsultasi Dokter',
          description: 'Notifikasi balasan pesan konsultasi dari dokter',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImpl?.createNotificationChannel(doctorChatChannel);
      }

      _isInitialized = true;
    } catch (e) {
      // Prevent app crash jika notifikasi gagal init
    }
  }

  // =====================================================================
  // ALARM TERJADWAL HARIAN — muncul TEPAT pada jam yang diset pengguna
  // =====================================================================

  Future<void> scheduleReminderNotification({
    required int id,
    required String medicineName,
    required String dosage,
    required String timeStr,
  }) async {
    await init();

    try {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'medication_alarm_channel',
        'Alarm Minum Obat',
        channelDescription: 'Alarm harian pengingat jadwal minum obat diabetes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Coba jadwalkan exact alarm terlebih dahulu
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: '⏰ Waktunya Minum Obat!',
          body: 'Saatnya minum $medicineName ($dosage) — Jadwal $timeStr',
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {
        // Fallback jika exact alarm dibatasi oleh izin/baterai di Android: gunakan inexact alarm
        await _plugin.zonedSchedule(
          id: id,
          title: '⏰ Waktunya Minum Obat!',
          body: 'Saatnya minum $medicineName ($dosage) — Jadwal $timeStr',
          scheduledDate: scheduledDate,
          notificationDetails: platformDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    } catch (_) {
      // Abaikan jika penjadwalan gagal tanpa menembakkan notifikasi prematur
    }
  }

  Future<void> cancelReminderNotification(int id) async {
    await init();
    try {
      // v22: cancel() — named parameter `id:`
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAllReminderNotifications() async {
    await init();
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // =====================================================================
  // NOTIFIKASI INSTAN
  // =====================================================================

  Future<void> showMedicationNotification({
    required int id,
    required String medicineName,
    required String dosage,
    required String time,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_reminder_channel',
      'Pengingat Minum Obat',
      channelDescription: 'Notifikasi pengingat jadwal minum obat diabetes',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // v22: show() — semua named parameters
    await _plugin.show(
      id: id,
      title: '⏰ Waktunya Minum Obat!',
      body: 'Saatnya minum $medicineName ($dosage) - Jadwal $time',
      notificationDetails: platformDetails,
    );
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dcare_general_channel',
      'Notifikasi D-Care',
      channelDescription: 'Saluran notifikasi umum D-Care',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  /// Menampilkan notifikasi sistem saat pasien menerima balasan chat dari dokter
  Future<void> showDoctorReplyNotification({
    required int id,
    required String doctorName,
    required String message,
    String? payload,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'doctor_chat_channel',
      'Pesan Konsultasi Dokter',
      channelDescription: 'Notifikasi balasan pesan konsultasi dari dokter',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      category: AndroidNotificationCategory.message,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      id: id,
      title: '💬 Balasan dari $doctorName',
      body: message,
      notificationDetails: platformDetails,
      payload: payload,
    );
  }
}
