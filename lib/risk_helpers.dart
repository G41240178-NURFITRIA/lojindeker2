/// IMT = BB / (TB dalam meter)^2, lalu diubah ke kategori yang ada di dataset.
/// Batas harus sama dengan di notebook Colab (standar Asia-Pasifik).
class HasilImt {
  final double nilai;
  final String kategori;
  HasilImt(this.nilai, this.kategori);
}

HasilImt hitungImt(double bbKg, double tbCm) {
  if (bbKg <= 0 || tbCm <= 0) {
    throw ArgumentError('Berat dan tinggi badan harus lebih dari 0');
  }
  final m = tbCm / 100;
  final imt = bbKg / (m * m);
  String kat;
  if (imt < 23) {
    kat = 'Normal';
  } else if (imt < 25) {
    kat = 'Beresiko';
  } else if (imt < 30) {
    kat = 'Obes 1';
  } else {
    kat = 'Obes 2';
  }
  return HasilImt(double.parse(imt.toStringAsFixed(1)), kat);
}

/// Umur asli (tahun penuh) dari tanggal lahir.
int hitungUsia(DateTime lahir, [DateTime? hariIni]) {
  final now = hariIni ?? DateTime.now();
  var umur = now.year - lahir.year;
  if (now.month < lahir.month ||
      (now.month == lahir.month && now.day < lahir.day)) {
    umur--;
  }
  return umur;
}

/// Pilihan Ya/Tidak di form -> label dataset.
String yaTidak(bool ya) => ya ? 'Iya' : 'Tidak';

/// Pilihan jenis kelamin di form -> label dataset.
/// PENTING: di dataset penulisannya 'Laki - Laki' (dengan spasi).
String labelJk(bool lakiLaki) => lakiLaki ? 'Laki - Laki' : 'Perempuan';
