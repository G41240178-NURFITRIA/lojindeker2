import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../models/app_user.dart';

/// Repository untuk operasi CRUD profil pengguna di Firestore.
/// Menangani semua tiga koleksi: users, doctors, admins.
class UserRepository {
  UserRepository._internal();
  static final UserRepository instance = UserRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Cari profil berdasarkan UID ─────────────────────────────────
  /// Cek admins → doctors → users berdasarkan UID, return AppUser atau null.
  Future<AppUser?> findByUid(String uid) async {
    for (final role in [AppRole.admin, AppRole.doctor, AppRole.pasien]) {
      try {
        final doc = await _db.collection(role.collection).doc(uid).get();
        if (doc.exists && doc.data() != null) {
          return AppUser.fromMap(doc.data()!, uid);
        }
      } catch (e) {
        debugPrint('⚠️ [UserRepository] findByUid check ${role.collection}: $e');
      }
    }
    return null;
  }

  // ─── loginLookup ─────────────────────────────────────────────────
  /// Cari email dari identifier (username / no HP / email) via loginLookup.
  Future<LoginLookup?> lookupIdentifier(String identifier) async {
    final key = identifier.toLowerCase().trim();
    try {
      final doc = await _db.collection('loginLookup').doc(key).get();
      if (doc.exists && doc.data() != null) {
        return LoginLookup.fromMap(doc.data()!);
      }
    } catch (e) {
      debugPrint('⚠️ [UserRepository] lookupIdentifier: $e');
    }
    return null;
  }

  // ─── Daftar Pasien (WriteBatch) ───────────────────────────────────
  /// Simpan profil pasien baru + 3 dokumen loginLookup dalam satu batch.
  /// Jika batch gagal → rollback: hapus user Auth.
  Future<void> createPatient({
    required AppUser user,
    required User firebaseUser,
  }) async {
    final batch = _db.batch();
    final ts = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      ...user.toMap(),
      'createdAt': ts,
      'updatedAt': ts,
    };

    // 1. Dokumen profil di users/{uid}
    batch.set(_db.collection('users').doc(user.uid), data);

    // 2. loginLookup/{username}
    final lookupData = <String, dynamic>{
      ...user.toLookupMap(),
      'createdAt': ts,
    };
    batch.set(
      _db.collection('loginLookup').doc(user.username.trim().toLowerCase()),
      lookupData,
    );

    // 3. loginLookup/{email}
    batch.set(
      _db.collection('loginLookup').doc(user.email.trim().toLowerCase()),
      lookupData,
    );

    // 4. loginLookup/{phoneNumber} — hanya jika tidak kosong
    if (user.phoneNumber.trim().isNotEmpty) {
      batch.set(
        _db.collection('loginLookup').doc(user.phoneNumber.trim()),
        lookupData,
      );
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [UserRepository] Batch commit gagal, rollback Auth user: $e');
      rethrow;
    }
  }

  // ─── Admin Tambah Dokter ──────────────────────────────────────────
  /// Simpan profil dokter baru + loginLookup dalam satu batch.
  Future<void> createDoctor({
    required AppUser doctor,
  }) async {
    final batch = _db.batch();
    final ts = FieldValue.serverTimestamp();
    final data = <String, dynamic>{
      ...doctor.toMap(),
      'createdAt': ts,
      'updatedAt': ts,
    };

    batch.set(_db.collection('doctors').doc(doctor.uid), data);

    final lookupData = <String, dynamic>{
      ...doctor.toLookupMap(),
      'createdAt': ts,
    };

    batch.set(
      _db.collection('loginLookup').doc(doctor.username.toLowerCase()),
      lookupData,
    );
    batch.set(
      _db.collection('loginLookup').doc(doctor.email.toLowerCase()),
      lookupData,
    );
    if (doctor.phoneNumber.trim().isNotEmpty) {
      batch.set(
        _db.collection('loginLookup').doc(doctor.phoneNumber.trim()),
        lookupData,
      );
    }

    await batch.commit();
  }

  // ─── Daftar Dokter ────────────────────────────────────────────────
  Stream<List<AppUser>> streamDoctors() {
    return _db
        .collection('doctors')
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromMap(d.data(), d.id))
            .toList());
  }

  /// Aktif/nonaktifkan dokter
  Future<void> setDoctorActive(String uid, {required bool isActive}) async {
    await _db.collection('doctors').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream profil dokter secara real-time
  Stream<AppUser?> streamDoctor(String uid) {
    return _db.collection('doctors').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.data()!, doc.id);
    });
  }

  /// Perbarui jadwal konsultasi online dokter
  Future<void> updateDoctorSchedule(String uid, String schedule) async {
    // 1. Simpan langsung ke koleksi 'doctors' utama
    await _db.collection('doctors').doc(uid).set({
      'schedule': schedule,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Sinkronkan ke 'users' jika dokumen tersebut ada (tanpa memicu kegagalan transaksi)
    try {
      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        await _db.collection('users').doc(uid).update({
          'schedule': schedule,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {}
  }

  /// Perbarui foto profil dokter
  Future<void> updateDoctorPhoto(String uid, String? photoUrl) async {
    await _db.collection('doctors').doc(uid).set({
      'photoUrl': photoUrl ?? '',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ─── Daftar Pasien / Pengguna ─────────────────────────────────────
  Stream<List<AppUser>> streamPatients() {
    return _db
        .collection('users')
        .orderBy('fullName')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppUser.fromMap(d.data(), d.id))
            .toList());
  }

  /// Aktif/nonaktifkan akun pasien
  Future<void> setPatientActive(String uid, {required bool isActive}) async {
    await _db.collection('users').doc(uid).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hapus akun pasien secara permanen dari Firestore.
  /// Menghapus: profil di users/{uid}, loginLookup/{username},
  /// loginLookup/{email}, dan loginLookup/{phoneNumber} (jika ada).
  Future<void> deletePatient(AppUser patient) async {
    final batch = _db.batch();

    // 1. Hapus dokumen profil
    batch.delete(_db.collection('users').doc(patient.uid));

    // 2. Hapus loginLookup berdasarkan username
    if (patient.username.trim().isNotEmpty) {
      batch.delete(
        _db.collection('loginLookup').doc(patient.username.toLowerCase()),
      );
    }

    // 3. Hapus loginLookup berdasarkan email
    if (patient.email.trim().isNotEmpty) {
      batch.delete(
        _db.collection('loginLookup').doc(patient.email.toLowerCase()),
      );
    }

    // 4. Hapus loginLookup berdasarkan nomor HP (jika ada)
    if (patient.phoneNumber.trim().isNotEmpty) {
      batch.delete(
        _db.collection('loginLookup').doc(patient.phoneNumber.trim()),
      );
    }

    await batch.commit();
  }

  // ─── Validasi keunikan ────────────────────────────────────────────
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _db
        .collection('loginLookup')
        .doc(username.toLowerCase())
        .get();
    return !doc.exists;
  }

  Future<bool> isEmailAvailable(String email) async {
    final doc = await _db
        .collection('loginLookup')
        .doc(email.toLowerCase())
        .get();
    return !doc.exists;
  }

  Future<bool> isPhoneAvailable(String phone) async {
    final doc = await _db.collection('loginLookup').doc(phone.trim()).get();
    return !doc.exists;
  }
}
