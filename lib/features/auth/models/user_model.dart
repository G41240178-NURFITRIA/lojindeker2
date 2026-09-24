import '../widgets/role_selector.dart';

/// Model representasi data pengguna di aplikasi dan Firestore
class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String dob;
  final UserRole role;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.dob,
    required this.role,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    UserRole role = UserRole.pasien;
    final roleStr = map['role']?.toString().toLowerCase();
    if (roleStr == 'dokter') {
      role = UserRole.dokter;
    } else if (roleStr == 'admin') {
      role = UserRole.admin;
    }

    DateTime? createdAt;
    if (map['createdAt'] != null) {
      final val = map['createdAt'];
      if (val is DateTime) {
        createdAt = val;
      } else if (val is String) {
        createdAt = DateTime.tryParse(val);
      } else {
        try {
          createdAt = (val as dynamic).toDate();
        } catch (_) {}
      }
    }

    return UserModel(
      uid: id,
      fullName: map['fullName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? map['mobile'] ?? '',
      dob: map['dob'] ?? '',
      role: role,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'dob': dob,
      'role': role.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
