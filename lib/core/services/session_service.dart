import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/session_config.dart';
import '../../features/auth/screens/login_screen.dart';

/// Service singleton untuk mengelola Session Timeout otomatis aplikasi D-Care.
/// - Background timeout (5 menit): memeriksa selisih waktu saat app di-minimize, mati layar, atau di-kill.
/// - Inactivity timeout (10 menit): memantau interaksi sentuhan pengguna saat app aktif di foreground.
/// - Warning dialog (30 detik): dialog peringatan dengan countdown sebelum auto-logout.
class SessionService with WidgetsBindingObserver {
  SessionService._internal();
  static final SessionService instance = SessionService._internal();

  /// Global navigator key agar SessionService dapat melakukan navigasi dan menampilkan dialog
  /// dari mana saja tanpa membutuhkan BuildContext lokal.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String _kLastActiveAt = 'dcare_session_last_active_at';
  static const String _kBackgroundEnteredAt = 'dcare_session_background_entered_at';

  DateTime? _lastActiveTime;
  DateTime? _backgroundEnteredTime;
  Timer? _inactivityTimer;
  Timer? _warningCountdownTimer;

  bool _isInitialized = false;
  bool _isTracking = false;
  bool _isLoggingOut = false;
  bool _isShowingWarningDialog = false;
  BuildContext? _warningDialogContext;

  DateTime? _lastThrottledSave;

  /// Inisialisasi service pada saat aplikasi dijalankan (main.dart)
  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    WidgetsBinding.instance.addObserver(this);

