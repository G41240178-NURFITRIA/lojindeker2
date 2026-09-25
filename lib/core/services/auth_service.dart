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

  /// Nama koleksi Firestore berdasarkan role
  String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.pasien:
        return 'users';
      case UserRole.dokter:
        return 'doctors';
      case UserRole.admin:
        return 'admins';
    }
  }

  /// Pendaftaran Akun Baru (Firebase Auth + Simpan Profil ke koleksi Firestore sesuai role)
  /// - Pasien  → koleksi 'users'
  /// - Dokter  → koleksi 'doctors'
  /// - Admin   → koleksi 'admins'
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

      // 2. Tentukan koleksi Firestore berdasarkan role
      final collection = _collectionForRole(role);

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

      // 3. Simpan profil lengkap ke koleksi yang sesuai role
      await _firestore.collection(collection).doc(user.uid).set({
        ...userModel.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
        '✅ [AuthService] Pengguna ${user.uid} berhasil terdaftar '
        'sebagai ${role.name} di koleksi "$collection".',
      );
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthError(e.code, e.message ?? 'Gagal mendaftar.');
    } catch (e) {
      debugPrint('❌ [AuthService] Error signUp: $e');
      rethrow;
    }
  }

  /// Cari email dari identifier (username/HP/nama) di satu koleksi Firestore.
  /// Mengembalikan email (String) atau null jika tidak ditemukan.
  Future<String?> _findEmailInCollection(
    String collection,
    String identifier,
  ) async {
    // Cari by username
    var q = await _firestore
        .collection(collection)
        .where('username', isEqualTo: identifier)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.data()['email'] as String?;

    // Cari by phoneNumber
    q = await _firestore
        .collection(collection)
        .where('phoneNumber', isEqualTo: identifier)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) return q.docs.first.data()['email'] as String?;

    // Fallback: cari by fullName (akun lama tanpa username)
    q = await _firestore
        .collection(collection)
        .where('fullName', isEqualTo: identifier)
        .limit(1)
        .get();
    if (q.docs.isNotEmpty) {
      final doc = q.docs.first;
      final data = doc.data();
      if (data['username'] == null || data['username'].toString().isEmpty) {
        // Simpan username agar konsisten ke depannya
        await _firestore.collection(collection).doc(doc.id).set(
          {'username': identifier},
          SetOptions(merge: true),
        );
        return data['email'] as String?;
      }
    }
    return null;
  }

  /// Login Pengguna — role ditentukan otomatis dari database, tidak perlu dipilih saat login.
  /// Mendukung identifier berupa: email, nomor HP, username, atau nama lengkap.
  /// Mencari di ketiga koleksi: 'users' (pasien), 'doctors', 'admins'.
  Future<UserModel> loginAutoRole({
    required String identifier,
    required String password,
  }) async {
    try {
      String emailToUse = identifier.trim();

      // Jika input bukan format email, cari di semua koleksi role
      if (!emailToUse.contains('@')) {
        const collections = ['users', 'doctors', 'admins'];
        for (final col in collections) {
          final found = await _findEmailInCollection(col, identifier.trim());
          if (found != null && found.contains('@')) {
            emailToUse = found;
            break;
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
      if (user == null) throw 'Gagal mendapatkan data akun pengguna.';

      // 2. Ambil profil + role dari Firestore — cek ketiga koleksi
      UserModel? userModel;
      for (final col in ['users', 'doctors', 'admins']) {
        final doc = await _firestore.collection(col).doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          userModel = UserModel.fromMap(doc.data()!, user.uid);
          debugPrint('ℹ️ [AuthService] Profil ditemukan di koleksi "$col".');
          break;
        }
      }

      // Jika tidak ditemukan di koleksi manapun — buat dokumen pasien baru
      userModel ??= UserModel(
        uid: user.uid,
        username: identifier.contains('@') ? identifier.split('@')[0] : identifier,
        fullName: user.displayName ??
            (identifier.contains('@') ? identifier.split('@')[0] : identifier),
        email: user.email ?? emailToUse,
        phoneNumber: '',
        dob: '',
        role: UserRole.pasien,
        createdAt: DateTime.now(),
      );
      // Simpan ke 'users' (koleksi pasien) jika belum ada
      await _firestore.collection('users').doc(user.uid).set(
        {...userModel.toMap(), 'createdAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );

      debugPrint(
        '✅ [AuthService] Login berhasil: ${userModel.fullName} '
        '(${userModel.email}) — role: ${userModel.role.name}',
      );
      return userModel;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthError(e.code, e.message ?? 'Gagal login.');
    } catch (e) {
      debugPrint('❌ [AuthService] Error loginAutoRole: $e');
      rethrow;
    }
  }

  /// Login legacy (masih kompatibel, tidak ada validasi role)
  Future<UserModel> login({
    required String identifier,
    required String password,
    UserRole expectedRole = UserRole.pasien,
  }) => loginAutoRole(identifier: identifier, password: password);

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

}
