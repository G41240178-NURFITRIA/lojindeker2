import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum role pengguna dalam aplikasi D-Care
enum AppRole { pasien, doctor, admin }

/// Extension untuk konversi AppRole ↔ String (nilai Firestore)
extension AppRoleExtension on AppRole {
  /// Nilai string yang disimpan di Firestore
  String get firestoreValue {
    switch (this) {
      case AppRole.pasien:
        return 'pasien';
      case AppRole.doctor:
        return 'doctor';
      case AppRole.admin:
        return 'admin';
    }
  }

  /// Nama koleksi Firestore untuk role ini
  String get collection {
    switch (this) {
      case AppRole.pasien:
        return 'users';
      case AppRole.doctor:
        return 'doctors';
      case AppRole.admin:
        return 'admins';
    }
  }
}

/// Parsing string → AppRole (null-safe)
AppRole appRoleFromString(String? value) {
  switch (value?.toLowerCase().trim()) {
    case 'doctor':
    case 'dokter':
      return AppRole.doctor;
    case 'admin':
      return AppRole.admin;
    default:
      return AppRole.pasien;
  }
}

/// Model data pengguna lengkap (semua koleksi Firestore)
class AppUser {
  final String uid;
  final String fullName;
  final String username;
  final String email;
  final String phoneNumber;
  final String dob; // "YYYY-MM-DD"
  final AppRole role;

  // Khusus dokter
  final String? specialization;
  final bool isActive;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.dob,
    required this.role,
    this.specialization,
    this.isActive = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid: uid,
      fullName: (map['fullName'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phoneNumber: (map['phoneNumber'] as String?) ?? '',
      dob: (map['dob'] as String?) ?? '',
      role: appRoleFromString(map['role'] as String?),
      specialization: map['specialization'] as String?,
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'fullName': fullName,
      'username': username.toLowerCase(),
      'email': email.toLowerCase(),
      'phoneNumber': phoneNumber,
      'dob': dob,
      'role': role.firestoreValue,
      if (role == AppRole.doctor) ...{
        'specialization': specialization ?? '',
        'isActive': isActive,
      },
    };
  }

  /// Buat map untuk dokumen loginLookup
  Map<String, dynamic> toLookupMap() {
    return <String, dynamic>{
      'email': email.toLowerCase(),
      'uid': uid,
      'role': role.firestoreValue,
    };
  }

  AppUser copyWith({
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    String? dob,
    AppRole? role,
    String? specialization,
    bool? isActive,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dob: dob ?? this.dob,
      role: role ?? this.role,
      specialization: specialization ?? this.specialization,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Dokumen loginLookup di Firestore
class LoginLookup {
  final String email;
  final String uid;
  final String role;

  const LoginLookup({
    required this.email,
    required this.uid,
    required this.role,
  });

  factory LoginLookup.fromMap(Map<String, dynamic> map) {
    return LoginLookup(
      email: (map['email'] as String?) ?? '',
      uid: (map['uid'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'pasien',
    );
  }
}

/// Helper: ambil Timestamp Firestore sebagai DateTime?
DateTime? tsToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
