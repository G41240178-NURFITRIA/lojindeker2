import 'package:flutter/material.dart';

/// Primary brand colors for the risk assessment feature
class RiskColors {
  static const Color maroonPrimary = Color(0xFF7A1F2B);
  static const Color maroonDark = Color(0xFF5A141E);
  static const Color cardBorderPink = Color(0xFFF4B8BC);
  static const Color scaffoldBg = Color(0xFFFAF1F1);
  static const Color textDark = Color(0xFF1E1E1E);
  static const Color textMuted = Color(0xFF757575);
  static const Color infoBannerBg = Color(0xFFEBF5FE);
  static const Color infoBannerBorder = Color(0xFFBAE0FD);
  static const Color infoBannerText = Color(0xFF0369A1);
}

/// Kategori tingkat risiko diabetes
enum RiskLevel {
  rendah,
  sedang,
  tinggi,
}

/// Helper extension untuk warna, label, dan rekomendasi berdasarkan tingkat risiko
extension RiskLevelExtension on RiskLevel {
  String get label {
    switch (this) {
      case RiskLevel.rendah:
        return 'Rendah';
      case RiskLevel.sedang:
        return 'Sedang';
      case RiskLevel.tinggi:
        return 'Tinggi';
    }
  }

  /// Warna utama teks & angka skor
  Color get color {
    switch (this) {
      case RiskLevel.rendah:
        return const Color(0xFF1E8E3E); // Hijau segar
      case RiskLevel.sedang:
        return const Color(0xFFD97706); // Kuning / Amber
      case RiskLevel.tinggi:
        return const Color(0xFFDC2626); // Merah tegas
    }
  }

  /// Warna background badge / chip
  Color get badgeBgColor {
    switch (this) {
      case RiskLevel.rendah:
        return const Color(0xFFE8F8EE);
      case RiskLevel.sedang:
        return const Color(0xFFFEF9C3);
      case RiskLevel.tinggi:
        return const Color(0xFFFEE2E2);
    }
  }

  /// Warna border badge / chip
  Color get badgeBorderColor {
    switch (this) {
      case RiskLevel.rendah:
        return const Color(0xFFA6E9BC);
      case RiskLevel.sedang:
        return const Color(0xFFFDE047);
      case RiskLevel.tinggi:
        return const Color(0xFFFECACA);
    }
  }

  /// Background kontainer rekomendasi
  Color get recommendationBgColor {
    switch (this) {
      case RiskLevel.rendah:
        return const Color(0xFFE8F8EE);
      case RiskLevel.sedang:
        return const Color(0xFFFFFBEB);
      case RiskLevel.tinggi:
        return const Color(0xFFFEF2F2);
    }
  }

  /// Border kontainer rekomendasi
  Color get recommendationBorderColor {
    switch (this) {
      case RiskLevel.rendah:
        return const Color(0xFFA7F3D0);
      case RiskLevel.sedang:
        return const Color(0xFFFDE68A);
      case RiskLevel.tinggi:
        return const Color(0xFFFECACA);
    }
  }

  /// Icon rekomendasi
  IconData get recommendationIcon {
    switch (this) {
      case RiskLevel.rendah:
        return Icons.check_circle_rounded;
      case RiskLevel.sedang:
        return Icons.warning_amber_rounded;
      case RiskLevel.tinggi:
        return Icons.warning_amber_rounded;
    }
  }

  /// Teks rekomendasi berdasarkan spesifikasi
  String get recommendationText {
    switch (this) {
      case RiskLevel.rendah:
        return 'Risiko Anda tergolong rendah. Pertahankan pola makan dan aktivitas fisik yang sudah baik.';
      case RiskLevel.sedang:
        return 'Risiko Anda sedang. Perbaiki pola makan dan tingkatkan aktivitas fisik secara bertahap untuk mengurangi risiko.';
      case RiskLevel.tinggi:
        return 'Risiko Anda tergolong tinggi. Disegerakan untuk konsultasi dengan dokter untuk pemeriksaan lebih lanjut.';
    }
  }
}

/// Model untuk faktor risiko dominan yang dapat memiliki status highlight
class RiskDominantFactor {
  final String name;
  final bool isHighlighted;

  const RiskDominantFactor({
    required this.name,
    required this.isHighlighted,
  });
}

/// Model data rekam pemeriksaan risiko AI (dinamis dan reusable)
class RiskAssessmentModel {
  final String id;
  final String date;
  final String time;
  final int score;
  final RiskLevel level;
  final List<String> factorsUsed;

  // Data input detail tabel
  final String age;
  final String diet;
  final String physicalActivity;
  final String familyHistory;
  final List<RiskDominantFactor> dominantFactors;

  const RiskAssessmentModel({
    required this.id,
    required this.date,
    required this.time,
    required this.score,
    required this.level,
    required this.factorsUsed,
    required this.age,
    required this.diet,
    required this.physicalActivity,
    required this.familyHistory,
    required this.dominantFactors,
  });

  String get dateTimeString => '$date, $time';
  String get formattedFactors => factorsUsed.join(', ');
}

/// Data dummy sesuai spesifikasi Figma dan prompt
final List<RiskAssessmentModel> dummyRiskAssessments = [
  const RiskAssessmentModel(
    id: 'risk_001',
    date: '20 Mei 2024',
    time: '16:04',
    score: 35,
    level: RiskLevel.rendah,
    factorsUsed: ['Usia', 'Pola Makan', 'Aktivitas Fisik'],
    age: '25 tahun',
    diet: 'Sehat',
    physicalActivity: 'Tinggi (5x/minggu)',
    familyHistory: 'Tidak Ada',
    dominantFactors: [
      RiskDominantFactor(name: 'Usia', isHighlighted: false),
      RiskDominantFactor(name: 'Pola Makan', isHighlighted: false),
    ],
  ),
  const RiskAssessmentModel(
    id: 'risk_002',
    date: '10 Februari 2024',
    time: '09:15',
    score: 58,
    level: RiskLevel.sedang,
    factorsUsed: ['Usia', 'Pola Makan', 'Riwayat Keluarga'],
    age: '38 tahun',
    diet: 'Cukup Sehat',
    physicalActivity: 'Sedang (2-3x/minggu)',
    familyHistory: 'Ada (Saudara Kandung)',
    dominantFactors: [
      RiskDominantFactor(name: 'Riwayat Keluarga', isHighlighted: true),
      RiskDominantFactor(name: 'Pola Makan', isHighlighted: false),
    ],
  ),
  const RiskAssessmentModel(
    id: 'risk_003',
    date: '5 November 2023',
    time: '09:15',
    score: 72,
    level: RiskLevel.tinggi,
    factorsUsed: ['Usia', 'Pola Makan', 'Aktivitas Fisik', 'Riwayat Keluarga'],
    age: '47 tahun',
    diet: 'Kurang Sehat',
    physicalActivity: 'Rendah (<1x/minggu)',
    familyHistory: 'Ada (Kedua Orang Tua)',
    dominantFactors: [
      RiskDominantFactor(name: 'Pola Makan', isHighlighted: true),
      RiskDominantFactor(name: 'Aktivitas Fisik', isHighlighted: true),
    ],
  ),
];
