import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  /// Notifier untuk URL / Data URI foto profil pengguna yang aktif saat ini
  final ValueNotifier<String?> profileImagePath = ValueNotifier<String?>(null);

  final ImagePicker _picker = ImagePicker();

  /// Daftar avatar preset siap pakai untuk pasien & dokter
  static const List<Map<String, String>> presetAvatars = [
    {
      'title': 'Pria Kasual',
      'url': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=350&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Wanita Senyum',
      'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=350&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Pria Kacamata',
      'url': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=350&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Wanita Berhijab / Sopan',
      'url': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=350&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Pria Muda',
      'url': 'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=350&auto=format&fit=crop&q=80',
    },
    {
      'title': 'Wanita Elegan',
      'url': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=350&auto=format&fit=crop&q=80',
    },
  ];

  /// Muat foto profil pengguna dari Firestore / Auth
  Future<void> loadCurrentPhoto([String? initialUrl]) async {
    if (initialUrl != null && initialUrl.trim().isNotEmpty) {
      profileImagePath.value = initialUrl.trim();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Cek koleksi users/{uid}
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final photo = userDoc.data()!['photoUrl']?.toString();
        if (photo != null && photo.trim().isNotEmpty) {
          profileImagePath.value = photo.trim();
          return;
        }
      }

      // 2. Cek koleksi doctors/{uid}
      final doctorDoc = await FirebaseFirestore.instance.collection('doctors').doc(user.uid).get();
      if (doctorDoc.exists && doctorDoc.data() != null) {
        final photo = doctorDoc.data()!['photoUrl']?.toString();
        if (photo != null && photo.trim().isNotEmpty) {
          profileImagePath.value = photo.trim();
          return;
        }
      }

      // 3. Cek FirebaseAuth photoURL
      if (user.photoURL != null && user.photoURL!.trim().isNotEmpty) {
        profileImagePath.value = user.photoURL!.trim();
      }
    } catch (e) {
      debugPrint('⚠️ [ProfileImageService] Error loadCurrentPhoto: $e');
    }
  }

  /// Ambil foto dari Galeri HP / Komputer, dikonversi ke Base64 Data URI yang multiplatform
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = pickedFile.mimeType ?? 'image/jpeg';
        final dataUri = 'data:$mimeType;base64,$base64String';
        profileImagePath.value = dataUri;
        return dataUri;
      }
    } catch (e) {
      debugPrint('⚠️ [ProfileImageService] Error picking image from gallery: $e');
    }
    return null;
  }

  /// Ambil foto dari Kamera
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);
        final mimeType = pickedFile.mimeType ?? 'image/jpeg';
        final dataUri = 'data:$mimeType;base64,$base64String';
        profileImagePath.value = dataUri;
        return dataUri;
      }
    } catch (e) {
      debugPrint('⚠️ [ProfileImageService] Error picking image from camera: $e');
    }
    return null;
  }

  /// Simpan foto profil secara permanen ke Firestore & Auth,
  /// serta sinkronkan ke semua percakapan di koleksi consultation_chats
  Future<void> saveProfilePhoto(
    String? newPhotoUrl, {
    String? displayName,
    String? role,
  }) async {
    profileImagePath.value = newPhotoUrl;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final uid = user.uid;
    final effectiveName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : (user.displayName ?? '');

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Simpan di koleksi users/{uid}
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
      batch.set(
        userDocRef,
        {
          'photoUrl': newPhotoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // 2. Simpan juga di koleksi doctors/{uid} jika akun dokter
      final doctorDocRef = FirebaseFirestore.instance.collection('doctors').doc(uid);
      batch.set(
        doctorDocRef,
        {
          'photoUrl': newPhotoUrl ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await batch.commit().catchError((e) {
        debugPrint('⚠️ [ProfileImageService] Batch update user/doctor error: $e');
      });

      // 3. Sinkronkan ke consultation_chats pasien
      try {
        final chatsByPatientId = await FirebaseFirestore.instance
            .collection('consultation_chats')
            .where('patientId', isEqualTo: uid)
            .get();
        for (final doc in chatsByPatientId.docs) {
          doc.reference.update({
            'patientPhotoUrl': newPhotoUrl ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          }).catchError((_) {});
        }

        if (effectiveName.isNotEmpty) {
          final chatsByPatientName = await FirebaseFirestore.instance
              .collection('consultation_chats')
              .where('patientName', isEqualTo: effectiveName)
              .get();
          for (final doc in chatsByPatientName.docs) {
            doc.reference.update({
              'patientPhotoUrl': newPhotoUrl ?? '',
              'updatedAt': FieldValue.serverTimestamp(),
            }).catchError((_) {});
          }
        }
      } catch (e) {
        debugPrint('⚠️ [ProfileImageService] Error syncing consultation_chats: $e');
      }

      // 4. Update photoURL di Firebase Auth
      await user.updatePhotoURL(newPhotoUrl).catchError((_) {});
    } catch (e) {
      debugPrint('⚠️ [ProfileImageService] Error saving profile photo: $e');
    }
  }

  /// Hapus foto profil (kembali ke avatar bawaan)
  Future<void> clearImage({String? displayName}) async {
    await saveProfilePhoto(null, displayName: displayName);
  }

  /// Cek apakah pengguna memiliki foto profil kustom yang aktif
  bool hasCustomImage() {
    final path = profileImagePath.value;
    return path != null && path.trim().isNotEmpty;
  }
}
