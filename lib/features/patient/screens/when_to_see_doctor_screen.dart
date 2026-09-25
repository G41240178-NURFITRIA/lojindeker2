import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultation_list_screen.dart';
import 'medical_records_screen.dart';
import 'riwayat_resep_screen.dart';

class WhenToSeeDoctorScreen extends StatelessWidget {
  const WhenToSeeDoctorScreen({super.key});

  void _showSymptomDetail(
    BuildContext context, {
    required String title,
    required String description,
    required String emergencyAction,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFB81018),
                          ),
                        ),
                        Text(
                          'Panduan Tanggap Darurat Medis',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              Text(
                'Deskripsi Gejala:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF424242),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF616161), height: 1.5),
              ),
              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.emergency_rounded, color: Color(0xFFE65100), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tindakan Segera Yang Harus Dilakukan:',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            emergencyAction,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF5D4037),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 18),
                  label: Text(
                    'Hubungi Dokter Terkait Gejala Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB81018),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB81018),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kapan Harus Ke Dokter?',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kenali gejala yang perlu penanganan medis segera. Tekan kartu gejala untuk melihat tindakan pertolongan pertama.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF616161),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              _buildSymptomCard(
                context: context,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Gula Darah Sangat Tinggi',
                description:
                    'Gula darah > 250 mg/dL disertai gejala seperti haus berlebih, sering buang air kecil, lemas, mual, atau napas berbau buah.',
                emergencyAction:
                    'Minum air putih banyak tanpa gula. Jangan makan makanan tinggi karbohidrat. Jika menggunakan insulin, periksa dosis koreksi dokter. Segera ke IGD jika timbul muntah atau sesak.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                context: context,
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFF1E88E5),
                iconBgColor: const Color(0xFFE3F2FD),
                title: 'Gula Darah Sangat Rendah',
                description:
                    'Gula darah < 70 mg/dL disertai keringat dingin, gemetar hebat, jantung berdebar, pusing, atau pandangan berbayang.',
                emergencyAction:
                    'Terapkan "Rule of 15": Minum 1/2 gelas jus buah manis atau 3 butir permen manis segera. Istirahat dan cek kembali gula darah dalam 15 menit. Ulangi bila belum mencapai 100 mg/dL.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                context: context,
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Nyeri Dada',
                description:
                    'Nyeri, rasa ditekan beban berat di dada yang dapat menjalar ke lengan kiri, leher, atau rahang.',
                emergencyAction:
                    'Segera hentikan seluruh aktivitas, duduk dengan posisi nyaman dan bernapas perlahan. Segera hubungi ambulans (119) atau minta antar ke IGD rumah sakit terdekat.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                context: context,
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF43A047),
                iconBgColor: const Color(0xFFE8F5E9),
                title: 'Sesak Nafas',
                description:
                    'Napas terasa berat, terengah-engah, atau tersengal-sengal tanpa melakukan aktivitas fisik berat.',
                emergencyAction:
                    'Duduk tegak, longgarkan pakaian yang ketat, dan hirup udara segar. Bila sesak disertai batuk atau bengkak, segera konsultasi ke dokter spesialis paru/jantung.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                context: context,
                icon: Icons.healing_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Luka Tidak Kunjung Sembuh',
                description:
                    'Luka lecet atau goresan pada kaki atau bagian tubuh lain yang basah, bernanah, atau tidak kunjung membaik lebih dari 1–2 minggu.',
                emergencyAction:
                    'Cuci dengan cairan infus NaCl steril, jangan beri ramuan tradisional atau alkohol keras. Keringkan dan balut dengan kasa steril. Segera konsultasikan ke klinik perawatan luka diabetes.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                context: context,
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF8E24AA),
                iconBgColor: const Color(0xFFF3E5F5),
                title: 'Penglihatan Kabur Mendadak',
                description:
                    'Penglihatan buram mendadak, tampak bintik hitam mengambang (floaters), atau kehilangan lapang pandang sementara.',
                emergencyAction:
                    'Ukur kadar gula darah saat itu juga. Hindari mengemudi atau aktivitas yang membutuhkan ketajaman mata. Segera buat janji temu dengan dokter spesialis mata (oftalmologi).',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                context: context,
                icon: Icons.accessibility_new_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Pembengkakan Pada Kaki',
                description:
                    'Kaki bengkak, berubah warna kemerahan atau kebiruan, kulit terasa panas saat disentuh, atau timbul mati rasa.',
                emergencyAction:
                    'Tinggikan posisi kaki saat berbaring. Periksa telapak kaki apakah ada tertusuk duri/benda asing yang tidak terasa karena neuropati. Kunjungi dokter untuk evaluasi sirkulasi dan fungsi ginjal.',
              ),
              const SizedBox(height: 24),

              // Warning box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC02), width: 1.5),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF9A825),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Jika Anda mengalami salah satu gejala di atas, jangan menunda. Segera hubungi tenaga kesehatan atau kunjungi fasilitas kesehatan terdekat.',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF5D4037),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emergency / Fast Consultation Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                  label: Text(
                    'Konsultasi Dokter Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB81018),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildSymptomCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
    required String emergencyAction,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSymptomDetail(
          context,
          title: title,
          description: description,
          emergencyAction: emergencyAction,
          icon: icon,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF0E0E0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB81018),
                            ),
                          ),
                        ),
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB81018)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF616161),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      height: 64,
      color: const Color(0xFFFAF1F1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            icon: Icons.home_outlined,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          _buildNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConsultationListScreen(),
                ),
              );
            },
          ),
          _buildNavItem(
            icon: Icons.person_outline_rounded,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 26,
          color: const Color(0xFFD65C62),
        ),
      ),
    );
  }
}
