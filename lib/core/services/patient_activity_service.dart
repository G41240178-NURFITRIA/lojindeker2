import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../features/patient/models/medication_reminder_model.dart';
import '../../features/patient/models/risk_assessment_model.dart';
import 'auth_service.dart';

/// Model untuk rekam riwayat dan status pengecekan risiko diabetes pasien
class PatientRiskRecord {
  final String id;
  final String date;
  final String time;
  final String status; // 'Rendah' | 'Sedang' | 'Tinggi'
  final int score;
  final String glucoseLevel;
  final String scoreDescription;
  final String recommendation;
  final String bmi;
  final String bloodPressure;
  final String familyHistory;
  final String physicalActivity;
  final double? weight;
  final double? height;
  final double? imt;
  final String? imtCategory;
  final int? age;
  final String? gender;

  const PatientRiskRecord({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    required this.score,
    required this.glucoseLevel,
    required this.scoreDescription,
    required this.recommendation,
    this.bmi = '22.4 kg/m² (Normal)',
    this.bloodPressure = '120/80 mmHg',
    this.familyHistory = 'Tidak Ada',
    this.physicalActivity = 'Rutin (> 3x seminggu)',
    this.weight,
    this.height,
    this.imt,
    this.imtCategory,
    this.age,
    this.gender,
  });

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'rendah':
        return const Color(0xFF2E7D32);
      case 'sedang':
        return const Color(0xFFE65100);
      case 'tinggi':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF757575);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'time': time,
      'status': status,
      'score': score,
      'glucoseLevel': glucoseLevel,
      'scoreDescription': scoreDescription,
      'recommendation': recommendation,
      'bmi': bmi,
      'bloodPressure': bloodPressure,
      'familyHistory': familyHistory,
      'physicalActivity': physicalActivity,
      'weight': weight,
      'height': height,
      'imt': imt,
      'imtCategory': imtCategory,
      'age': age,
      'gender': gender,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory PatientRiskRecord.fromMap(Map<String, dynamic> map) {
    return PatientRiskRecord(
      id: map['id']?.toString() ?? 'RSK-${DateTime.now().millisecondsSinceEpoch}',
      date: map['date']?.toString() ?? 'Hari ini',
      time: map['time']?.toString() ?? '08:00',
      status: map['status']?.toString() ?? 'Rendah',
      score: (map['score'] as num?)?.toInt() ?? 25,
      glucoseLevel: map['glucoseLevel']?.toString() ?? 'Kadar Gula: - mg/dL',
      scoreDescription: map['scoreDescription']?.toString() ?? 'Skor Risiko: 25%',
      recommendation: map['recommendation']?.toString() ?? 'Pertahankan pola hidup sehat.',
      bmi: map['bmi']?.toString() ?? 'Normal',
      bloodPressure: map['bloodPressure']?.toString() ?? '120/80 mmHg',
      familyHistory: map['familyHistory']?.toString() ?? 'Tidak Ada',
      physicalActivity: map['physicalActivity']?.toString() ?? 'Rutin',
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      imt: (map['imt'] as num?)?.toDouble(),
      imtCategory: map['imtCategory']?.toString(),
      age: (map['age'] as num?)?.toInt(),
      gender: map['gender']?.toString(),
    );
  }
}

/// Model untuk aktivitas konsultasi dokter terakhir
class PatientConsultationActivity {
  final String doctorName;
  final String specialty;
  final String date;
  final String time;
  final String lastMessage;

