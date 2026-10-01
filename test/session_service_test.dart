import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:d_care/core/constants/session_config.dart';
import 'package:d_care/core/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionConfig Tests', () {
    test('Durasi timeout sesuai spesifikasi kebutuhan', () {
      expect(SessionConfig.backgroundTimeout, const Duration(minutes: 5));
      expect(SessionConfig.inactivityTimeout, const Duration(minutes: 10));
      expect(SessionConfig.warningDuration, const Duration(seconds: 30));
    });
  });

  group('SessionService SharedPreferences & Cold Start Logic', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveLastActive, getLastActive, dan clearLastActive bekerja dengan benar', () async {
      final service = SessionService.instance;

      final testTime = DateTime(2026, 10, 1, 12, 0, 0);
      await service.saveLastActive(testTime);

      final loaded = await service.getLastActive();
      expect(loaded, isNotNull);
      expect(loaded!.millisecondsSinceEpoch, testTime.millisecondsSinceEpoch);

      await service.clearLastActive();
      final cleared = await service.getLastActive();
      expect(cleared, isNull);
    });

    test('isSessionExpiredOnColdStart mendeteksi sesi valid (< 5 menit)', () async {
      final service = SessionService.instance;

      // 2 menit yang lalu
      final recentTime = DateTime.now().subtract(const Duration(minutes: 2));
      await service.saveLastActive(recentTime);

      final isExpired = await service.isSessionExpiredOnColdStart();
      expect(isExpired, isFalse);
    });

    test('isSessionExpiredOnColdStart mendeteksi sesi kedaluwarsa (> 5 menit)', () async {
      final service = SessionService.instance;

      // 6 menit yang lalu
      final expiredTime = DateTime.now().subtract(const Duration(minutes: 6));
      await service.saveLastActive(expiredTime);

      final isExpired = await service.isSessionExpiredOnColdStart();
      expect(isExpired, isTrue);
    });

    test('isSessionExpiredOnColdStart mendeteksi manipulasi jam mundur (selisih negatif)', () async {
      final service = SessionService.instance;

      // Waktu di masa depan (misal jam diubah mundur)
      final futureTime = DateTime.now().add(const Duration(hours: 1));
      await service.saveLastActive(futureTime);

      final isExpired = await service.isSessionExpiredOnColdStart();
      expect(isExpired, isTrue);
    });
  });
}
