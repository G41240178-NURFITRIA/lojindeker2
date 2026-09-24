import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';

/// Konfigurasi Firebase yang membaca kredensial dari file .env
class FirebaseConfig {
  FirebaseConfig._();

  static String _getValue(List<String> keys, {String defaultValue = ''}) {
    for (final key in keys) {
      final val = dotenv.env[key];
      if (val != null && val.trim().isNotEmpty) {
        return val.trim();
      }
    }
    return defaultValue;
  }

  /// API Key Firebase
  static String get apiKey => _getValue(['FIREBASE_API_KEY', 'apiKey', 'API_KEY']);

  /// Auth Domain Firebase
  static String get authDomain => _getValue(['FIREBASE_AUTH_DOMAIN', 'authDomain', 'AUTH_DOMAIN']);

  /// Project ID Firebase
  static String get projectId => _getValue(['FIREBASE_PROJECT_ID', 'projectId', 'PROJECT_ID']);

  /// Storage Bucket Firebase
  static String get storageBucket => _getValue(['FIREBASE_STORAGE_BUCKET', 'storageBucket', 'STORAGE_BUCKET']);

  /// Messaging Sender ID Firebase
  static String get messagingSenderId => _getValue(['FIREBASE_MESSAGING_SENDER_ID', 'messagingSenderId', 'MESSAGING_SENDER_ID']);

  /// App ID Firebase
  static String get appId => _getValue(['FIREBASE_APP_ID', 'appId', 'APP_ID']);

  /// FirebaseOptions yang di-generate dari nilai-nilai .env
  static FirebaseOptions get currentPlatform {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isNotEmpty ? authDomain : null,
      storageBucket: storageBucket.isNotEmpty ? storageBucket : null,
    );
  }

  /// Mengecek apakah variabel wajib sudah terisi di .env
  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty;

  /// Inisialisasi dotenv dan Firebase
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('⚠️ [FirebaseConfig] File .env tidak ditemukan atau gagal dimuat: $e');
    }

    if (isConfigured) {
      try {
        await Firebase.initializeApp(
          options: currentPlatform,
        );
        debugPrint('✅ [FirebaseConfig] Firebase berhasil diinisialisasi.');
      } catch (e) {
        debugPrint('❌ [FirebaseConfig] Gagal menginisialisasi Firebase: $e');
      }
    } else {
      debugPrint(
        'ℹ️ [FirebaseConfig] Kredensial Firebase di .env belum diisi. Inisialisasi Firebase dilewati sementara.',
      );
    }
  }
}
