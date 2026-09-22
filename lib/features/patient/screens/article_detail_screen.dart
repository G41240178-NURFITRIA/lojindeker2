import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultation_list_screen.dart';

class EducationArticle {
  final String id;
  final String category;
  final String title;
  final String subtitle;
  final String readTime;
  final String reviewer;
  final Color imageBgColor;
  final Color categoryColor;
  final IconData iconData;
  final String summary;
  final List<String> keyPoints;
  final List<ArticleSection> sections;
  final List<String>? dos;
  final List<String>? donts;

  const EducationArticle({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.readTime,
    required this.reviewer,
    required this.imageBgColor,
    required this.categoryColor,
    required this.iconData,
    required this.summary,
    required this.keyPoints,
    required this.sections,
    this.dos,
    this.donts,
  });
}

class ArticleSection {
  final String title;
  final String content;
  final IconData? icon;

  const ArticleSection({
    required this.title,
    required this.content,
    this.icon,
  });
}

// Preset Artikel Edukasi
final List<EducationArticle> educationalArticles = [
  const EducationArticle(
    id: 'art-1',
    category: 'Pola Makan',
    title: 'Pola Makan Sehat Untuk Diabetes',
    subtitle: 'Tips Memilih Makanan Sehari-Hari Yang Aman Untuk Gula Darah',
    readTime: '4 menit baca',
    reviewer: 'dr. Siti Rahma, Sp.PD (Spesialis Penyakit Dalam)',
    imageBgColor: Color(0xFFFBE9E7),
    categoryColor: Color(0xFFB81018),
    iconData: Icons.restaurant_menu_rounded,
    summary:
        'Pola makan merupakan kunci utama dalam mengontrol kadar glukosa darah penderita diabetes. Menerapkan prinsip 3J (Jadwal, Jumlah, dan Jenis) membantu menjaga gula darah tetap stabil tanpa lonjakan drastis.',
    keyPoints: [
      'Pahami prinsip 3J: Jadwal makan tepat, Jumlah kalori sesuai, Jenis makanan rendah indeks glikemik.',
      'Gunakan metode "Piring Model T": 1/2 piring sayur, 1/4 protein rendah lemak, 1/4 karbohidrat kompleks.',
      'Hindari gula sederhana tersembunyi dalam minuman manis, saus olahan, dan camilan kemasan.',
    ],
    sections: [
      ArticleSection(
        title: '1. Mengenal Aturan 3J',
        content:
            '• Jadwal: Makan 3 kali makanan utama dan 2-3 kali selingan ringan pada jam yang sama setiap hari agar kerja insulin teratur.\n• Jumlah: Sesuaikan porsi dengan kebutuhan kalori dan aktivitas fisik Anda.\n• Jenis: Pilih karbohidrat kompleks berserat tinggi (beras merah, oatmeal, ubi jalar) dibandingkan karbohidrat sederhana (nasi putih berlebih, tepung terigu, gula pasir).',
        icon: Icons.access_time_rounded,
      ),
      ArticleSection(
        title: '2. Cara Menyusun Piring Makan Sehat',
        content:
            'Bayangkan piring makan Anda dibagi menjadi 4 bagian:\n- 1/2 Piring (50%): Sayuran segar atau kukus seperti bayam, brokoli, buncis, dan wortel.\n- 1/4 Piring (25%): Sumber protein bebas lemak seperti dada ayam tanpa kulit, ikan kembung/salmon, tahu, dan tempe.\n- 1/4 Piring (25%): Karbohidrat kompleks seperti nasi merah, jagung rebus, atau kentang kukus dengan kulitnya.',
        icon: Icons.pie_chart_rounded,
      ),
      ArticleSection(
        title: '3. Hidrasi dan Minuman yang Tepat',
        content:
            'Utamakan air putih minimal 2 liter per hari. Hindari jus buah dengan gula tambahan karena serat alami telah rusak dan memicu kenaikan gula darah mendadak. Teh hijau tanpa gula atau infused water lemon bisa menjadi alternatif sehat.',
        icon: Icons.water_drop_rounded,
      ),
    ],
    dos: [
      'Konsumsi sayuran berdaun hijau setiap hari',
      'Pilih buah utuh dengan indeks glikemik rendah (apel, pir, beri)',
      'Banyak minum air putih hangat setelah bangun tidur',
      'Baca label nutrisi informasi nilai gizi sebelum membeli produk',
    ],
    donts: [
      'Mengonsumsi teh manis kemasan, boba, atau soda',
      'Melewatkan sarapan yang berakibat makan berlebih di siang hari',
      'Mengonsumsi gorengan bertepung dan makanan cepat saji',
      'Menambahkan kecap manis atau saus olahan tinggi gula berlebih',
    ],
  ),
  const EducationArticle(
    id: 'art-2',
    category: 'Aktivitas Fisik',
    title: 'Olahraga Yang Aman Untuk Penderita Diabetes',
    subtitle: 'Jenis Olahraga Yang Aman Dan Bermanfaat Menjaga Gula Darah',
    readTime: '3 menit baca',
    reviewer: 'dr. Andi Pratama, Sp.KO (Spesialis Kedokteran Olahraga)',
    imageBgColor: Color(0xFFF3E5F5),
    categoryColor: Color(0xFF8E24AA),
    iconData: Icons.directions_run_rounded,
    summary:
        'Aktivitas fisik teratur meningkatkan sensitivitas insulin sehingga sel-sel tubuh lebih efektif menyerap glukosa dari peredaran darah. Ketahui jenis olahraga aman dan panduan proteksi diri selama berolahraga.',
    keyPoints: [
      'Lakukan olahraga aerobik intensitas sedang minimal 150 menit per minggu (30 menit, 5 hari seminggu).',
      'Selalu ukur kadar gula darah sebelum memulai latihan.',
      'Gunakan alas kaki yang pas dan empuk guna mencegah risiko luka pada telapak kaki.',
    ],
    sections: [
      ArticleSection(
        title: '1. Jenis Olahraga yang Sangat Dianjurkan',
        content:
            '• Jalan Cepat: Olahraga paling aman dan mudah dilakukan di sekitar lingkungan rumah.\n• Bersepeda Santai: Melatih kekuatan otot paha dan kardiovaskular dengan risiko benturan rendah.\n• Berenang: Sangat baik untuk penderita diabetes dengan masalah sendi atau kelebihan berat badan.\n• Senam Diabetes / Yoga: Melatih kelenturan, sirkulasi peredaran darah perifer, dan pernapasan.',
        icon: Icons.sports_gymnastics_rounded,
      ),
      ArticleSection(
        title: '2. Aturan Cek Gula Darah Sebelum Olahraga',
        content:
            '• < 100 mg/dL: Konsumsi camilan ringan berkabohidrat (misal: 1 buah pisang atau biskuit gandum) sebelum berolahraga.\n• 100 - 250 mg/dL: Zona aman dan ideal untuk mulai berolahraga.\n• > 250 mg/dL: Tunda olahraga berat dan periksa keberadaan keton dalam urine, karena olahraga justru bisa meningkatkan gula darah saat insulin kurang.',
        icon: Icons.health_and_safety_rounded,
      ),
      ArticleSection(
        title: '3. Perlindungan Kaki (Foot Care)',
        content:
            'Neuropati diabetik dapat menurunkan rasa nyeri di kaki. Selalu kenakan kaos kaki katun kering dan sepatu olahraga yang tidak sempit. Setelah selesai berolahraga, basuh kaki dan periksa apakah ada lecet atau memar sekecil apa pun.',
        icon: Icons.accessibility_rounded,
      ),
    ],
    dos: [
      'Pemanasan 5-10 menit sebelum mulai dan pendinginan setelahnya',
      'Bawa permen glukosa atau jus kotak kecil untuk antisipasi hipoglikemia',
      'Minum air secara berkala untuk mencegah dehidrasi',
      'Ajak teman atau beri tahu keluarga rute olahraga Anda',
    ],
    donts: [
      'Berolahraga tanpa alas kaki di permukaan keras atau panas',
      'Memaksakan berolahraga saat badan meriang atau demam',
      'Melakukan olahraga angkat beban yang memicu tekanan darah berlebih tanpa supervisi',
      'Mengabaikan rasa pusing, gemetar, atau keringat dingin tiba-tiba',
    ],
  ),
  const EducationArticle(
    id: 'art-3',
    category: 'Monitoring',
    title: 'Cara Memantau Gula Darah Di Rumah',
    subtitle: 'Panduan Mudah Memantau Gula Darah Secara Mandiri',
    readTime: '5 menit baca',
    reviewer: 'Ners Dewi Lestari, S.Kep (Edukator Diabetes Tersertifikasi)',
    imageBgColor: Color(0xFFEFEBE9),
    categoryColor: Color(0xFF6D4C41),
    iconData: Icons.monitor_heart_rounded,
    summary:
        'Pemantauan Mandiri Glukosa Darah (SMBG) memberikan gambaran nyata pengaruh makanan, aktivitas fisik, dan obat terhadap tubuh Anda, sehingga komplikasi diabetes dapat dicegah sedini mungkin.',
    keyPoints: [
      'Ketahui waktu ideal pemeriksaan: Gula Darah Puasa (GDP) dan Gula Darah 2 Jam Post-Prandial (GD2PP).',
      'Selalu cuci tangan bersih dengan air hangat dan sabun sebelum menusuk jari.',
      'Catat hasil setiap pengukuran di menu Riwayat pada aplikasi LojinDeker untuk dievaluasi dokter.',
    ],
    sections: [
      ArticleSection(
        title: '1. Kapan Waktu Terbaik Pengukuran?',
        content:
            '• Pagi Hari Saat Bangun (Puasa 8–10 jam): Mengukur efektivitas obat malam dan fungsi hati. Target normal: 80 - 130 mg/dL.\n• 2 Jam Setelah Makan Utama: Mengukur respons tubuh terhadap makanan yang baru dikonsumsi. Target: < 180 mg/dL.\n• Sebelum Tidur Malam: Menghindari bahaya hipoglikemia nokturnal saat terlelap. Target: 100 - 140 mg/dL.\n• Saat Merasa Tubuh Tidak Sehat: Terutama jika gemetar, berkeringat dingin, atau pandangan berputar.',
        icon: Icons.schedule_rounded,
      ),
      ArticleSection(
        title: '2. Prosedur Steril Penggunaan Glucometer',
        content:
            '1. Cuci tangan dengan air hangat dan sabun, lalu keringkan secara menyeluruh. Jangan gunakan alkohol secara berlebihan karena dapat mengencerkan sampel darah.\n2. Pasang strip uji ke alat glucometer yang menyala otomatis.\n3. Tusuk bagian samping ujung jari (bukan di bantalan tengah) untuk mengurangi rasa sakit.\n4. Biarkan darah menyentuh ujung strip uji hingga terdengar bunyi bip tanda pengukuran dimulai.\n5. Tekan jari dengan kapas bersih untuk menghentikan pendarahan.',
        icon: Icons.sanitizer_rounded,
      ),
      ArticleSection(
        title: '3. Langkah Jika Hasil Terlalu Rendah atau Tinggi',
        content:
            '• Jika < 70 mg/dL (Hipoglikemia): Segera terapkan aturan "Rule of 15": konsumsi 15 gram karbohidrat cepat serap (1/2 cangkir jus buah atau 3 butir permen manis), tunggu 15 menit, lalu cek kembali.\n• Jika > 250 mg/dL terus-menerus: Perbanyak minum air putih, cek dosis obat, dan segera hubungi tenaga medis atau kunjungi fasilitas kesehatan.',
        icon: Icons.warning_amber_rounded,
      ),
    ],
    dos: [
      'Ganti jarum lancet setiap kali pengambilan darah demi kebersihan dan ketajaman',
      'Simpan strip uji di wadah tertutup rapat terlindung dari sinar matahari langsung',
      'Catat makanan apa yang dikonsumsi sebelum lonjakan gula terjadi',
      'Bawa catatan gula darah saat kontrol rutin ke dokter',
    ],
    donts: [
      'Menggunakan strip uji yang sudah melewati tanggal kedaluwarsa',
      'Meminjamkan alat penusuk (lancing device) kepada orang lain',
      'Menekan jari terlalu keras hingga cairan jaringan mencemari darah',
      'Mengubah dosis obat insulin sendiri tanpa rekomendasi dokter',
    ],
  ),
];

