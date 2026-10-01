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
      _db.collection('loginLookup').doc(user.username.toLowerCase()),
      lookupData,
    );

    // 3. loginLookup/{email}
    batch.set(
      _db.collection('loginLookup').doc(user.email.toLowerCase()),
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
      try {
        await firebaseUser.delete();
      } catch (deleteErr) {
        debugPrint('❌ [UserRepository] Gagal menghapus Auth user saat rollback: $deleteErr');
      }
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
