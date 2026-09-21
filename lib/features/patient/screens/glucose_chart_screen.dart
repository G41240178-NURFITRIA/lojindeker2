import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlucoseChartScreen extends StatefulWidget {
  const GlucoseChartScreen({super.key});

  @override
  State<GlucoseChartScreen> createState() => _GlucoseChartScreenState();
}

class _GlucoseChartScreenState extends State<GlucoseChartScreen> {
  int _selectedFilterIndex = 0; // 0: 7 Hari, 1: 30 Hari
  int _selectedTabIndex = 0;

  static const Color _primaryRed = Color(0xFFC62828);
  static const Color _darkRed = Color(0xFF8F0D12);
  static const Color _greenLine = Color(0xFF2E7D32);
  static const Color _yellowLine = Color(0xFFD4A017);

  // Data 7 Hari
  final List<String> _dates7 = ['17 Mei', '18 Mei', '19 Mei', 'Kmrn', 'Hr ini'];
  final List<double> _beforeMeal7 = [78, 85, 74, 70, 80];
  final List<double> _afterMeal7 = [95, 105, 98, 125, 136];

  // Data 30 Hari (Contoh tren)
  final List<String> _dates30 = ['Minggu 1', 'Minggu 2', 'Minggu 3', 'Minggu 4', 'Hr ini'];
  final List<double> _beforeMeal30 = [82, 79, 75, 72, 80];
  final List<double> _afterMeal30 = [110, 118, 112, 128, 136];

  @override
  Widget build(BuildContext context) {
    final dates = _selectedFilterIndex == 0 ? _dates7 : _dates30;
    final beforeMealData = _selectedFilterIndex == 0 ? _beforeMeal7 : _beforeMeal30;
    final afterMealData = _selectedFilterIndex == 0 ? _afterMeal7 : _afterMeal30;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Filter Pills: 7 Hari & 30 Hari
              _buildFilterPills(),
              const SizedBox(height: 14),

              // 2. Legend: Sebelum Makan (Hijau) & Setelah Makan (Kuning)
              _buildLegend(),
              const SizedBox(height: 16),

              // 3. Line Chart Canvas
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.only(right: 8, bottom: 4),
                child: CustomPaint(
                  painter: _GlucoseChartPainter(
                    dates: dates,
                    beforeMealData: beforeMealData,
                    afterMealData: afterMealData,
                    greenColor: _greenLine,
                    yellowColor: _yellowLine,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Tiga Card Ringkasan: Rata-rata, Tertinggi, Terendah
              _buildSummaryCards(),
              const SizedBox(height: 18),

              // 5. Box Catatan Kuning Muda: Analisis Tren
              _buildTrendAnalysisBox(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Header Merah dengan tombol kembali `<` dan judul "Grafik Monitoring GDA"
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primaryRed,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Grafik Monitoring GDA',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
    );
  }

  /// Toggle Filter 2 Pill: "7 Hari" & "30 Hari"
  Widget _buildFilterPills() {
    return Row(
      children: [
        _buildPillItem(
          label: '7 Hari',
          isSelected: _selectedFilterIndex == 0,
          onTap: () => setState(() => _selectedFilterIndex = 0),
        ),
        const SizedBox(width: 8),
        _buildPillItem(
          label: '30 Hari',
          isSelected: _selectedFilterIndex == 1,
          onTap: () => setState(() => _selectedFilterIndex = 1),
        ),
      ],
    );
  }

  Widget _buildPillItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? _darkRed : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _darkRed : _primaryRed,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF333333),
            ),
          ),
        ),
      ),
    );
  }

  /// Legend: Titik Hijau & Titik Kuning
  Widget _buildLegend() {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: _greenLine,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Sebelum Makan',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF424242),
          ),
        ),
        const SizedBox(width: 18),
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: _yellowLine,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Setelah Makan',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF424242),
          ),
        ),
      ],
    );
  }

  /// 3 Card Ringkasan: Rata-rata, Tertinggi, Terendah
  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            label: 'Rata rata',
            value: '128',
            valueColor: const Color(0xFF141414),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'Tertinggi',
            value: '185',
            valueColor: _primaryRed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            label: 'Terendah',
            value: '78',
            valueColor: _greenLine,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryRed, width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
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
              color: valueColor,
            ),
          ),
          Text(
            'mg/dL',
            style: GoogleFonts.poppins(
              fontSize: 9.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  /// Box Catatan Kuning Muda: Analisis Tren
  Widget _buildTrendAnalysisBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6), // Kuning pastel lembut
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 16,
                color: Color(0xFF8D6E00),
              ),
              const SizedBox(width: 6),
              Text(
                'Analisis Tren',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8D6E00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Gula darah setelah makan cenderung meningkat di 3 hari terakhir.\nPerhatikan porsi makan.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7A6000),
              height: 1.4,
            ),
          ),
        ],
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