class ArticleDetailScreen extends StatefulWidget {
  final EducationArticle article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  bool _isBookmarked = false;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final article = widget.article;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edukasi Kesehatan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: Colors.white,
            ),
            tooltip: 'Simpan Artikel',
            onPressed: () {
              setState(() => _isBookmarked = !_isBookmarked);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBookmarked ? 'Artikel disimpan ke favorit' : 'Artikel dihapus dari favorit',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFFB81018),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            tooltip: 'Bagikan Artikel',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Tautan artikel "${article.title}" siap dibagikan!',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFFD81B60),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: article.imageBgColor,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(article.iconData, color: article.categoryColor, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: article.categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: article.categoryColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF212121),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF757575)),
                      const SizedBox(width: 4),
                      Text(
                        article.readTime,
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF757575)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 4),
                      Text(
                        'Ditinjau Medis',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reviewer note card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEADBDB)),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(0xFFF9EAEB),
                          child: Icon(Icons.medical_services_rounded, color: Color(0xFFB81018), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Peninjau Medis:',
                                style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF757575)),
                              ),
                              Text(
                                article.reviewer,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF212121),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFD1A9)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lightbulb_rounded, color: Color(0xFFE65100), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Ringkasan Penting',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          article.summary,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF4E342E),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key takeaways
                  Text(
                    'Poin Utama',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...article.keyPoints.map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFB81018),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 10, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              point,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF424242),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Detailed Sections
                  Text(
                    'Panduan Praktis',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...article.sections.map(
                    (sec) => Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF0E4E4)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (sec.icon != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: article.categoryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(sec.icon, color: article.categoryColor, size: 18),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  sec.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF212121),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sec.content,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF555555),
                              height: 1.55,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Do's and Don'ts
                  if (article.dos != null && article.donts != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Yang Dianjurkan & Dihindari',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141414),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dos
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA5D6A7)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Dianjurkan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...article.dos!.map(
                                  (d) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• $d',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: const Color(0xFF1B5E20),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Don'ts
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEF9A9A)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.cancel_rounded, color: Color(0xFFC62828), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Hindari',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFC62828),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ...article.donts!.map(
                                  (dn) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      '• $dn',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10.5,
                                        color: const Color(0xFFB71C1C),
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),

                  // Bottom Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isCompleted = !_isCompleted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isCompleted
                                  ? 'Bagus! Anda telah menyelesaikan bacaan edukasi ini.'
                                  : 'Status selesai dibatalkan.',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                          ),
                        );
                      },
                      icon: Icon(
                        _isCompleted ? Icons.check_circle_rounded : Icons.task_alt_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _isCompleted ? 'Sudah Selesai Dibaca ✓' : 'Tandai Selesai Dibaca',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFB81018),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ConsultationListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_outlined, color: Color(0xFFB81018), size: 18),
                      label: Text(
                        'Konsultasikan Topik Ini ke Dokter',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB81018),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFB81018), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