  const PatientConsultationActivity({
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.time,
    required this.lastMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'specialty': specialty,
      'date': date,
      'time': time,
      'lastMessage': lastMessage,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  factory PatientConsultationActivity.fromMap(Map<String, dynamic> map) {
    return PatientConsultationActivity(
      doctorName: map['doctorName']?.toString() ?? 'dr. Koko',
      specialty: map['specialty']?.toString() ?? 'Spesialis Penyakit Dalam',
      date: map['date']?.toString() ?? '18 Mei 2026',
      time: map['time']?.toString() ?? '14:00',
      lastMessage: map['lastMessage']?.toString() ?? 'Konsultasi selesai',
    );
  }
}

/// Info hasil kalkulasi pengingat obat berikutnya
class NextReminderInfo {
  final MedicationReminder? reminder;
  final String timeText; // contoh: '19.00'
  final String labelText; // contoh: 'Hari ini, 19.00'
  final String subtitleText; // contoh: 'Pengingat obat berikutnya: 19.00'
  final bool allTakenToday;
  final bool hasActiveReminders;

  const NextReminderInfo({
    required this.reminder,
    required this.timeText,
    required this.labelText,
    required this.subtitleText,
    required this.allTakenToday,
    required this.hasActiveReminders,
  });
}

/// Service pusat untuk mengelola dan menyinkronkan:
/// 1. Status Kesehatan Anda (Hasil Cek Risiko terkini)
/// 2. Aktivitas Terbaru (Cek Risiko, Konsultasi Dokter, Pengingat Obat)
class PatientActivityService {
  static final PatientActivityService instance = PatientActivityService._internal();
  PatientActivityService._internal() {
    _initDefaultData();
  }

  static String formatIndonesianDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}.${date.minute.toString().padLeft(2, '0')}';
  }

  // ValueNotifiers untuk reaktivitas UI real-time
  final ValueNotifier<PatientRiskRecord> latestRiskNotifier = ValueNotifier<PatientRiskRecord>(
    const PatientRiskRecord(
      id: 'RSK-INIT',
      date: '20 Mei 2024',
      time: '16:04',
      status: 'Rendah',
      score: 35,
      glucoseLevel: 'Kadar Gula: 98 mg/dL',
      scoreDescription: 'Skor Risiko: 35% • Kategori Rendah',
      recommendation: 'Pertahankan gaya hidup sehat Anda. Lanjutkan olahraga rutin dan pola makan seimbang.',
      bmi: '22.5 kg/m² (Normal)',
      bloodPressure: '120/80 mmHg',
      familyHistory: 'Tidak ada riwayat diabetes',
      physicalActivity: 'Aktif (4x / minggu)',
    ),
  );

  final ValueNotifier<List<PatientRiskRecord>> riskHistoryNotifier = ValueNotifier<List<PatientRiskRecord>>([]);

  final ValueNotifier<PatientConsultationActivity> latestConsultationNotifier = ValueNotifier<PatientConsultationActivity>(
    const PatientConsultationActivity(
      doctorName: 'dr. Koko',
      specialty: 'Spesialis Penyakit Dalam',
      date: '18 Mei 2026',
      time: '14:00',
      lastMessage: 'Konsultasi terakhir',
    ),
  );

  final ValueNotifier<List<MedicationReminder>> remindersNotifier = ValueNotifier<List<MedicationReminder>>([]);

  bool _isInitialized = false;

  void _initDefaultData() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Inisialisasi daftar riwayat risiko awal sesuai dengan data referensi
    final initialRecords = [
      const PatientRiskRecord(
        id: 'RSK-2026-001',
        date: '20 Mei 2024',
        time: '16:04',
        status: 'Rendah',
        score: 25,
        glucoseLevel: 'Kadar Gula: 98 mg/dL',
        scoreDescription: 'Skor Risiko: 8% • Kategori Rendah',
        recommendation: 'Pertahankan pola makan sehat, hidrasi cukup, dan olahraga rutin minimal 30 menit sehari.',
        bmi: '21.8 kg/m² (Ideal)',
        bloodPressure: '118/76 mmHg',
        familyHistory: 'Tidak ada riwayat diabetes',
        physicalActivity: 'Aktif (4x / minggu)',
      ),
      const PatientRiskRecord(
        id: 'RSK-2026-002',
        date: '14 Maret 2024',
        time: '09:15',
        status: 'Sedang',
        score: 52,
        glucoseLevel: 'Kadar Gula: 135 mg/dL',
        scoreDescription: 'Skor Risiko: 42% • Kategori Sedang',
        recommendation: 'Kurangi konsumsi gula dan karbohidrat sederhana. Perbanyak serat serta jadwalkan kontrol ulang.',
        bmi: '25.6 kg/m² (Kelebihan BB)',
        bloodPressure: '128/84 mmHg',
        familyHistory: 'Ada pada keluarga',
        physicalActivity: 'Jarang (1x / minggu)',
      ),
    ];
    riskHistoryNotifier.value = initialRecords;
    latestRiskNotifier.value = initialRecords.first;

