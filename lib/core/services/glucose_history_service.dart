import 'package:flutter/foundation.dart';

class GlucoseRecord {
  final String id;
  final int value; // Nilai gula darah dalam mg/dL
  final DateTime date;
  final String time; // Contoh: '07.30'
  final String label; // Contoh: 'Sebelum makan', '2 Jam Setelah Makan'
  final String? note;

  const GlucoseRecord({
    required this.id,
    required this.value,
    required this.date,
    required this.time,
    required this.label,
    this.note,
  });
}

class GlucoseHistoryService {
  static final GlucoseHistoryService _instance = GlucoseHistoryService._internal();
  factory GlucoseHistoryService() => _instance;
  GlucoseHistoryService._internal();

  /// Daftar seluruh riwayat data gula darah yang terekam pada sistem.
  /// Awalnya kosong karena belum ada data yang terekam.
  final ValueNotifier<List<GlucoseRecord>> recordsNotifier = ValueNotifier<List<GlucoseRecord>>([]);

  List<GlucoseRecord> get records => recordsNotifier.value;

  /// Nilai tertinggi (Highest Glucose) dari semua total riwayat
  int? get highestGlucose {
    if (records.isEmpty) return null;
    return records.map((r) => r.value).reduce((a, b) => a > b ? a : b);
  }

  /// Nilai rata-rata (Average Glucose) dari semua total riwayat
  int? get averageGlucose {
    if (records.isEmpty) return null;
    final total = records.map((r) => r.value).reduce((a, b) => a + b);
    return (total / records.length).round();
  }

  /// Nilai terendah (Lowest Glucose) dari semua total riwayat
  int? get lowestGlucose {
    if (records.isEmpty) return null;
    return records.map((r) => r.value).reduce((a, b) => a < b ? a : b);
  }

  /// Teks display untuk Highest Glucose ('-' jika belum ada data)
  String get highestDisplay => highestGlucose != null ? '$highestGlucose' : '-';

  /// Teks display untuk Average Glucose ('-' jika belum ada data)
  String get averageDisplay => averageGlucose != null ? '$averageGlucose' : '-';

  /// Teks display untuk Lowest Glucose ('-' jika belum ada data)
  String get lowestDisplay => lowestGlucose != null ? '$lowestGlucose' : '-';

  /// Menambahkan rekaman gula darah baru ke sistem
  void addRecord({
    required int value,
    DateTime? date,
    String? time,
    String label = 'Pemeriksaan Mandiri',
    String? note,
  }) {
    final now = date ?? DateTime.now();
    final timeStr = time ??
        '${now.hour.toString().padLeft(2, '0')}.${now.minute.toString().padLeft(2, '0')}';
    final record = GlucoseRecord(
      id: 'GLU-${DateTime.now().millisecondsSinceEpoch}',
      value: value,
      date: now,
      time: timeStr,
      label: label,
      note: note,
    );
    recordsNotifier.value = [record, ...recordsNotifier.value];
  }

  /// Mengatur ulang seluruh data
  void setRecords(List<GlucoseRecord> newRecords) {
    recordsNotifier.value = List.unmodifiable(newRecords);
  }

  /// Mengosongkan data rekaman
  void clearRecords() {
    recordsNotifier.value = [];
  }
}
