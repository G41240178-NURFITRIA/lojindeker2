import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WhenToSeeDoctorScreen extends StatelessWidget {
  const WhenToSeeDoctorScreen({super.key});

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
                'Kenali gejala yang perlu penanganan medis agar kondisi tidak semakin memburuk',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: const Color(0xFF616161),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              _buildSymptomCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Gula Darah Sangat Tinggi',
                description:
                    'Gula darah > 250 mg/dL disertai gejala seperti haus, sering buang air kecil, lemas, atau mual.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFF1E88E5),
                iconBgColor: const Color(0xFFE3F2FD),
                title: 'Gula Darah Sangat Rendah',
                description:
                    'Gula darah < 70 mg/dL disertai keringat dingin, gemetar, pusing, atau kebingungan.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Nyeri Dada',
                description:
                    'Nyeri atau tekanan di dada yang dapat menjalar ke lengan, leher, atau rahang.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                icon: Icons.air_rounded,
                iconColor: const Color(0xFF43A047),
                iconBgColor: const Color(0xFFE8F5E9),
                title: 'Sesak Nafas',
                description:
                    'Napas terasa berat atau terengah-engah tanpa aktivitas berat.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                icon: Icons.healing_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Luka Tidak Kunjung Sembuh',
                description:
                    'Luka pada kaki atau bagian tubuh lain yang tidak sembuh lebih dari 1–2 minggu.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                icon: Icons.visibility_rounded,
                iconColor: const Color(0xFF8E24AA),
                iconBgColor: const Color(0xFFF3E5F5),
                title: 'Penglihatan Kabur Mendadak',
                description:
                    'Penglihatan kabur tiba-tiba atau hilang penglihatan sementara.',
              ),
              const SizedBox(height: 12),

              _buildSymptomCard(
                icon: Icons.accessibility_new_rounded,
                iconColor: const Color(0xFFE53935),
                iconBgColor: const Color(0xFFFDEDED),
                title: 'Pembengkakan Pada Kaki',
                description:
                    'Kaki bengkak, kemerahan, atau terasa hangat dan nyeri.',
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
                        'Jika Anda mengalami salah satu gejala di atas, segera hubungi tenaga kesehatan atau kunjungi fasilitas kesehatan terdekat.',
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSymptomCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String description,
  }) {
    return Container(
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
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB81018),
                  ),
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
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 64,
      color: const Color(0xFFFAF1F1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined),
          _buildNavItem(Icons.chat_bubble_outline_rounded),
          _buildNavItem(Icons.person_outline_rounded),
          _buildNavItem(Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon) {
    return InkWell(
      onTap: () {},
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