    // Inisialisasi daftar pengingat obat awal (Metformin 19.00 sesuai tampilan awal)
    remindersNotifier.value = [
      MedicationReminder(
        id: 'rem-default-1',
        medicineName: 'Metformin',
        dosage: '500 mg (1 tablet)',
        schedule: 'Malam (Sesudah makan)',
        time: '19.00',
        isActive: true,
        isTakenToday: false,
        iconData: Icons.medication_rounded,
      ),
    ];

    // Coba sinkronisasi dari Firestore jika user login
    loadUserDataFromFirestore();
  }

  /// Memuat data pengguna dari Firestore jika telah login
  Future<void> loadUserDataFromFirestore() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;

        // 1. Cek latest risk assessment
        if (data['latestRiskStatus'] != null) {
          final status = data['latestRiskStatus'].toString();
          final score = (data['latestRiskScore'] as num?)?.toInt() ?? 25;
          final date = data['latestRiskDate']?.toString() ?? formatIndonesianDate(DateTime.now());
          final time = data['latestRiskTime']?.toString() ?? '10:00';

          latestRiskNotifier.value = PatientRiskRecord(
            id: 'RSK-SYNC',
            date: date,
            time: time,
            status: status,
            score: score,
            glucoseLevel: data['latestGlucoseLevel']?.toString() ?? 'Kadar Gula: -',
            scoreDescription: 'Skor Risiko: $score%',
            recommendation: data['latestRiskRecommendation']?.toString() ?? 'Pola hidup sehat',
          );
        }

        // 2. Cek latest consultation
        if (data['latestDoctorName'] != null) {
          latestConsultationNotifier.value = PatientConsultationActivity(
            doctorName: data['latestDoctorName'].toString(),
            specialty: data['latestDoctorSpecialty']?.toString() ?? 'Spesialis Penyakit Dalam',
            date: data['latestConsultationDate']?.toString() ?? 'Hari ini',
            time: data['latestConsultationTime']?.toString() ?? '14:00',
            lastMessage: data['latestConsultationMessage']?.toString() ?? 'Konsultasi selesai',
          );
        }
      }

      // 3. Muat daftar pengingat obat dari subcollection
      final remSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medication_reminders')
          .get();

      if (remSnapshot.docs.isNotEmpty) {
        final loadedReminders = remSnapshot.docs.map((doc) {
          return MedicationReminder.fromMap(doc.data());
        }).toList();
        remindersNotifier.value = loadedReminders;
      }

      // 4. Muat daftar riwayat risiko dari subcollection
      final riskSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('risk_assessments')
          .orderBy('timestamp', descending: true)
          .get();

      if (riskSnapshot.docs.isNotEmpty) {
        final loadedRisks = riskSnapshot.docs.map((doc) {
          return PatientRiskRecord.fromMap(doc.data());
        }).toList();
        riskHistoryNotifier.value = loadedRisks;
        latestRiskNotifier.value = loadedRisks.first;
      }
    } catch (e) {
      debugPrint('ℹ️ [PatientActivityService] Gagal load dari Firestore (menggunakan data lokal): $e');
    }
  }

  // ==========================================
  // METODE UNTUK CEK RISIKO / STATUS KESEHATAN
  // ==========================================

  /// Menyimpan hasil pengecekan risiko diabetes terbaru dari pengguna
  Future<void> recordRiskAssessment({
    required int score,
    required String status,
    required double weight,
    required double height,
    required double imt,
    required String imtCategory,
    required int age,
    required String gender,
    required bool familyHistory,
    required bool smokingHistory,
    required bool hypertensionHistory,
    required bool cardiovascularHistory,
  }) async {
    final now = DateTime.now();
    final dateStr = formatIndonesianDate(now);
    final timeStr = formatTime(now);

    final String recommendation;
    if (status.toLowerCase() == 'rendah') {
      recommendation = 'Pertahankan gaya hidup sehat Anda. Lanjutkan olahraga rutin dan pola makan seimbang.';
    } else if (status.toLowerCase() == 'sedang') {
      recommendation = 'Perhatikan asupan gula dan karbohidrat olahan. Tingkatkan aktivitas fisik dan pantau gula darah berkala.';
    } else {
      recommendation = 'Terdapat indikator risiko signifikan. Sangat disarankan berkonsultasi dengan dokter untuk cek gula darah.';
    }

    final newRecord = PatientRiskRecord(
      id: 'RSK-${now.millisecondsSinceEpoch}',
      date: dateStr,
      time: timeStr,
      status: status,
      score: score,
      glucoseLevel: 'Kadar Gula: Terkontrol',
      scoreDescription: 'Skor Risiko: $score% • Kategori $status',
      recommendation: recommendation,
      bmi: '${imt.toStringAsFixed(1)} kg/m² ($imtCategory)',
      bloodPressure: hypertensionHistory ? 'Tinggi' : 'Normal',
      familyHistory: familyHistory ? 'Ada' : 'Tidak Ada',
      physicalActivity: 'Terkoreksi AI',
      weight: weight,
      height: height,
      imt: imt,
      imtCategory: imtCategory,
      age: age,
      gender: gender,
    );

    // Update state reaktif lokal seketika
    latestRiskNotifier.value = newRecord;
    riskHistoryNotifier.value = [newRecord, ...riskHistoryNotifier.value];

    // Sinkronkan juga ke dummyRiskAssessments agar layar lain terupdate
    final newLevel = status.toLowerCase() == 'tinggi'
        ? RiskLevel.tinggi
        : (status.toLowerCase() == 'sedang' ? RiskLevel.sedang : RiskLevel.rendah);
    
    dummyRiskAssessments.insert(
      0,
      RiskAssessmentModel(
        id: newRecord.id,
        date: dateStr,
        time: timeStr,
        score: score,
        level: newLevel,
        factorsUsed: ['Usia', 'IMT', 'Riwayat Keluarga'],
        age: '$age tahun',
        diet: 'Normal',
        physicalActivity: 'Aktif',
        familyHistory: familyHistory ? 'Ada' : 'Tidak Ada',
        dominantFactors: [
          RiskDominantFactor(name: 'IMT', isHighlighted: imt >= 23),
          RiskDominantFactor(name: 'Usia', isHighlighted: age >= 45),
        ],
      ),
    );

    // Simpan ke Firestore jika user online
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'latestRiskStatus': status,
          'latestRiskScore': score,
          'latestRiskDate': dateStr,
          'latestRiskTime': timeStr,
          'latestRiskRecommendation': recommendation,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('risk_assessments')
            .doc(newRecord.id)
            .set(newRecord.toMap());
      } catch (e) {
        debugPrint('Error saving risk assessment to Firestore: $e');
      }
    }
  }

  // ==========================================
  // METODE UNTUK KONSULTASI DOKTER
  // ==========================================

  /// Memperbarui aktivitas konsultasi dokter terakhir
  Future<void> recordConsultation({
    required String doctorName,
    String specialty = 'Spesialis Penyakit Dalam',
    String? lastMessage,
    DateTime? timestamp,
  }) async {
    final now = timestamp ?? DateTime.now();
    final dateStr = formatIndonesianDate(now);
    final timeStr = formatTime(now);

    final activity = PatientConsultationActivity(
      doctorName: doctorName,
      specialty: specialty,
      date: dateStr,
      time: timeStr,
      lastMessage: lastMessage ?? 'Sesi konsultasi dokter',
    );

    latestConsultationNotifier.value = activity;

    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'latestDoctorName': doctorName,
          'latestDoctorSpecialty': specialty,
          'latestConsultationDate': dateStr,
          'latestConsultationTime': timeStr,
          'latestConsultationMessage': activity.lastMessage,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving consultation to Firestore: $e');
      }
    }
  }

  // ==========================================
  // METODE UNTUK PENGINGAT OBAT
  // ==========================================

  List<MedicationReminder> get reminders => remindersNotifier.value;

  /// Menambahkan jadwal pengingat obat baru
  Future<void> addReminder(MedicationReminder reminder) async {
    remindersNotifier.value = [reminder, ...remindersNotifier.value];
    _syncReminderToFirestore(reminder);
  }

  /// Menghapus jadwal pengingat obat
  Future<void> removeReminder(String id) async {
    remindersNotifier.value = remindersNotifier.value.where((r) => r.id != id).toList();
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medication_reminders')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('Error deleting reminder from Firestore: $e');
      }
    }
  }

  /// Mengaktifkan atau menonaktifkan pengingat obat
  Future<void> toggleReminderActive(String id, bool isActive) async {
    final updatedList = remindersNotifier.value.map((r) {
      if (r.id == id) {
        r.isActive = isActive;
      }
      return r;
    }).toList();
    remindersNotifier.value = updatedList;

    final rem = updatedList.firstWhere((r) => r.id == id);
    _syncReminderToFirestore(rem);
  }

  /// Mengubah status sudah diminum hari ini
  Future<void> toggleReminderTaken(String id, bool isTaken) async {
    final updatedList = remindersNotifier.value.map((r) {
      if (r.id == id) {
        r.isTakenToday = isTaken;
      }
      return r;
    }).toList();
    remindersNotifier.value = updatedList;

    final rem = updatedList.firstWhere((r) => r.id == id);
    _syncReminderToFirestore(rem);
  }

  /// Mengubah waktu jam pengingat obat
  Future<void> updateReminderTime(String id, String newTime) async {
    final updatedList = remindersNotifier.value.map((r) {
      if (r.id == id) {
        r.time = newTime;
      }
      return r;
    }).toList();
    remindersNotifier.value = updatedList;

    final rem = updatedList.firstWhere((r) => r.id == id);
    _syncReminderToFirestore(rem);
  }

  void _syncReminderToFirestore(MedicationReminder rem) async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('medication_reminders')
            .doc(rem.id)
            .set(rem.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error syncing reminder to Firestore: $e');
      }
    }
  }

  /// Menghitung jadwal pengingat obat berikutnya yang paling relevan untuk Dashboard
  NextReminderInfo getNextReminderInfo() {
    final activeReminders = remindersNotifier.value.where((r) => r.isActive).toList();

    if (activeReminders.isEmpty) {
      return const NextReminderInfo(
        reminder: null,
        timeText: '-',
        labelText: 'Belum diatur',
        subtitleText: 'Belum ada pengingat obat aktif',
        allTakenToday: false,
        hasActiveReminders: false,
      );
    }

    final untakenReminders = activeReminders.where((r) => !r.isTakenToday).toList();

    if (untakenReminders.isEmpty) {
      return const NextReminderInfo(
        reminder: null,
        timeText: 'Selesai',
        labelText: 'Semua diminum',
        subtitleText: 'Semua obat hari ini sudah diminum ✨',
        allTakenToday: true,
        hasActiveReminders: true,
      );
    }

    // Urutkan berdasarkan waktu jam
    untakenReminders.sort((a, b) {
      final aMinutes = _parseTimeToMinutes(a.time);
      final bMinutes = _parseTimeToMinutes(b.time);
      return aMinutes.compareTo(bMinutes);
    });

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;

    // Cari jadwal hari ini yang terdekat setelah jam sekarang
    MedicationReminder? nextRem = untakenReminders.firstWhere(
      (r) => _parseTimeToMinutes(r.time) >= currentMinutes,
      orElse: () => untakenReminders.first, // Jika semua sudah lewat, ambil yang pertama
    );

    final cleanTime = nextRem.time.replaceAll(':', '.');
    return NextReminderInfo(
      reminder: nextRem,
      timeText: cleanTime,
      labelText: 'Hari ini, $cleanTime',
      subtitleText: 'Pengingat obat berikutnya: $cleanTime',
      allTakenToday: false,
      hasActiveReminders: true,
    );
  }

  int _parseTimeToMinutes(String timeStr) {
    try {
      final clean = timeStr.trim().replaceAll('.', ':');
      final parts = clean.split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        return h * 60 + m;
      }
    } catch (_) {}
    return 0;
  }
}
