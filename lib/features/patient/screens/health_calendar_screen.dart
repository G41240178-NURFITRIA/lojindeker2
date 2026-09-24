import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'consultation_list_screen.dart';
import 'medication_reminder_screen.dart';

enum HealthEventType {
  doctorAppointment,
  medication,
  bloodSugarCheck,
  labTest,
}

class HealthEvent {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final DateTime date;
  final HealthEventType type;
  final String location;
  final String doctorName;
  bool isCompleted;

  HealthEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.date,
    required this.type,
    this.location = '',
    this.doctorName = '',
    this.isCompleted = false,
  });
}

class HealthCalendarScreen extends StatefulWidget {
  const HealthCalendarScreen({super.key});

  @override
  State<HealthCalendarScreen> createState() => _HealthCalendarScreenState();
}

class _HealthCalendarScreenState extends State<HealthCalendarScreen> {
  static const Color _primaryPink = Color(0xFFF06292);
  static const Color _darkRose = Color(0xFFD81B60);
  static const Color _maroon = Color(0xFFB81018);

  late DateTime _selectedDate;
  late DateTime _currentMonth;
  String _selectedFilter = 'Semua';

  late List<HealthEvent> _events;

  final List<String> _filters = ['Semua', 'Kontrol Dokter', 'Minum Obat', 'Cek Gula'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _currentMonth = DateTime(now.year, now.month, 1);

    _events = [
      HealthEvent(
        id: 'ev-1',
        title: 'Kontrol Rutin Spesialis Penyakit Dalam',
        subtitle: 'Pemeriksaan tensi & evaluasi resep rutin',
        time: '09:00 - 10:30 WIB',
        date: DateTime(now.year, now.month, now.day),
        type: HealthEventType.doctorAppointment,
        doctorName: 'dr. Afieta Putri, Sp.PD',
        location: 'Poli Spesialis Deker Medika',
      ),
      HealthEvent(
        id: 'ev-2',
        title: 'Minum Metformin 500mg',
        subtitle: '1 Tablet sesudah sarapan pagi',
        time: '08:00 WIB',
        date: DateTime(now.year, now.month, now.day),
        type: HealthEventType.medication,
        isCompleted: true,
      ),
      HealthEvent(
        id: 'ev-3',
        title: 'Cek Gula Darah Puasa (GDP)',
        subtitle: 'Target ideal: 80 - 130 mg/dL',
        time: '07:00 WIB',
        date: DateTime(now.year, now.month, now.day),
        type: HealthEventType.bloodSugarCheck,
        isCompleted: true,
      ),
      HealthEvent(
        id: 'ev-4',
        title: 'Tes Laboratorium HbA1c 3 Bulanan',
        subtitle: 'Cek rata-rata gula darah triwulanan',
        time: '08:30 WIB',
        date: DateTime(now.year, now.month, now.day).add(const Duration(days: 3)),
        type: HealthEventType.labTest,
        location: 'Laboratorium Klinik Deker',
      ),
      HealthEvent(
        id: 'ev-5',
        title: 'Konsultasi Lanjutan Gula Darah',
        subtitle: 'Review hasil lab dan pola makan',
        time: '14:00 WIB',
        date: DateTime(now.year, now.month, now.day).add(const Duration(days: 5)),
        type: HealthEventType.doctorAppointment,
        doctorName: 'dr. Kaka, Sp.PD-KEMD',
        location: 'Klinik Rawat Jalan Deker',
      ),
      HealthEvent(
        id: 'ev-6',
        title: 'Minum Glimepiride 2mg',
        subtitle: '1 Tablet sebelum makan malam',
        time: '20:00 WIB',
        date: DateTime(now.year, now.month, now.day),
        type: HealthEventType.medication,
      ),
    ];
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  List<HealthEvent> _getEventsForDate(DateTime date) {
    return _events.where((e) {
      final sameDay = e.date.year == date.year && e.date.month == date.month && e.date.day == date.day;
      if (!sameDay) return false;

      if (_selectedFilter == 'Kontrol Dokter') {
        return e.type == HealthEventType.doctorAppointment;
      } else if (_selectedFilter == 'Minum Obat') {
        return e.type == HealthEventType.medication;
      } else if (_selectedFilter == 'Cek Gula') {
        return e.type == HealthEventType.bloodSugarCheck || e.type == HealthEventType.labTest;
      }
      return true;
    }).toList();
  }

  bool _hasEventsOnDate(DateTime date) {
    return _events.any((e) =>
        e.date.year == date.year && e.date.month == date.month && e.date.day == date.day);
  }

  void _showAddEventSheet() {
    final titleController = TextEditingController();
    final subtitleController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    DateTime selectedEventDate = _selectedDate;
    HealthEventType selectedType = HealthEventType.doctorAppointment;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedTime =
                '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')} WIB';

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9EAEB),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.event_note_rounded, color: _maroon, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tambah Agenda Kesehatan',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF141414),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Kategori Agenda
                    Text(
                      'Jenis Agenda',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Kontrol Dokter'),
                          selected: selectedType == HealthEventType.doctorAppointment,
                          selectedColor: const Color(0xFFF9EAEB),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            color: selectedType == HealthEventType.doctorAppointment ? _maroon : const Color(0xFF616161),
                            fontWeight: selectedType == HealthEventType.doctorAppointment ? FontWeight.w600 : FontWeight.w400,
                          ),
                          onSelected: (val) => setModalState(() => selectedType = HealthEventType.doctorAppointment),
                        ),
                        ChoiceChip(
                          label: const Text('Minum Obat'),
                          selected: selectedType == HealthEventType.medication,
                          selectedColor: const Color(0xFFF9EAEB),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            color: selectedType == HealthEventType.medication ? _maroon : const Color(0xFF616161),
                            fontWeight: selectedType == HealthEventType.medication ? FontWeight.w600 : FontWeight.w400,
                          ),
                          onSelected: (val) => setModalState(() => selectedType = HealthEventType.medication),
                        ),
                        ChoiceChip(
                          label: const Text('Cek Gula / Lab'),
                          selected: selectedType == HealthEventType.bloodSugarCheck,
                          selectedColor: const Color(0xFFF9EAEB),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 11,
                            color: selectedType == HealthEventType.bloodSugarCheck ? _maroon : const Color(0xFF616161),
                            fontWeight: selectedType == HealthEventType.bloodSugarCheck ? FontWeight.w600 : FontWeight.w400,
                          ),
                          onSelected: (val) => setModalState(() => selectedType = HealthEventType.bloodSugarCheck),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Judul
                    Text(
                      'Nama Agenda / Dokter / Tes',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Misal: Kontrol dr. Afieta Putri, Sp.PD',
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9E9E9E)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Catatan / Lokasi
                    Text(
                      'Catatan / Lokasi',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF424242),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: subtitleController,
                      decoration: InputDecoration(
                        hintText: 'Misal: Poli Penyakit Dalam RS Deker Medika',
                        hintStyle: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF9E9E9E)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Tanggal & Jam
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedEventDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (pickedDate != null) {
                                setModalState(() => selectedEventDate = pickedDate);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: _maroon),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${selectedEventDate.day}/${selectedEventDate.month}/${selectedEventDate.year}',
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pickedTime = await showTimePicker(
                                context: sheetContext,
                                initialTime: selectedTime,
                              );
                              if (pickedTime != null) {
                                setModalState(() => selectedTime = pickedTime);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: _maroon),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      formattedTime,
                                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Batal',
                              style: GoogleFonts.poppins(color: const Color(0xFF757575), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final text = titleController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Nama agenda tidak boleh kosong', style: GoogleFonts.poppins(fontSize: 12)),
                                    backgroundColor: Colors.red.shade700,
                                  ),
                                );
                                return;
                              }

                              final newEvent = HealthEvent(
                                id: 'ev-${DateTime.now().millisecondsSinceEpoch}',
                                title: text,
                                subtitle: subtitleController.text.trim().isEmpty
                                    ? 'Agenda Kesehatan Pribadi'
                                    : subtitleController.text.trim(),
                                time: formattedTime,
                                date: selectedEventDate,
                                type: selectedType,
                              );

                              setState(() {
                                _events.add(newEvent);
                                _selectedDate = selectedEventDate;
                              });

                              Navigator.pop(sheetContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Agenda "$text" berhasil ditambahkan ke kalender', style: GoogleFonts.poppins(fontSize: 12)),
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _maroon,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: Text(
                              'Simpan Agenda',
                              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMonthHeader() {
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final monthStr = '${monthNames[_currentMonth.month - 1]} ${_currentMonth.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: _maroon, size: 28),
            onPressed: _previousMonth,
          ),
          Text(
            monthStr,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: _maroon, size: 28),
            onPressed: _nextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1 = Mon, 7 = Sun

    final weekTitles = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekTitles.map((w) {
              final isWeekend = w == 'Sab' || w == 'Min';
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isWeekend ? _darkRose : const Color(0xFF757575),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 42, // 6 rows max
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              if (dayOffset < 0 || dayOffset >= daysInMonth) {
                return const SizedBox.shrink();
              }

              final dayNum = dayOffset + 1;
              final thisDate = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
              final isSelected = _selectedDate.year == thisDate.year &&
                  _selectedDate.month == thisDate.month &&
                  _selectedDate.day == thisDate.day;
              final isToday = DateTime.now().year == thisDate.year &&
                  DateTime.now().month == thisDate.month &&
                  DateTime.now().day == thisDate.day;
              final hasEvent = _hasEventsOnDate(thisDate);

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = thisDate;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryPink
                        : (isToday ? const Color(0xFFFFF0F5) : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelected
                        ? Border.all(color: _primaryPink, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNum',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? _maroon : const Color(0xFF212121)),
                        ),
                      ),
                      if (hasEvent)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : _darkRose,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: _primaryPink,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF424242),
              ),
              side: BorderSide(
                color: isSelected ? _primaryPink : const Color(0xFFE0E0E0),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (val) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventCard(HealthEvent event) {
    Color badgeColor;
    Color iconBg;
    IconData icon;
    String badgeText;

    switch (event.type) {
      case HealthEventType.doctorAppointment:
        badgeColor = const Color(0xFF1976D2);
        iconBg = const Color(0xFFE3F2FD);
        icon = Icons.local_hospital_rounded;
        badgeText = 'Kontrol Dokter';
        break;
      case HealthEventType.medication:
        badgeColor = _darkRose;
        iconBg = const Color(0xFFFCE4EC);
        icon = Icons.medication_rounded;
        badgeText = 'Minum Obat';
        break;
      case HealthEventType.bloodSugarCheck:
        badgeColor = const Color(0xFFE65100);
        iconBg = const Color(0xFFFFF3E0);
        icon = Icons.bloodtype_rounded;
        badgeText = 'Cek Gula Darah';
        break;
      case HealthEventType.labTest:
        badgeColor = const Color(0xFF388E3C);
        iconBg = const Color(0xFFE8F5E9);
        icon = Icons.biotech_rounded;
        badgeText = 'Uji Laboratorium';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.isCompleted ? const Color(0xFFA5D6A7) : const Color(0xFFFCE4EC),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: badgeColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF141414),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  event.isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: event.isCompleted ? const Color(0xFF2E7D32) : const Color(0xFFBDBDBD),
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    event.isCompleted = !event.isCompleted;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        event.isCompleted
                            ? 'Agenda "${event.title}" telah diselesaikan ✓'
                            : 'Status "${event.title}" dikembalikan',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      backgroundColor: event.isCompleted ? const Color(0xFF2E7D32) : const Color(0xFF616161),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event.subtitle,
            style: GoogleFonts.poppins(fontSize: 11.5, color: const Color(0xFF616161)),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: _primaryPink),
              const SizedBox(width: 4),
              Text(
                event.time,
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF424242)),
              ),
              if (event.doctorName.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.person_pin_rounded, size: 14, color: _primaryPink),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.doctorName,
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF616161)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else if (event.location.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.location_on_rounded, size: 14, color: _primaryPink),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF616161)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dailyEvents = _getEventsForDate(_selectedDate);
    final monthNames = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final selectedDateStr =
        '${_selectedDate.day} ${monthNames[_selectedDate.month - 1]} ${_selectedDate.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kalender Kesehatan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Tambah Agenda',
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
            onPressed: _showAddEventSheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly Header
              _buildMonthHeader(),
              const SizedBox(height: 12),

              // Calendar Grid
              _buildCalendarGrid(),
              const SizedBox(height: 16),

              // Quick Actions Banner (Konsultasi & Pengingat Obat)
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConsultationListScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8BBD0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 18, color: _darkRose),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jadwal Dokter',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _darkRose),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF8BBD0)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.alarm_on_rounded, size: 18, color: _darkRose),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pengingat Obat',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: _darkRose),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Filter Chips
              _buildFilterChips(),
              const SizedBox(height: 16),

              // Selected Date Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agenda: $selectedDateStr',
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      Text(
                        '${dailyEvents.length} agenda terjadwal pada hari ini',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF757575),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddEventSheet,
                    icon: const Icon(Icons.add, size: 14, color: Colors.white),
                    label: Text(
                      'Agenda',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _maroon,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Events List for Selected Day
              if (dailyEvents.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCE4EC)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 44, color: Color(0xFFBDBDBD)),
                      const SizedBox(height: 8),
                      Text(
                        'Tidak Ada Agenda Pada Tanggal Ini',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF616161),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tekan "+ Agenda" untuk mencatat jadwal kontrol dokter atau pengingat kesehatan Anda.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                )
              else
                ...dailyEvents.map((e) => _buildEventCard(e)),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
