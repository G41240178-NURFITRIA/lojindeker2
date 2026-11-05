import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Tipe/kategori aktivitas audit trail yang dicatat di log admin
enum AdminActivityType {
  pasienBaru,       // Pasien baru mendaftar
  dokterBaru,       // Dokter baru ditambahkan admin
  adminBaru,        // Admin baru ditambahkan
  cekRisiko,        // Pasien melakukan cek risiko diabetes
  konsultasi,       // Pasien memulai/menyelesaikan konsultasi
  statusPengguna,   // Admin aktifkan/nonaktifkan akun pasien
  statusDokter,     // Admin aktifkan/nonaktifkan akun dokter
  resetSandi,       // Admin/User meminta link reset sandi
  ubahSandi,        // User/Dokter/Admin berhasil mengubah kata sandi
  ubahProfil,       // Perubahan data akun/profil pengguna
  hapusAkun,        // Akun dihapus dari sistem
  artikelBaru,      // Artikel edukasi baru diterbitkan
  ubahArtikel,      // Artikel edukasi diperbarui
  hapusArtikel,     // Artikel edukasi dihapus
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
      case AdminActivityType.adminBaru:
        return 'admin_add';
      case AdminActivityType.cekRisiko:
        return 'health_safety';
      case AdminActivityType.konsultasi:
        return 'chat';
      case AdminActivityType.statusPengguna:
      case AdminActivityType.statusDokter:
        return 'toggle';
      case AdminActivityType.resetSandi:
        return 'lock_reset';
      case AdminActivityType.ubahSandi:
        return 'password_changed';
      case AdminActivityType.ubahProfil:
        return 'edit_profile';
      case AdminActivityType.hapusAkun:
        return 'delete_account';
      case AdminActivityType.artikelBaru:
      case AdminActivityType.ubahArtikel:
        return 'article';
      case AdminActivityType.hapusArtikel:
        return 'article_delete';
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

/// Service untuk mencatat dan membaca log aktivitas audit trail admin dari Firestore.
/// Koleksi Firestore: `admin_activity_log`
class AdminActivityService {
  AdminActivityService._internal();
  static final AdminActivityService instance = AdminActivityService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'admin_activity_log';

  /// Stream real-time log aktivitas terbaru (maks 100 entri terbaru)
  Stream<List<AdminActivityLog>> streamActivities({int limit = 100}) {
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

  /// Admin baru ditambahkan oleh admin
  Future<void> logAdminBaru({
    required String fullName,
    required String username,
    String email = '',
  }) =>
      logActivity(
        type: AdminActivityType.adminBaru,
        title: 'Admin Baru Ditambahkan',
        subtitle: '$fullName • @$username',
        metadata: {'fullName': fullName, 'username': username, 'email': email},
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

  /// Perubahan kata sandi pengguna (Password Changed)
  Future<void> logUbahSandi({
    required String email,
    String fullName = '',
    String role = 'pengguna',
  }) =>
      logActivity(
        type: AdminActivityType.ubahSandi,
        title: 'Kata Sandi Diperbarui',
        subtitle: '${fullName.isNotEmpty ? "$fullName ($role)" : email} telah memperbarui kata sandi',
        metadata: {'email': email, 'fullName': fullName, 'role': role},
      );

  /// Permintaan reset kata sandi (Reset Password Link)
  Future<void> logResetSandi({
    required String email,
    String fullName = '',
    String role = 'pasien',
  }) =>
      logActivity(
        type: AdminActivityType.resetSandi,
        title: 'Reset Sandi Dikirim',
        subtitle: '${fullName.isNotEmpty ? "$fullName • " : ""}$email ($role)',
        metadata: {'email': email, 'fullName': fullName, 'role': role},
      );

  /// Perubahan data akun / profil pengguna (Username, Profil, No HP, dll)
  Future<void> logUbahProfil({
    required String fullName,
    required String detailPerubahan,
    String email = '',
    String role = 'pengguna',
  }) =>
      logActivity(
        type: AdminActivityType.ubahProfil,
        title: 'Profil Akun Diperbarui',
        subtitle: '$fullName ($role) • $detailPerubahan',
        metadata: {
          'fullName': fullName,
          'email': email,
          'role': role,
          'detail': detailPerubahan,
        },
      );

  /// Admin mengubah status aktif pengguna (pasien)
  Future<void> logStatusPengguna({
    required String fullName,
    required bool isActive,
    String email = '',
  }) =>
      logActivity(
        type: AdminActivityType.statusPengguna,
        title: isActive ? 'Akun Pengguna Diaktifkan' : 'Akun Pengguna Dinonaktifkan',
        subtitle: '$fullName • ${isActive ? "Akses login dibuka kembali" : "Akses login ditangguhkan"}',
        metadata: {'fullName': fullName, 'isActive': isActive, 'email': email},
      );

  /// Admin mengubah status aktif dokter
  Future<void> logStatusDokter({
    required String fullName,
    required bool isActive,
    String email = '',
  }) =>
      logActivity(
        type: AdminActivityType.statusDokter,
        title: isActive ? 'Akun Dokter Diaktifkan' : 'Akun Dokter Dinonaktifkan',
        subtitle: '$fullName • ${isActive ? "Dokter siap menerima konsultasi" : "Status dokter dinonaktifkan"}',
        metadata: {'fullName': fullName, 'isActive': isActive, 'email': email},
      );

  /// Akun pengguna / dokter / admin dihapus permanen
  Future<void> logHapusAkun({
    required String fullName,
    required String role,
    String email = '',
  }) =>
      logActivity(
        type: AdminActivityType.hapusAkun,
        title: 'Akun Dihapus',
        subtitle: '$fullName ($role) • ${email.isNotEmpty ? email : "Dihapus oleh admin"}',
        metadata: {'fullName': fullName, 'role': role, 'email': email},
      );

  /// Artikel edukasi baru dipublikasikan
  Future<void> logArtikelBaru({
    required String title,
    required String reviewer,
  }) =>
      logActivity(
        type: AdminActivityType.artikelBaru,
        title: 'Artikel Edukasi Diterbitkan',
        subtitle: '"$title" • Direview oleh $reviewer',
        metadata: {'title': title, 'reviewer': reviewer},
      );

  /// Artikel edukasi diperbarui
  Future<void> logUbahArtikel({
    required String title,
    required String reviewer,
  }) =>
      logActivity(
        type: AdminActivityType.ubahArtikel,
        title: 'Artikel Edukasi Diperbarui',
        subtitle: '"$title" • Direview oleh $reviewer',
        metadata: {'title': title, 'reviewer': reviewer},
      );

  /// Artikel edukasi dihapus
  Future<void> logHapusArtikel({
    required String title,
  }) =>
      logActivity(
        type: AdminActivityType.hapusArtikel,
        title: 'Artikel Edukasi Dihapus',
        subtitle: 'Materi "$title" telah dihapus dari sistem',
        metadata: {'title': title},
      );

  /// User (pasien/dokter/admin) login ke sistem
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