/// CustomPainter untuk Grafik Garis Gula Darah (2 Garis & Reference Lines)
class _GlucoseChartPainter extends CustomPainter {
  final List<String> dates;
  final List<double> beforeMealData;
  final List<double> afterMealData;
  final Color greenColor;
  final Color yellowColor;

  _GlucoseChartPainter({
    required this.dates,
    required this.beforeMealData,
    required this.afterMealData,
    required this.greenColor,
    required this.yellowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 32.0;
    const bottomPadding = 24.0;
    const topPadding = 16.0;

    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding - topPadding;

    // Rentang nilai sumbu Y: 40 s/d 180
    const minY = 40.0;
    const maxY = 180.0;

    double getYPos(double value) {
      final normalized = (value - minY) / (maxY - minY);
      return size.height - bottomPadding - (normalized * chartHeight);
    }

    double getXPos(int index) {
      if (dates.length <= 1) return leftPadding;
      final step = (chartWidth - 20) / (dates.length - 1);
      return leftPadding + 10 + (index * step);
    }

    // 1. Sumbu X dan Y dasar
    final axisPaint = Paint()
      ..color = const Color(0xFFE8D5D5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Sumbu Y
    canvas.drawLine(
      const Offset(leftPadding, topPadding),
      Offset(leftPadding, size.height - bottomPadding),
      axisPaint,
    );

    // Sumbu X
    canvas.drawLine(
      Offset(leftPadding, size.height - bottomPadding),
      Offset(size.width, size.height - bottomPadding),
      axisPaint,
    );

    // 2. Garis Target Referensi Dashed (140 dan 80)
    _drawReferenceLine(
      canvas: canvas,
      yPos: getYPos(140),
      label: '140',
      labelColor: yellowColor,
      startX: leftPadding,
      endX: size.width,
    );

    _drawReferenceLine(
      canvas: canvas,
      yPos: getYPos(80),
      label: '80',
      labelColor: greenColor,
      startX: leftPadding,
      endX: size.width,
    );

    // 3. Gambar Garis Kuning (Setelah Makan)
    _drawLineSeries(
      canvas: canvas,
      data: afterMealData,
      color: yellowColor,
      getXPos: getXPos,
      getYPos: getYPos,
    );

    // 4. Gambar Garis Hijau (Sebelum Makan)
    _drawLineSeries(
      canvas: canvas,
      data: beforeMealData,
      color: greenColor,
      getXPos: getXPos,
      getYPos: getYPos,
    );

    // 5. Label Sumbu X (Tanggal)
    final textStyle = GoogleFonts.poppins(
      fontSize: 10,
      color: const Color(0xFF888888),
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < dates.length; i++) {
      final textSpan = TextSpan(text: dates[i], style: textStyle);
      final tp = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      final x = getXPos(i) - (tp.width / 2);
      final y = size.height - bottomPadding + 6;
      tp.paint(canvas, Offset(x, y));
    }
  }

  void _drawReferenceLine({
    required Canvas canvas,
    required double yPos,
    required String label,
    required Color labelColor,
    required double startX,
    required double endX,
  }) {
    // Label teks di kiri
    final textSpan = TextSpan(
      text: label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: labelColor,
      ),
    );
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(2, yPos - (tp.height / 2)));

    // Garis putus-putus
    final dashPaint = Paint()
      ..color = const Color(0xFFDCD0D0)
      ..strokeWidth = 1.0;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double curX = startX;

    while (curX < endX) {
      canvas.drawLine(
        Offset(curX, yPos),
        Offset(curX + dashWidth, yPos),
        dashPaint,
      );
      curX += dashWidth + dashSpace;
    }
  }

  void _drawLineSeries({
    required Canvas canvas,
    required List<double> data,
    required Color color,
    required double Function(int) getXPos,
    required double Function(double) getYPos,
  }) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = getXPos(i);
      final y = getYPos(data[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Titik node lingkaran
    for (int i = 0; i < data.length; i++) {
      final x = getXPos(i);
      final y = getYPos(data[i]);
      // Node terakhir sedikit lebih besar
      final radius = (i == data.length - 1) ? 5.5 : 4.5;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlucoseChartPainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.beforeMealData != beforeMealData ||
        oldDelegate.afterMealData != afterMealData;
  }
}
