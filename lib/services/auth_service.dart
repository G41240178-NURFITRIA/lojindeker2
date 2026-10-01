import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../core/services/session_service.dart';
import 'user_repository.dart';

/// Service autentikasi utama aplikasi D-Care.
/// Menangani login (via loginLookup), signup pasien, forgot password, dan logout.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Terjemahan error Firebase → Bahasa Indonesia ─────────────────
  String _mapError(String code, [String fallback = 'Terjadi kesalahan autentikasi.']) {
    switch (code) {
      case 'user-not-found':
        return 'Akun tidak ditemukan. Periksa kembali email atau username Anda.';
      case 'wrong-password':
        return 'Password yang Anda masukkan salah.';
      case 'invalid-credential':
        return 'Email atau password tidak valid. Silakan periksa kembali.';
      case 'invalid-email':
        return 'Format alamat email tidak valid.';
      case 'email-already-in-use':
        return 'Email ini sudah terdaftar. Silakan gunakan email lain.';
      case 'weak-password':
        return 'Password terlalu lemah. Minimal 8 karakter dengan huruf dan angka.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Silakan coba beberapa saat lagi.';
      case 'network-request-failed':
        return 'Gagal terhubung ke jaringan. Periksa koneksi internet Anda.';
      case 'operation-not-allowed':
        return 'Metode Email/Password belum diaktifkan di Firebase Console.';
      default:
        return fallback;
    }
  }

  // ─── Login ────────────────────────────────────────────────────────
  /// Login dengan identifier (email / username / nomor HP) + password.
  /// - Jika identifier mengandung "@" → langsung pakai sebagai email.
  /// - Jika tidak → cari di loginLookup untuk mendapat email.
  /// Return [AppUser] yang sudah memuat role.
  Future<AppUser> login({
    required String identifier,
    required String password,
  }) async {
    try {
      String emailToUse = identifier.trim();

      // Jika bukan format email, cari di loginLookup
      if (!emailToUse.contains('@')) {
        final lookup = await UserRepository.instance
            .lookupIdentifier(emailToUse);
        if (lookup == null || lookup.email.isEmpty) {
          throw Exception(
            'Akun dengan username / nomor HP tersebut tidak ditemukan.',
          );
        }
        emailToUse = lookup.email;
      }

      // Sign in Firebase Auth
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Gagal mendapatkan data akun.');

      // Cari profil di Firestore
      final appUser = await UserRepository.instance.findByUid(uid);

      if (appUser == null) {
        // UID tidak ada di koleksi manapun → logout + error
        await _auth.signOut();
        throw Exception(
          'Akun tidak ditemukan dalam database. Hubungi administrator.',
        );
      }

      // Dokter tidak aktif → tolak
      if (appUser.role == AppRole.doctor && !appUser.isActive) {
        await _auth.signOut();
        throw Exception(
          'Akun dokter ini telah dinonaktifkan. Hubungi administrator.',
        );
      }

      debugPrint(
        '✅ [AuthService] Login berhasil: ${appUser.fullName} (${appUser.role.firestoreValue})',
      );

      // Reset waktu aktif dan mulai tracking sesi otomatis
      await SessionService.instance.saveLastActive();
      await SessionService.instance.startSession(isNewLogin: true);

      return appUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] FirebaseAuthException: ${e.code}');
      throw Exception(_mapError(e.code, e.message ?? 'Gagal login.'));
    }
  }

  // ─── Legacy wrapper compat dengan kode lama ───────────────────────
  // Masih dipakai oleh login_screen.dart lama
  Future<AppUser> loginAutoRole({
    required String identifier,
    required String password,
  }) => login(identifier: identifier, password: password);

  // ─── Daftar Pasien ────────────────────────────────────────────────
  /// Membuat akun pasien baru.
  /// 1. Validasi input
  /// 2. createUserWithEmailAndPassword
  /// 3. WriteBatch: users/{uid} + 3 dokumen loginLookup
  /// 4. Jika Firestore gagal → hapus Auth user (rollback)
  Future<AppUser> signUpPatient({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String dob,
  }) async {
    // ── Validasi ──────────────────────────────────────────────────
    final usernameClean = username.trim().toLowerCase();
    final emailClean = email.trim().toLowerCase();
    final phoneClean = phoneNumber.trim();
    final fullNameClean = fullName.trim();
    final dobClean = dob.trim();

    if (usernameClean.isEmpty ||
        fullNameClean.isEmpty ||
        emailClean.isEmpty ||
        password.isEmpty ||
        phoneClean.isEmpty ||
        dobClean.isEmpty) {
      throw Exception('Semua field wajib diisi.');
    }

    // Username: 4-20 karakter, hanya huruf/angka/_
    final usernameRegex = RegExp(r'^[a-z0-9_]{4,20}$');
    if (!usernameRegex.hasMatch(usernameClean)) {
      throw Exception(
        'Username harus 4–20 karakter dan hanya boleh mengandung huruf, angka, atau garis bawah.',
      );
    }

    // Email valid
    final emailRegex = RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(emailClean)) {
      throw Exception('Format email tidak valid.');
    }

    // HP: dimulai 08, 10-14 digit
    final phoneRegex = RegExp(r'^08\d{8,12}$');
    if (!phoneRegex.hasMatch(phoneClean)) {
      throw Exception(
        'Nomor HP harus dimulai dengan 08 dan terdiri dari 10–14 digit.',
      );
    }

    // Password min 8, huruf + angka
    if (password.length < 8 ||
        !password.contains(RegExp(r'[a-zA-Z]')) ||
        !password.contains(RegExp(r'[0-9]'))) {
      throw Exception(
        'Password minimal 8 karakter dan harus mengandung huruf serta angka.',
      );
    }

    // Tanggal lahir tidak di masa depan
    final dobDate = DateTime.tryParse(dobClean);
    if (dobDate == null) {
      throw Exception('Format tanggal lahir tidak valid.');
    }
    if (dobDate.isAfter(DateTime.now())) {
      throw Exception('Tanggal lahir tidak boleh di masa depan.');
    }

    // ── Cek keunikan ──────────────────────────────────────────────
    final repo = UserRepository.instance;

    if (!await repo.isUsernameAvailable(usernameClean)) {
      throw Exception('Username "$usernameClean" sudah digunakan.');
    }
    if (!await repo.isEmailAvailable(emailClean)) {
      throw Exception('Email "$emailClean" sudah terdaftar.');
    }
    if (!await repo.isPhoneAvailable(phoneClean)) {
      throw Exception('Nomor HP "$phoneClean" sudah terdaftar.');
    }

    // ── Buat akun Firebase Auth ───────────────────────────────────
    late final FirebaseAuth firebaseAuth;
    try {
      firebaseAuth = _auth;
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: emailClean,
        password: password,
      );

      final firebaseUser = credential.user!;
      await firebaseUser.updateDisplayName(fullNameClean);

      final appUser = AppUser(
        uid: firebaseUser.uid,
        fullName: fullNameClean,
        username: usernameClean,
        email: emailClean,
        phoneNumber: phoneClean,
        dob: dobClean,
        role: AppRole.pasien,
      );

      // ── WriteBatch ke Firestore ───────────────────────────────
      await repo.createPatient(
        user: appUser,
        firebaseUser: firebaseUser,
      );

      debugPrint(
        '✅ [AuthService] Pasien terdaftar: ${appUser.uid}',
      );

      // Mulai tracking sesi otomatis untuk pasien baru
      await SessionService.instance.saveLastActive();
      await SessionService.instance.startSession(isNewLogin: true);

      return appUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthService] signUpPatient Firebase: ${e.code}');
      throw Exception(_mapError(e.code, e.message ?? 'Gagal mendaftar.'));
    }
  }

  // ─── Legacy compat untuk sign_up_screen.dart lama ─────────────────
  Future<AppUser> signUp({
    required String email,
    required String password,
    String? username,
    required String fullName,
    required String phoneNumber,
    required String dob,
    dynamic role,
  }) async {
    return signUpPatient(
      username: username ?? fullName,
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      dob: dob,
    );
  }

  // ─── Admin Tambah Dokter ──────────────────────────────────────────
  /// Membuat akun dokter via Firebase App sekunder agar admin tidak ter-logout.
  Future<AppUser> createDoctorAsAdmin({
    required String username,
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String dob,
    required String specialization,
  }) async {
    final usernameClean = username.trim().toLowerCase();
    final emailClean = email.trim().toLowerCase();
    final phoneClean = phoneNumber.trim();

    // Validasi keunikan
    final repo = UserRepository.instance;
    if (!await repo.isUsernameAvailable(usernameClean)) {
      throw Exception('Username "$usernameClean" sudah digunakan.');
    }
    if (!await repo.isEmailAvailable(emailClean)) {
      throw Exception('Email "$emailClean" sudah terdaftar.');
    }
    if (phoneClean.isNotEmpty && !await repo.isPhoneAvailable(phoneClean)) {
      throw Exception('Nomor HP "$phoneClean" sudah terdaftar.');
    }

    // Buat Firebase App sekunder agar admin tidak ter-logout
    FirebaseApp? secondaryApp;
    try {
      // Gunakan options app utama
      final mainOptions = Firebase.app().options;
      const secondaryName = 'secondary_doctor_creation';

      // Hapus instance lama jika ada
      try {
        final old = Firebase.app(secondaryName);
        await old.delete();
      } catch (_) {}

      secondaryApp = await Firebase.initializeApp(
        name: secondaryName,
        options: mainOptions,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: emailClean,
        password: password,
      );

      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(fullName.trim());

      // Sign out dari instance sekunder
      await secondaryAuth.signOut();

      final doctor = AppUser(
        uid: uid,
        fullName: fullName.trim(),
        username: usernameClean,
        email: emailClean,
        phoneNumber: phoneClean,
        dob: dob.trim(),
        role: AppRole.doctor,
        specialization: specialization.trim(),
        isActive: true,
      );

      await repo.createDoctor(doctor: doctor);

      debugPrint('✅ [AuthService] Dokter dibuat oleh admin: $uid');
      return doctor;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapError(e.code, e.message ?? 'Gagal membuat akun dokter.'));
    } finally {
      try {
        await secondaryApp?.delete();
      } catch (_) {}
    }
  }

  // ─── Reset Password ───────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(
        _mapError(e.code, e.message ?? 'Gagal mengirim email reset.'),
      );
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────
  Future<void> signOut() async {
    await SessionService.instance.stopSession();
    await _auth.signOut();
    debugPrint('ℹ️ [AuthService] User logout.');
  }
}
