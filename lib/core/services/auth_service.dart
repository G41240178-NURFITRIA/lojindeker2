import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/widgets/role_selector.dart';

/// Service untuk menangani alur Autentikasi Firebase dan Profil di Firestore
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Terjemahan kode error Firebase ke bahasa Indonesia yang ramah pengguna
  String _mapFirebaseAuthError(String code, [String defaultMessage = 'Terjadi kesalahan autentikasi.']) {
    switch (code) {
      case 'user-not-found':
        return 'Akun dengan email tersebut tidak ditemukan.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-credential':
        return 'Email atau password salah. Silakan periksa kembali.';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan login atau gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 6 karakter.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan gagal. Silakan coba beberapa saat lagi.';
      case 'operation-not-allowed':
        return 'Metode Email/Password belum diaktifkan di Firebase Console Authentication.';
      case 'network-request-failed':
        return 'Gagal terhubung ke jaringan. Periksa koneksi internet Anda.';
      default:
        return defaultMessage;
    }
  }

  /// Pendaftaran Akun Baru (Firebase Auth + Simpan Profil ke Firestore)
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? username,
    required String fullName,
    required String phoneNumber,
    required String dob,
    UserRole role = UserRole.pasien,
  }) async {
    try {
      // 1. Buat user di Firebase Authentication
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw Exception('Gagal membuat pengguna di Firebase Auth.');
      }

      // Update displayName di Firebase Auth
      await user.updateDisplayName(fullName);

      final accountUsername = (username != null && username.trim().isNotEmpty)
          ? username.trim()
          : fullName.trim();

      // 2. Simpan profil lengkap ke Firestore koleksi 'users'
      final userModel = UserModel(
        uid: user.uid,
        username: accountUsername,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        dob: dob.trim(),
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set({
        ...userModel.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ [AuthService] Pengguna ${user.uid} berhasil terdaftar dan profil tersimpan di Firestore.');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthError(e.code, e.message ?? 'Gagal mendaftar.');
    } catch (e) {
      debugPrint('❌ [AuthService] Error signUp: $e');
      rethrow;
    }
  }

  /// Login Pengguna (Bisa menggunakan Email atau Username Akun / Nomor HP)
  Future<UserModel> login({
    required String identifier,
    required String password,
    required UserRole expectedRole,
  }) async {
    try {
      String emailToUse = identifier.trim();

      // Jika input bukan format email (tidak ada tanda @), cari email yang sesuai di Firestore
      if (!emailToUse.contains('@')) {
        // 1. Prioritaskan pencarian berdasarkan username akun login
        final usernameQuery = await _firestore
            .collection('users')
            .where('username', isEqualTo: identifier.trim())
            .limit(1)
            .get();

        if (usernameQuery.docs.isNotEmpty) {
          emailToUse = usernameQuery.docs.first.data()['email'] ?? '';
        } else {
          // 2. Cari berdasarkan nomor HP
          final phoneQuery = await _firestore
              .collection('users')
              .where('phoneNumber', isEqualTo: identifier.trim())
              .limit(1)
              .get();

          if (phoneQuery.docs.isNotEmpty) {
            emailToUse = phoneQuery.docs.first.data()['email'] ?? '';
          } else {
            // 3. Fallback akun lama: Cek fullName hanya jika akun lama belum memiliki username akun terpisah
            final nameQuery = await _firestore
                .collection('users')
                .where('fullName', isEqualTo: identifier.trim())
                .limit(1)
                .get();

            if (nameQuery.docs.isNotEmpty) {
              final docData = nameQuery.docs.first.data();
              if (docData['username'] == null || docData['username'].toString().isEmpty) {
                emailToUse = docData['email'] ?? '';
                // Simpan username akun ini secara permanen agar ke depannya konsisten
                await _firestore.collection('users').doc(nameQuery.docs.first.id).set({
                  'username': identifier.trim(),
                }, SetOptions(merge: true));
              }
            }
          }
        }

        if (emailToUse.isEmpty || !emailToUse.contains('@')) {
          throw 'Format login harus berupa email yang valid, username akun, atau nomor HP yang terdaftar.';
        }
      }

      // 1. Sign in ke Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw 'Gagal mendapatkan data akun pengguna.';
      }

      // 2. Ambil profil pengguna dari Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;
      if (userDoc.exists && userDoc.data() != null) {
        userModel = UserModel.fromMap(userDoc.data()!, user.uid);
      } else {
        // Jika dokumen belum ada (misal akun lama), buat dokumen default di Firestore
        userModel = UserModel(
          uid: user.uid,
          username: identifier.contains('@') ? identifier.split('@')[0] : identifier,
          fullName: user.displayName ?? (identifier.contains('@') ? identifier.split('@')[0] : identifier),
          email: user.email ?? emailToUse,
          phoneNumber: '',
          dob: '',
          role: expectedRole,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      }

      // 3. Verifikasi apakah peran yang dipilih saat login sesuai dengan akun
      if (userModel.role != expectedRole) {
        await _auth.signOut();
        throw 'Akun ini terdaftar sebagai ${_roleName(userModel.role)}, bukan sebagai ${_roleName(expectedRole)}. Silakan pilih peran yang sesuai.';
      }

      debugPrint('✅ [AuthService] Login berhasil untuk user: ${userModel.fullName} (${userModel.email})');
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthError(e.code, e.message ?? 'Gagal login.');
    } catch (e) {
      debugPrint('❌ [AuthService] Error login: $e');
      rethrow;
    }
  }

  /// Reset Password melalui email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('✅ [AuthService] Email reset password terkirim ke $email');
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e.code, e.message ?? 'Gagal mengirim email reset password.');
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('ℹ️ [AuthService] User berhasil logout.');
  }

  /// Helper teks nama peran
  String _roleName(UserRole role) {
    switch (role) {
      case UserRole.pasien:
        return 'Pasien';
      case UserRole.dokter:
        return 'Dokter';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
