import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tipe/kategori aktivitas yang dicatat di log admin
enum AdminActivityType {
  pasienBaru,       // Pasien baru mendaftar
  dokterBaru,       // Dokter baru ditambahkan admin
  cekRisiko,        // Pasien melakukan cek risiko diabetes
  konsultasi,       // Pasien memulai/menyelesaikan konsultasi
  statusPengguna,   // Admin aktifkan/nonaktifkan akun pasien
  statusDokter,     // Admin aktifkan/nonaktifkan akun dokter
  resetSandi,       // Admin reset sandi pasien
  login,            // User login ke sistem
  logout,           // User logout dari sistem
  sistemNormal,     // Status sistem normal (default)
}

/// Model untuk satu entri log aktivitas admin
class AdminActivityLog {
  final String id;
  final AdminActivityType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  AdminActivityLog({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.metadata = const {},
  });

  String get iconKey {
    switch (type) {
      case AdminActivityType.pasienBaru:
        return 'person_add';
      case AdminActivityType.dokterBaru:
        return 'doctor';
      case AdminActivityType.cekRisiko:
        return 'health_safety';
      case AdminActivityType.konsultasi:
        return 'chat';
      case AdminActivityType.statusPengguna:
      case AdminActivityType.statusDokter:
        return 'toggle';
      case AdminActivityType.resetSandi:
        return 'lock_reset';
      case AdminActivityType.login:
        return 'login';
      case AdminActivityType.logout:
        return 'logout';
      case AdminActivityType.sistemNormal:
        return 'check';
    }
  }

  /// Waktu relatif dalam Bahasa Indonesia
  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return _formatDate(timestamp);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  factory AdminActivityLog.fromMap(Map<String, dynamic> map, String docId) {
    final ts = map['timestamp'];
    DateTime parsedTime;
    if (ts is Timestamp) {
      parsedTime = ts.toDate();
    } else {
      parsedTime = DateTime.now();
    }

    AdminActivityType parsedType = AdminActivityType.sistemNormal;
    final typeStr = map['type']?.toString() ?? '';
    for (final t in AdminActivityType.values) {
      if (t.name == typeStr) {
        parsedType = t;
        break;
      }
    }

    return AdminActivityLog(
      id: docId,
      type: parsedType,
      title: map['title']?.toString() ?? 'Aktivitas Sistem',
      subtitle: map['subtitle']?.toString() ?? '',
      timestamp: parsedTime,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// Service untuk mencatat dan membaca log aktivitas admin dari Firestore.
/// Koleksi Firestore: `admin_activity_log`
class AdminActivityService {
  AdminActivityService._internal();
  static final AdminActivityService instance = AdminActivityService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'admin_activity_log';

  /// Stream real-time log aktivitas terbaru (maks 50 entri terbaru)
  Stream<List<AdminActivityLog>> streamActivities({int limit = 50}) {
    return _db
        .collection(_collection)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AdminActivityLog.fromMap(d.data(), d.id))
            .toList());
  }

  /// Catat satu aktivitas baru ke Firestore
  Future<void> logActivity({
    required AdminActivityType type,
    required String title,
    required String subtitle,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final id = 'ACT-${DateTime.now().millisecondsSinceEpoch}';
      final log = AdminActivityLog(
        id: id,
        type: type,
        title: title,
        subtitle: subtitle,
        timestamp: DateTime.now(),
        metadata: metadata,
      );
      await _db.collection(_collection).doc(id).set(log.toMap());
      debugPrint('✅ [AdminActivityService] Aktivitas dicatat: $title');
    } catch (e) {
      debugPrint('❌ [AdminActivityService] Gagal catat aktivitas: $e');
    }
  }

  // ── Shortcut untuk tiap jenis aktivitas ───────────────────────────

  /// Pasien baru mendaftar
  Future<void> logPasienBaru({
    required String fullName,
    required String email,
    String username = '',
  }) =>
      logActivity(
        type: AdminActivityType.pasienBaru,
        title: 'Pasien Baru Terdaftar',
        subtitle: '$fullName • $email',
        metadata: {'fullName': fullName, 'email': email, 'username': username},
      );

  /// Dokter baru ditambahkan oleh admin
  Future<void> logDokterBaru({
    required String fullName,
    required String specialization,
    String email = '',
  }) =>
      logActivity(
        type: AdminActivityType.dokterBaru,
        title: 'Dokter Baru Ditambahkan',
        subtitle: '$fullName • $specialization',
        metadata: {'fullName': fullName, 'specialization': specialization, 'email': email},
      );

  /// Pasien melakukan cek risiko diabetes
  Future<void> logCekRisiko({
    required String patientName,
    required String status,
    required int score,
  }) =>
      logActivity(
        type: AdminActivityType.cekRisiko,
        title: 'Cek Risiko Selesai',
        subtitle: '${patientName.isNotEmpty ? patientName : "Pasien"} • Risiko $status ($score%)',
        metadata: {'patientName': patientName, 'status': status, 'score': score},
      );

  /// Pasien memulai konsultasi dengan dokter
  Future<void> logKonsultasi({
    required String patientName,
    required String doctorName,
  }) =>
      logActivity(
        type: AdminActivityType.konsultasi,
        title: 'Konsultasi Dimulai',
        subtitle: '$patientName berkaitan dengan $doctorName',
        metadata: {'patientName': patientName, 'doctorName': doctorName},
      );

  /// Admin mengubah status aktif pengguna (pasien)
  Future<void> logStatusPengguna({
    required String fullName,
    required bool isActive,
  }) =>
      logActivity(
        type: AdminActivityType.statusPengguna,
        title: isActive ? 'Pengguna Diaktifkan' : 'Pengguna Dinonaktifkan',
        subtitle: '$fullName • Status diperbarui oleh admin',
        metadata: {'fullName': fullName, 'isActive': isActive},
      );

  /// Admin mengubah status aktif dokter
  Future<void> logStatusDokter({
    required String fullName,
    required bool isActive,
  }) =>
      logActivity(
        type: AdminActivityType.statusDokter,
        title: isActive ? 'Dokter Diaktifkan' : 'Dokter Dinonaktifkan',
        subtitle: '$fullName • Status diperbarui oleh admin',
        metadata: {'fullName': fullName, 'isActive': isActive},
      );

  /// Admin reset sandi pasien
  Future<void> logResetSandi({
    required String email,
    String fullName = '',
  }) =>
      logActivity(
        type: AdminActivityType.resetSandi,
        title: 'Reset Sandi Dikirim',
        subtitle: '${fullName.isNotEmpty ? "$fullName • " : ""}$email',
        metadata: {'email': email, 'fullName': fullName},
      );

  /// User (pasien/dokter) login ke sistem
  Future<void> logLogin({
    required String fullName,
    required String role,
  }) =>
      logActivity(
        type: AdminActivityType.login,
        title: 'Login ke Sistem',
        subtitle: '$fullName masuk sebagai $role',
        metadata: {'fullName': fullName, 'role': role},
      );

  /// User logout dari sistem
  Future<void> logLogout({
    required String fullName,
    required String role,
  }) =>
      logActivity(
        type: AdminActivityType.logout,
        title: 'Logout dari Sistem',
        subtitle: '$fullName ($role) keluar',
        metadata: {'fullName': fullName, 'role': role},
      );
}
