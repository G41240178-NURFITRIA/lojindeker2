import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_repository.dart';
import 'services/auth_service.dart';
import 'core/services/session_service.dart';
import 'models/app_user.dart';
import 'features/auth/screens/landing_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/doctor/screens/doctor_dashboard_screen.dart';
import 'features/patient/screens/patient_dashboard_screen.dart';

/// AuthGate mengontrol aliran autentikasi aplikasi berdasarkan status login
/// FirebaseAuth, pemeriksaan timeout cold start, dan role pengguna di Firestore.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkedColdStart = false;
  bool _coldStartTimedOut = false;

  @override
  void initState() {
    super.initState();
    _checkColdStart();
  }

  Future<void> _checkColdStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final isExpired =
          await SessionService.instance.isSessionExpiredOnColdStart();
      if (isExpired) {
        await AuthService.instance.signOut();
        if (mounted) {
          setState(() {
            _coldStartTimedOut = true;
            _checkedColdStart = true;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _checkedColdStart = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen sementara memeriksa cold start sesi
    if (!_checkedColdStart) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF1F1),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA171E)),
          ),
        ),
      );
    }

    // Jika pada cold start sesi sudah melebihi background timeout (> 5 menit)
    if (_coldStartTimedOut) {
      return const LoginScreen(
        sessionExpiredMessage: 'Sesi Anda telah berakhir, silakan login kembali.',
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Tampilkan loading screen sementara Firebase memeriksa sesi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAF1F1),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA171E)),
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LandingScreen();
        }

        // Pengguna terautentikasi di Auth, muat data profil & role dari Firestore
        return FutureBuilder<AppUser?>(
          future: UserRepository.instance.findByUid(user.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFFAF1F1),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA171E)),
                  ),
                ),
              );
            }

            final appUser = userSnapshot.data;

            // Jika UID tidak ditemukan di admins, doctors, maupun users
            if (appUser == null) {
              // Sign out agar tidak tersangkut
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AuthService.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Akun tidak terdaftar di sistem.'),
                    backgroundColor: Color(0xFFBA171E),
                  ),
                );
              });
              return const LandingScreen();
            }

            // Validasi status dokter aktif
            if (appUser.role == AppRole.doctor && !appUser.isActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                AuthService.instance.signOut();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Akun dokter Anda dinonaktifkan. Hubungi admin.'),
                    backgroundColor: Color(0xFFBA171E),
                  ),
                );
              });
              return const LandingScreen();
            }

            // Redirect otomatis sesuai role
            switch (appUser.role) {
              case AppRole.admin:
                return const AdminDashboardScreen();
              case AppRole.doctor:
                return DoctorDashboardScreen(doctorName: appUser.fullName);
              case AppRole.pasien:
                return PatientDashboardScreen(patientName: appUser.fullName);
            }
          },
        );
      },
    );
  }
}
