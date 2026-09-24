import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glucose_chart_screen.dart';
import 'risk_check_screen.dart';

class GlucoseHistoryScreen extends StatefulWidget {
  const GlucoseHistoryScreen({super.key});

  @override
  State<GlucoseHistoryScreen> createState() => _GlucoseHistoryScreenState();
}

class _GlucoseHistoryScreenState extends State<GlucoseHistoryScreen> {
  int _selectedTabIndex = 0;
  int _activePillIndex = 2; // Default: 'Monitoring' aktif

  static const Color _primaryRed = Color(0xFFC62828);
  static const Color _darkRed = Color(0xFF8F0D12);
  static const Color _greenDot = Color(0xFF1B5E20);
  static const Color _orangeDot = Color(0xFFE65100);

  final List<String> _pillTitles = [
    'Cek Risiko AI',
    'Konsultasi',
    'Monitoring',
    'Resep',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 4 Tab Pill di Bawah Header
              _buildPillTabs(),
              const SizedBox(height: 18),

              // 2. Card Putih "Ringkasan 7 Hari Terakhir"
              _buildSummaryCard(),
              const SizedBox(height: 20),

              // 3. Riwayat: Hari Ini
              _buildSectionTitle('Hari Ini'),
              const SizedBox(height: 8),
              _buildHistoryGroupCard([
                _HistoryItemData(
                  dotColor: _greenDot,
                  time: '07.30',
                  label: 'Sebelum makan',
                  value: '112',
                ),
                _HistoryItemData(
                  dotColor: _orangeDot,
                  time: '20.15',
                  label: '2 Jam Setelah Makan',
                  value: '136',
                ),
              ]),
              const SizedBox(height: 18),

              // 4. Riwayat: Kemarin
              _buildSectionTitle('Kemarin'),
              const SizedBox(height: 8),
              _buildHistoryGroupCard([
                _HistoryItemData(
                  dotColor: _greenDot,
                  time: '07.45',
                  label: 'Sebelum makan',
                  value: '105',
                ),
                _HistoryItemData(
                  dotColor: _orangeDot,
                  time: '19.30',
                  label: '2 Jam Setelah Makan',
                  value: '142',
                ),
              ]),
              const SizedBox(height: 18),

              // 5. Riwayat: 17 Mei 2024
              _buildSectionTitle('17 Mei 2024'),
              const SizedBox(height: 8),
              _buildHistoryGroupCard([
                _HistoryItemData(
                  dotColor: _greenDot,
                  time: '07.20',
                  label: 'Sebelum makan',
                  value: '98',
                ),
                _HistoryItemData(
                  dotColor: _greenDot,
                  time: '19.10',
                  label: '2 Jam Setelah Makan',
                  value: '125',
                ),
              ]),
              const SizedBox(height: 24),

              // 6. Tombol Outline Merah: Lihat Grafik
              _buildViewChartButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Header Merah dengan tombol back dan judul "Riwayat Monitoring Gula Darah"
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryRed,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 70,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Riwayat Monitoring Gula\nDarah',
        style: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.25,
        ),
      ),
      centerTitle: false,
    );
  }

  /// 4 Tab Pill: Cek Risiko AI, Konsultasi, Monitoring, Resep
  Widget _buildPillTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_pillTitles.length, (index) {
          final isSelected = _activePillIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() => _activePillIndex = index);
                  if (index == 0) {
                    // Jika klik Cek Risiko AI, buka RiskCheckScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiskCheckScreen(),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? _darkRed : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? _darkRed : _primaryRed,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _pillTitles[index],
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Card Putih Border Merah: "Ringkasan 7 Hari Terakhir"
  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryRed, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan 7 Hari Terakhir',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInnerSummaryPill(
                  label: 'Rata rata',
                  value: '',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInnerSummaryPill(
                  label: 'Tertinggi',
                  value: '',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInnerSummaryPill(
                  label: 'Terendah',
                  value: '',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInnerSummaryPill({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _primaryRed, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF141414),
            ),
          ),
          Text(
            'mg/dL',
            style: GoogleFonts.poppins(
              fontSize: 9,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  /// Judul Seksi Tanggal
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF222222),
      ),
    );
  }

  /// Card Kelompok Riwayat
  Widget _buildHistoryGroupCard(List<_HistoryItemData> items) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryRed, width: 1),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    // Dot Bullet
                    Container(
                      width: 8.5,
                      height: 8.5,
                      decoration: BoxDecoration(
                        color: item.dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Waktu
                    SizedBox(
                      width: 48,
                      child: Text(
                        item.time,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF222222),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Keterangan
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ),

                    // Nilai mg/dL
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.value,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF141414),
                          ),
                        ),
                        Text(
                          'mg/dL',
                          style: GoogleFonts.poppins(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF757575),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  thickness: 0.8,
                  color: _primaryRed.withValues(alpha: 0.4),
                ),
            ],
          );
        }),
      ),
    );
  }

  /// Tombol Outline Merah Rounded: "Lihat Grafik" -> Navigasi ke Halaman 2
  Widget _buildViewChartButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const GlucoseChartScreen(),
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _primaryRed, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
        ),
        child: Text(
          'Lihat Grafik',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _primaryRed,
          ),
        ),
      ),
    );
  }

  /// Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 62,
      color: const Color(0xFFFAF1F1),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined),
          _buildNavItem(1, Icons.chat_bubble_outline_rounded),
          _buildNavItem(2, Icons.person_outline_rounded),
          _buildNavItem(3, Icons.calendar_month_outlined),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    final isSelected = _selectedTabIndex == index;
    final color = isSelected ? const Color(0xFFBA171E) : const Color(0xFFD65C62);

    return InkWell(
      onTap: () {
        setState(() => _selectedTabIndex = index);
        if (index == 0) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 24,
          color: color,
        ),
      ),
    );
  }
}

class _HistoryItemData {
  final Color dotColor;
  final String time;
  final String label;
  final String value;

  _HistoryItemData({
    required this.dotColor,
    required this.time,
    required this.label,
    required this.value,
  });
}
