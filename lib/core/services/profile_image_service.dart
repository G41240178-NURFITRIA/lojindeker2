import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ProfileImageService {
  static final ProfileImageService _instance = ProfileImageService._internal();
  factory ProfileImageService() => _instance;
  ProfileImageService._internal();

  /// Notifier untuk path foto profil yang dipilih oleh pengguna
  final ValueNotifier<String?> profileImagePath = ValueNotifier<String?>(null);

  final ImagePicker _picker = ImagePicker();

  /// Ambil foto dari Galeri
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        profileImagePath.value = pickedFile.path;
        return pickedFile.path;
      }
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Ambil foto dari Kamera
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        profileImagePath.value = pickedFile.path;
        return pickedFile.path;
      }
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
    return null;
  }

  /// Hapus foto kustom (kembali ke default)
  void clearImage() {
    profileImagePath.value = null;
  }

  /// Cek apakah file foto profil valid dan ada di storage
  bool hasCustomImage() {
    final path = profileImagePath.value;
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}
