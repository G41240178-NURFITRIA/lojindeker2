import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/auth_service.dart';
import 'consultation_list_screen.dart';
import 'riwayat_resep_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String patientName;

  const MedicalRecordsScreen({
    super.key,
    this.patientName = 'Pasien',
  });

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Konsultasi', 'Resep Obat'];

  late List<_MedicalRecordItem> _records;
  String _patientDisplayName = '';
  String _dob = '';
  String _phoneNumber = '';
  String _email = '';
  int? _age;

  @override
  void initState() {
    super.initState();
    _patientDisplayName = widget.patientName;
    _records = [];
    _loadPatientData();
  }

  int? _calculateAge(String dobStr) {
    try {
      final parts = dobStr.split('-');
      if (parts.length == 3) {
        final birthDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        return age > 0 ? age : null;
      }
    } catch (_) {}
    return null;
  }

  String _formatIndonesianDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _loadPatientData() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _records = [];
        });
      }
      return;
    }

    // 1. Muat profil user dari Firestore
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        final fullName = (data['fullName'] ?? data['profileName'])?.toString();
        final dobStr = data['dob']?.toString() ?? '';
        final phone = data['phoneNumber']?.toString() ?? '';
        final mail = data['email']?.toString() ?? user.email ?? '';

        setState(() {
          if (fullName != null && fullName.trim().isNotEmpty) {
            _patientDisplayName = fullName.trim();
          }
          _dob = dobStr.trim();
          _phoneNumber = phone.trim();
          _email = mail.trim();
          if (_dob.isNotEmpty) {
            _age = _calculateAge(_dob);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading patient data in MedicalRecordsScreen: $e');
    }

    final List<_MedicalRecordItem> loadedRecords = [];

    // 2. Muat riwayat konsultasi asli pasien dari Firestore
    try {
      final chatsSnap = await FirebaseFirestore.instance
          .collection('consultation_chats')
          .where('patientId', isEqualTo: user.uid)
          .get();

      for (final chatDoc in chatsSnap.docs) {
        final cData = chatDoc.data();
        final doctorName = cData['doctorName']?.toString() ?? 'Dokter';
        final specialty = cData['doctorSpecialty']?.toString() ?? 'Spesialis Penyakit Dalam';
        final statusRaw = cData['status']?.toString().toLowerCase() ?? 'selesai';
        final isActive = statusRaw == 'active' || statusRaw == 'aktif';

        DateTime date = DateTime.now();
        if (cData['createdAt'] is Timestamp) {
          date = (cData['createdAt'] as Timestamp).toDate();
        } else if (cData['lastMessageTime'] is Timestamp) {
          date = (cData['lastMessageTime'] as Timestamp).toDate();
        } else if (cData['updatedAt'] is Timestamp) {
          date = (cData['updatedAt'] as Timestamp).toDate();
        }

        final notes = cData['lastMessage']?.toString() ??
            cData['glucoseNote']?.toString() ??
            'Sesi konsultasi dokter.';

        loadedRecords.add(
          _MedicalRecordItem(
            date: _formatIndonesianDate(date),
            doctorName: doctorName,
            clinic: '$specialty • Konsultasi Online',
            status: isActive ? 'Aktif' : 'Selesai',
            statusColor: isActive ? const Color(0xFF1976D2) : const Color(0xFF2E7D32),
            medicines: const [],
            notes: notes.isNotEmpty ? notes : 'Sesi konsultasi dokter selesai.',
            categoryType: 'Konsultasi',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading consultation records: $e');
    }

    // 3. Muat riwayat resep obat pasien jika tersimpan di subcollection prescriptions
    try {
      final prescriptionsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('prescriptions')
          .get();

      for (final pDoc in prescriptionsSnap.docs) {
        final pData = pDoc.data();
        final doctorName = pData['doctorName']?.toString() ?? 'dr. Spesialis';
        final clinic = pData['clinic']?.toString() ?? 'Resep Dokter Resmi';
        final status = pData['status']?.toString() ?? 'Aktif';
        final dateStr = pData['date']?.toString() ?? _formatIndonesianDate(DateTime.now());
        final notes = pData['notes']?.toString() ?? 'Konsumsi obat sesuai aturan pakai dokter.';
        final medsList = (pData['medicines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            (pData['items'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
            [];

        loadedRecords.add(
          _MedicalRecordItem(
            date: dateStr,
            doctorName: doctorName,
            clinic: clinic,
            status: status,
            statusColor: status.toLowerCase() == 'aktif' ? const Color(0xFF1976D2) : const Color(0xFF757575),
            medicines: medsList,
            notes: notes,
            categoryType: 'Resep Obat',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error loading prescription records: $e');
    }

    if (mounted) {
      setState(() {
        _records = loadedRecords;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final currentCategory = _filters[_selectedFilterIndex];
    final filteredRecords = _records.where((item) => item.categoryType == currentCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Stack(
        children: [
          // Background decorative circle at top right
          Positioned(
            top: -70,
            right: -70,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF8BBD0).withValues(alpha: 0.5),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 1. App Bar Header
                _buildAppBar(context),

                // 2. Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Patient Identity Card (Data Asli dari Database)
                        _buildPatientProfileCard(),
                        const SizedBox(height: 18),

                        // Filter Chips: Hanya Konsultasi & Resep Obat
                        _buildFilterChips(),
                        const SizedBox(height: 18),

                        // Section Title & Counter
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              currentCategory == 'Konsultasi'
                                  ? 'Riwayat Konsultasi Dokter'
                                  : 'Riwayat Resep Obat',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF141414),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD81B60).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${filteredRecords.length} Catatan',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD81B60),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Records List / Empty State
                        if (filteredRecords.isEmpty)
                          _buildEmptyRecordsState(currentCategory)
                        else
                          ...filteredRecords.map((item) => _buildRecordCard(item)),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Bottom Action Button sesuai kategori aktif
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (_selectedFilterIndex == 0 || filteredRecords.isEmpty) {
                    // Buka layar daftar dokter / konsultasi
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConsultationListScreen(),
                      ),
                    );
                  } else {
                    // Buka layar riwayat resep lengkap
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RiwayatResepScreen(),
                      ),
                    );
                  }
                },
                icon: Icon(
                  (_selectedFilterIndex == 0 || filteredRecords.isEmpty)
                      ? Icons.chat_bubble_outline_rounded
                      : Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  _selectedFilterIndex == 0
                      ? 'Jadwalkan Konsultasi Dokter'
                      : (filteredRecords.isEmpty
                          ? 'Konsultasi Sekarang'
                          : 'Buka Riwayat Resep Lengkap'),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF06292),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEADBDB), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xFF333333),
              ),
            ),
          ),

          // Title
          Text(
            'Riwayat Pasien',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),

          // Spacer agar judul tetap presisi di tengah
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildPatientProfileCard() {
    final name = _patientDisplayName.isNotEmpty ? _patientDisplayName : widget.patientName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF8DA1),
            Color(0xFFF06292),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF06292).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        _email,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Pasien Terdaftar',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPatientMetaItem('Usia', _age != null ? '$_age Thn' : '-'),
              _buildPatientMetaItem('Tgl. Lahir', _dob.isNotEmpty ? _dob : '-'),
              _buildPatientMetaItem('No. HP', _phoneNumber.isNotEmpty ? _phoneNumber : '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPatientMetaItem(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyRecordsState(String category) {
    final isConsultation = category == 'Konsultasi';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConsultation ? Icons.chat_bubble_outline_rounded : Icons.medication_outlined,
              color: const Color(0xFFD81B60),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isConsultation ? 'Belum ada riwayat konsultasi' : 'Belum ada riwayat resep obat',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF141414),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isConsultation
                ? 'Riwayat konsultasi dengan dokter dan catatan anjuran\nakan muncul di sini setelah konsultasi dilakukan.'
                : 'Daftar resep obat yang diresepkan oleh dokter\nakan tersimpan secara otomatis di sini.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF757575),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConsultationListScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8DA1), Color(0xFFF06292)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConsultation ? Icons.chat_outlined : Icons.medication_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConsultation ? 'Konsultasi Sekarang' : 'Konsultasi Dokter Sekarang',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: List.generate(_filters.length, (index) {
        final isSelected = _selectedFilterIndex == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 6,
              right: index == _filters.length - 1 ? 0 : 6,
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedFilterIndex = index),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD81B60) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD81B60) : const Color(0xFFF8BBD0),
                    width: 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFFD81B60).withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      index == 0 ? Icons.chat_bubble_outline_rounded : Icons.medication_outlined,
                      size: 15,
                      color: isSelected ? Colors.white : const Color(0xFFD81B60),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _filters[index],
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : const Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRecordCard(_MedicalRecordItem item) {
    final isConsultation = item.categoryType == 'Konsultasi';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Kunjungan / Resep
          InkWell(
            onTap: () {
              setState(() {
                item.isExpanded = !item.isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF1F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isConsultation ? Icons.chat_bubble_outline_rounded : Icons.medication_rounded,
                      color: const Color(0xFFBA171E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.date,
                              style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF141414),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: item.statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.status,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: item.statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.doctorName,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF444444),
                          ),
                        ),
                        Text(
                          item.clinic,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    item.isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Detail Isi Riwayat (Jika di-expand)
          if (item.isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daftar Obat
                  if (item.medicines.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.medication_rounded, size: 16, color: Color(0xFF8F0D12)),
                        const SizedBox(width: 6),
                        Text(
                          isConsultation ? 'Obat yang Direkomendasikan' : 'Daftar Obat & Aturan Minum',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8F0D12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF1F1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.medicines.map((med) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFBA171E))),
                                Expanded(
                                  child: Text(
                                    med,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF212121),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Catatan / Anjuran Dokter
                  if (item.notes.isNotEmpty) ...[
                    Text(
                      isConsultation ? 'Catatan & Anjuran Dokter' : 'Petunjuk Penggunaan',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8F0D12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        item.notes,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          height: 1.45,
                          color: const Color(0xFF424242),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MedicalRecordItem {
  final String date;
  final String doctorName;
  final String clinic;
  final String status;
  final Color statusColor;
  final List<String> medicines;
  final String notes;
  final String categoryType;
  bool isExpanded;

  _MedicalRecordItem({
    required this.date,
    required this.doctorName,
    required this.clinic,
    required this.status,
    required this.statusColor,
    required this.medicines,
    required this.notes,
    required this.categoryType,
  }) : isExpanded = false;
}