    // Pantau perubahan status autentikasi Firebase
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        if (!_isTracking) {
          startSession(isNewLogin: false);
        }
      } else {
        stopSession();
      }
    });
  }

  /// Mulai pelacakan sesi saat pengguna telah login.
  /// Jika [isNewLogin] bernilai true, timestamp akan di-reset bersih ke waktu sekarang.
  /// Jika false (misal cold start / pemulihan sesi), baca data lama agar cold start check akurat.
  Future<void> startSession({bool isNewLogin = false}) async {
    _isTracking = true;
    _isLoggingOut = false;
    _backgroundEnteredTime = null;
    await clearBackgroundEnteredAt();

    if (isNewLogin) {
      final now = DateTime.now();
      _lastActiveTime = now;
      await saveLastActive(now);
    } else {
      _lastActiveTime = await getLastActive();
      if (_lastActiveTime == null) {
        final now = DateTime.now();
        _lastActiveTime = now;
        await saveLastActive(now);
      }
    }
    _resetInactivityTimer();
  }

  /// Berhenti melacak sesi dan bersihkan semua timer (misalnya saat logout)
  Future<void> stopSession() async {
    _isTracking = false;
    _isLoggingOut = false;
    _dismissWarningDialog();
    _stopInactivityTimer();
    _stopWarningTimer();
    await clearBackgroundEnteredAt();
    await clearLastActive();
  }

  /// Simpan timestamp saat aplikasi masuk ke background
  Future<void> saveBackgroundEnteredAt([DateTime? time]) async {
    final t = time ?? DateTime.now();
    _backgroundEnteredTime = t;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kBackgroundEnteredAt, t.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal menyimpan backgroundEnteredAt: $e');
    }
  }

  /// Ambil timestamp saat aplikasi masuk ke background
  Future<DateTime?> getBackgroundEnteredAt() async {
    if (_backgroundEnteredTime != null) {
      return _backgroundEnteredTime;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kBackgroundEnteredAt);
      if (ms != null) {
        _backgroundEnteredTime = DateTime.fromMillisecondsSinceEpoch(ms);
        return _backgroundEnteredTime;
      }
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal membaca backgroundEnteredAt: $e');
    }
    return null;
  }

  /// Hapus timestamp masuk background
  Future<void> clearBackgroundEnteredAt() async {
    _backgroundEnteredTime = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kBackgroundEnteredAt);
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal menghapus backgroundEnteredAt: $e');
    }
  }

  /// Simpan timestamp aktivitas terakhir ke SharedPreferences
  Future<void> saveLastActive([DateTime? time]) async {
    final t = time ?? DateTime.now();
    _lastActiveTime = t;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kLastActiveAt, t.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal menyimpan lastActiveAt: $e');
    }
  }

  /// Ambil timestamp aktivitas terakhir dari SharedPreferences
  Future<DateTime?> getLastActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_kLastActiveAt);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal membaca lastActiveAt: $e');
    }
    return _lastActiveTime;
  }

  /// Hapus timestamp aktivitas terakhir
  Future<void> clearLastActive() async {
    _lastActiveTime = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLastActiveAt);
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal menghapus lastActiveAt: $e');
    }
  }

  /// Pemeriksaan saat Cold Start di AuthGate:
  /// Mengembalikan true jika sesi user telah melebihi backgroundTimeout (2 menit / 120 detik)
  /// sejak aplikasi masuk background atau ditutup.
  Future<bool> isSessionExpiredOnColdStart() async {
    final bgTime = await getBackgroundEnteredAt();
    final lastActive = await getLastActive();
    final referenceTime = bgTime ?? lastActive;

    if (referenceTime == null) {
      // Jika belum ada data tersimpan, set sekarang sebagai acuan
      await saveLastActive();
      return false;
    }

    final now = DateTime.now();
    final diff = now.difference(referenceTime);
    final timeoutLimit = SessionConfig.backgroundTimeout;

    // Timeout jika selisih >= 120 detik ATAU selisih negatif (jam perangkat diubah mundur)
    if (diff >= timeoutLimit || diff.isNegative) {
      debugPrint(
        '⏳ [SessionService] Cold start timeout: diff=${diff.inSeconds}s (maks: ${timeoutLimit.inSeconds}s)',
      );
      await clearBackgroundEnteredAt();
      await clearLastActive();
      return true;
    }

    // Masih dalam batas waktu sesi (< 2 menit): bersihkan mark background dan perbarui last active
    await clearBackgroundEnteredAt();
    await saveLastActive(now);
    return false;
  }

  /// Dipanggil setiap kali pengguna menyentuh layar aplikasi (onPointerDown / Move)
  void onUserInteraction() {
    if (!_isTracking || _isLoggingOut) return;

    // Jika dialog peringatan sedang muncul, jangan reset dari gesture sembarang di layar;
    // Pengguna harus secara eksplisit menekan tombol "Tetap Masuk"
    if (_isShowingWarningDialog) return;

    final now = DateTime.now();
    _lastActiveTime = now;

    // Throttle penyimpanan ke storage (maksimal 1x per 30 detik agar hemat IO)
    if (_lastThrottledSave == null ||
        now.difference(_lastThrottledSave!) > const Duration(seconds: 30)) {
      _lastThrottledSave = now;
      saveLastActive(now);
    }

    _resetInactivityTimer();
  }

  /// Lifecycle observer: menangani background (minimize, screen off, kill) & resumed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (!_isTracking || _isLoggingOut) return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Ketentuan 1: Ketika pengguna menekan tombol Home atau berpindah ke aplikasi lain,
        // catat waktu aplikasi masuk ke background.
        if (_backgroundEnteredTime == null) {
          final now = DateTime.now();
          _backgroundEnteredTime = now;
          saveBackgroundEnteredAt(now);
          debugPrint('📱 [SessionService] App masuk background pada: $now');
        }
        _stopInactivityTimer();
        _dismissWarningDialog();
        break;

      case AppLifecycleState.resumed:
        // Saat aplikasi dibuka kembali, periksa background timeout 2 menit (120 detik)
        _handleAppResumed();
        break;

      case AppLifecycleState.detached:
        if (_backgroundEnteredTime == null) {
          saveBackgroundEnteredAt();
        }
        break;
    }
  }

  /// Penanganan saat aplikasi kembali aktif di foreground
  Future<void> _handleAppResumed() async {
    if (!_isTracking || _isLoggingOut) return;

    final bgTime = await getBackgroundEnteredAt();
    final now = DateTime.now();

    if (bgTime != null) {
      final diff = now.difference(bgTime);
      final timeoutLimit = SessionConfig.backgroundTimeout;

      debugPrint(
        '📱 [SessionService] App resumed. Waktu di background: ${diff.inSeconds} detik (Batas: ${timeoutLimit.inSeconds} detik)',
      );

      // Ketentuan 3 & 4: Jika pengguna kembali setelah 2 menit atau lebih (>= 120 detik)
      // sejak aplikasi masuk background, otomatis logout dan arahkan ke halaman Login.
      // (Juga jika selisih negatif akibat jam diubah mundur)
      if (diff >= timeoutLimit || diff.isNegative) {
        debugPrint(
          '⏳ [SessionService] Background timeout tercapai: diff=${diff.inSeconds}s (maks: ${timeoutLimit.inSeconds}s)',
        );
        await clearBackgroundEnteredAt();
        await handleTimeout(
          message: 'Sesi Anda telah berakhir (tidak aktif lebih dari 2 menit). Silakan login kembali.',
        );
        return;
      }
    }

    // Ketentuan 2: Jika pengguna kembali sebelum 2 menit, tetap tampilkan halaman terakhir tanpa login ulang.
    debugPrint('✅ [SessionService] Kembali dalam rentang aman (< 2 menit). Sesi dipertahankan.');
    await clearBackgroundEnteredAt();
    await saveLastActive(now);
    _resetInactivityTimer();
  }

  /// Reset timer inaktivitas (10 menit)
  void _resetInactivityTimer() {
    _stopInactivityTimer();
    if (!_isTracking || _isLoggingOut) return;

    _inactivityTimer = Timer(SessionConfig.inactivityTimeout, () {
      _onInactivityTimeoutTriggered();
    });
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _stopWarningTimer() {
    _warningCountdownTimer?.cancel();
    _warningCountdownTimer = null;
  }

  /// Dipanggil saat inaktivitas 10 menit tercapai tanpa sentuhan
  void _onInactivityTimeoutTriggered() {
    if (!_isTracking || _isLoggingOut) return;
    _showWarningDialog();
  }

  /// Menampilkan dialog peringatan 30 detik sebelum auto-logout
  void _showWarningDialog() {
    final navState = navigatorKey.currentState;
    final context = navState?.overlay?.context ?? navState?.context;
    if (context == null || !context.mounted) return;

    _isShowingWarningDialog = true;
    int remainingSeconds = SessionConfig.warningDuration.inSeconds;

    // StatefulBuilder agar angka countdown di dialog dapat ter-update setiap detik
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _warningDialogContext = dialogCtx;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _warningCountdownTimer?.cancel();
            _warningCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              remainingSeconds--;
              if (remainingSeconds <= 0) {
                timer.cancel();
                _dismissWarningDialog();
                handleTimeout(
                  message: 'Sesi Anda telah berakhir karena tidak ada aktivitas.',
                );
              } else {
                setDialogState(() {});
              }
            });

            return PopScope(
              canPop: false,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFBA171E).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFBA171E),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Peringatan Sesi',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF141414),
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sesi Anda akan berakhir dalam $remainingSeconds detik karena tidak ada aktivitas.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF555555),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Apakah Anda ingin tetap berada di dalam aplikasi?',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                actions: [
                  Row(
                    children: [
                      // Tombol Keluar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _dismissWarningDialog();
                            handleTimeout(
                              message: 'Anda telah keluar dari aplikasi.',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFD0D0D0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Keluar',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF666666),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Tombol Tetap Masuk
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _dismissWarningDialog();
                            saveLastActive();
                            _resetInactivityTimer();
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: const Color(0xFFBA171E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Tetap Masuk',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      _isShowingWarningDialog = false;
      _warningDialogContext = null;
      _stopWarningTimer();
    });
  }

  void _dismissWarningDialog() {
    _stopWarningTimer();
    if (_isShowingWarningDialog) {
      _isShowingWarningDialog = false;
      if (_warningDialogContext != null && _warningDialogContext!.mounted) {
        Navigator.of(_warningDialogContext!).pop();
      }
      _warningDialogContext = null;
    }
  }

  /// Eksekusi logout akibat timeout sesi, bersihkan stack navigasi, dan kembali ke halaman Login.
  Future<void> handleTimeout({
    String message = 'Sesi Anda telah berakhir (tidak aktif lebih dari 2 menit). Silakan login kembali.',
  }) async {
    if (_isLoggingOut) return;
    _isLoggingOut = true;

    _dismissWarningDialog();
    _stopInactivityTimer();
    _stopWarningTimer();
    _isTracking = false;

    await clearBackgroundEnteredAt();
    await clearLastActive();

    // Hapus sesi autentikasi secara aman
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('⚠️ [SessionService] Gagal signOut Firebase: $e');
    }

    _isLoggingOut = false;

    // Bersihkan seluruh history/stack navigasi agar pengguna tidak bisa
    // kembali ke halaman dashboard dengan tombol Back sistem
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginScreen(sessionExpiredMessage: message),
        ),
        (route) => false,
      );
    }
  }

  /// Dispose service saat aplikasi di-terminate
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopInactivityTimer();
    _stopWarningTimer();
  }
}
