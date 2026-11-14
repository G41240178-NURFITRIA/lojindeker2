import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

/// Hasil prediksi Naive Bayes.
class HasilPrediksi {
  final String kelas;                       // label kelas dengan probabilitas tertinggi
  final Map<String, double> probabilitas;   // 0.0 - 1.0 untuk tiap kelas
  final bool berisiko;                      // true jika kelas = Diabetes Melitus Tipe 2

  HasilPrediksi(this.kelas, this.probabilitas, this.berisiko);

  double get probabilitasDiabetes =>
      probabilitas['Diabetes Melitus Tipe 2'] ?? 0.0;
}

/// Categorical Naive Bayes yang parameternya dibaca dari model_nb_dcare.json
/// (hasil training di Google Colab).
class NaiveBayesModel {
  final List<String> fitur;
  final Map<String, List<String>> kategori;
  final List<String> kelas;
  final List<double> logPrior;
  final Map<String, List<List<double>>> logLikelihood; // [fitur][kelas][kategori]
  final List<int> batasUsia;
  final List<String> labelUsia;

  NaiveBayesModel._(this.fitur, this.kategori, this.kelas, this.logPrior,
      this.logLikelihood, this.batasUsia, this.labelUsia);

  static Future<NaiveBayesModel> muat(
      [String path = 'assets/model_nb_dcare.json']) async {
    final j = jsonDecode(await rootBundle.loadString(path))
        as Map<String, dynamic>;

    List<double> toD(List l) => l.map((e) => (e as num).toDouble()).toList();

    final ll = <String, List<List<double>>>{};
    (j['log_likelihood'] as Map<String, dynamic>).forEach((k, v) {
      ll[k] = (v as List).map((row) => toD(row as List)).toList();
    });

    final kat = <String, List<String>>{};
    (j['kategori'] as Map<String, dynamic>).forEach((k, v) {
      kat[k] = List<String>.from(v as List);
    });

    return NaiveBayesModel._(
      List<String>.from(j['fitur'] as List),
      kat,
      List<String>.from(j['kelas'] as List),
      toD(j['log_prior'] as List),
      ll,
      List<int>.from((j['batas_usia']['batas'] as List)),
      List<String>.from((j['batas_usia']['label'] as List)),
    );
  }

  /// [input] berisi kategori (bukan angka) dengan nama kunci persis seperti di
  /// `fitur`, misalnya {'JK': 'Perempuan', 'Usia': '35-49', 'IMT': 'Normal', ...}
  HasilPrediksi prediksi(Map<String, String> input) {
    final skor = List<double>.from(logPrior);

    for (final f in fitur) {
      final nilai = input[f];
      if (nilai == null) {
        throw ArgumentError('Isian "$f" belum diisi');
      }
      final k = kategori[f]!.indexOf(nilai);
      if (k < 0) {
        throw ArgumentError('Nilai "$nilai" tidak dikenal untuk "$f"');
      }
      for (var c = 0; c < skor.length; c++) {
        skor[c] += logLikelihood[f]![c][k];
      }
    }

    // Normalisasi dengan trik log-sum-exp agar stabil
    final maks = skor.reduce(math.max);
    final eksp = skor.map((s) => math.exp(s - maks)).toList();
    final total = eksp.reduce((a, b) => a + b);
    final prob = eksp.map((e) => e / total).toList();

    var idx = 0;
    for (var i = 1; i < prob.length; i++) {
      if (prob[i] > prob[idx]) idx = i;
    }

    final peta = <String, double>{
      for (var i = 0; i < kelas.length; i++) kelas[i]: prob[i],
    };
    return HasilPrediksi(
        kelas[idx], peta, kelas[idx] == 'Diabetes Melitus Tipe 2');
  }

  /// Umur (tahun) -> kelompok umur sesuai batas di JSON.
  String kelompokUsia(int umur) {
    for (var i = 0; i < batasUsia.length; i++) {
      if (umur < batasUsia[i]) return labelUsia[i];
    }
    return labelUsia.last;
  }
}
