// ignore_for_file: avoid_print
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:d_care/core/config/firebase_config.dart';

/// Skrip utilitas untuk melakukan Seed Akun Admin awal ke Firebase Auth & Firestore.
///
/// Cara Menjalankan:
/// flutter run scripts/seed_admin.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();

  const adminEmail = 'admin@dcare.id';
  const adminPassword = 'AdminDcare2026!';
  const adminUsername = 'admin';
  const adminPhone = '081234567890';
  const adminFullName = 'Administrator Utama';
  const adminDob = '1990-01-01';

  print('=== SEED ADMIN D-CARE ===');
  print('Email    : $adminEmail');
  print('Username : $adminUsername');
  print('Phone    : $adminPhone');

  try {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    UserCredential? cred;
    try {
      cred = await auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
      print('✅ Akun Firebase Auth berhasil dibuat dengan UID: ${cred.user!.uid}');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('ℹ️ Akun Auth sudah ada, mencoba sign in...');
        cred = await auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
        print('✅ Berhasil sign in dengan UID: ${cred.user!.uid}');
      } else {
        rethrow;
      }
    }

    final uid = cred.user!.uid;

    final batch = firestore.batch();

    // 1. Dokumen di koleksi admins/{uid}
    final adminRef = firestore.collection('admins').doc(uid);
    batch.set(adminRef, {
      'uid': uid,
      'fullName': adminFullName,
      'username': adminUsername,
      'email': adminEmail,
      'phoneNumber': adminPhone,
      'dob': adminDob,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Dokumen loginLookup untuk username, phone, dan email
    final lookupUsername = firestore.collection('loginLookup').doc(adminUsername);
    final lookupPhone = firestore.collection('loginLookup').doc(adminPhone);
    final lookupEmail = firestore.collection('loginLookup').doc(adminEmail);

    final lookupData = {
      'email': adminEmail,
      'uid': uid,
      'role': 'admin',
    };

    batch.set(lookupUsername, lookupData);
    batch.set(lookupPhone, lookupData);
    batch.set(lookupEmail, lookupData);

    await batch.commit();

    print('✅ Data admin & loginLookup berhasil ditulis ke Firestore!');
    print('Selesai. Anda sekarang dapat login sebagai admin.');
  } catch (e) {
    print('❌ Gagal melakukan seed admin: $e');
  }
}
