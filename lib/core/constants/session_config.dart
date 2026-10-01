/// Konfigurasi durasi timeout sesi aplikasi D-Care.
/// Semua durasi diletakkan di satu file agar mudah disesuaikan / diuji.
class SessionConfig {
  SessionConfig._();

  /// Waktu maksimal aplikasi berada di latar belakang (minimize, pindah app, layar mati, app di-kill).
  /// Melebihi durasi ini, sesi user akan berakhir otomatis.
  static const Duration backgroundTimeout = Duration(minutes: 5);

  /// Waktu ketidakaktifan (user tidak menyentuh layar saat app terbuka).
  /// Setelah durasi ini terlewati, dialog peringatan akan dimunculkan.
  static const Duration inactivityTimeout = Duration(minutes: 10);

  /// Durasi countdown pada dialog peringatan sebelum logout otomatis dilakukan.
  static const Duration warningDuration = Duration(seconds: 30);
}
