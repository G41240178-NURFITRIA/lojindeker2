import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/admin_activity_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/patient_activity_service.dart';
import '../../../core/services/patient_chat_notification_service.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';
import '../../../core/widgets/in_app_camera_screen.dart';
import '../../../core/widgets/medical_document_viewer_screen.dart';

/// Model pesan chat
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String time;
  final String type; // 'text' | 'image' | 'document'
  final String? attachmentData;
  final String? attachmentName;
  final String? attachmentSize;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.type = 'text',
    this.attachmentData,
    this.attachmentName,
    this.attachmentSize,
  });

  factory ChatMessage.fromRealtime(RealtimeChatMessage rm) {
    return ChatMessage(
      id: rm.id,
      text: rm.text,
      isUser: rm.isPatient,
      time: rm.time,
      type: rm.type,
      attachmentData: rm.attachmentData,
      attachmentName: rm.attachmentName,
      attachmentSize: rm.attachmentSize,
    );
  }
}

/// Layar Chat Konsultasi Interaktif (Tema Soft Pink)
class LiveChatScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String initials;
  final String? doctorId;

  const LiveChatScreen({
    super.key,
    this.doctorName = 'Dr. Kaka',
    this.specialty = 'Spesialis Penyakit Dalam',
    this.initials = 'DK',
    this.doctorId,
  });

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  bool _isLoading = true;
  String? _doctorPhotoUrl;
  StreamSubscription<List<RealtimeChatMessage>>? _messageSubscription;
  StreamSubscription<DocumentSnapshot>? _doctorProfileSubscription;
  StreamSubscription<DocumentSnapshot>? _chatDocSubscription;

  // Palette soft pink matching the app's brand theme
  static const Color _primaryPink = Color(0xFFF06292);       // Soft Pink Brand
  static const Color _darkRose = Color(0xFFD81B60);          // Deep Soft Pink
  static const Color _softPinkLight = Color(0xFFFF94B2);     // Light Soft Pink
  static const Color _doctorBubbleBg = Color(0xFFFCE4EC);    // Soft Pink Bubble dokter
  static const Color _doctorBubbleBorder = Color(0xFFF8BBD0);// Soft Pink Border dokter
  static const Color _inputBarBg = Color(0xFFFFF0F5);        // Soft Pink bar background
  static const Color _borderSoft = Color(0xFFF8BBD0);

  List<ChatMessage> _messages = [];

  final List<String> _quickPrompts = [
    'Gula darah puasa saya 108 mg/dL',
    'Ingin konsultasi pantangan makan',
    'Kapan jadwal evaluasi resep?',
    'Ada pusing ringan setelah minum obat',
  ];

  @override
  void initState() {
    super.initState();
    _initDoctorPhotoSubscription();
    _initChat();
  }

  void _initDoctorPhotoSubscription() {
    final docId = widget.doctorId;
    final docName = widget.doctorName.trim();

    if (docId != null && docId.isNotEmpty) {
      _subscribeDoctorDoc(docId);
      return;
    }

    // Cari dokter berdasarkan nama di koleksi 'doctors'
    FirebaseFirestore.instance
        .collection('doctors')
        .where('fullName', isEqualTo: docName)
        .limit(1)
        .get()
        .then((snap) {
      if (!mounted) return;
      if (snap.docs.isNotEmpty) {
        _subscribeDoctorDoc(snap.docs.first.id);
      } else {
        // Fallback: cari yang mendekati
        FirebaseFirestore.instance
            .collection('doctors')
            .snapshots()
            .listen((allSnap) {
          if (!mounted) return;
          for (final d in allSnap.docs) {
            final data = d.data();
            final fn = (data['fullName'] as String?)?.toLowerCase().trim() ?? '';
            final target = docName.toLowerCase();
            if (fn.isNotEmpty && (fn.contains(target) || target.contains(fn))) {
              final photo = data['photoUrl'] as String?;
              setState(() {
                _doctorPhotoUrl = (photo != null && photo.trim().isNotEmpty) ? photo : null;
              });
              break;
            }
          }
        });
      }
    }).catchError((e) {
      debugPrint('⚠️ Error init doctor photo subscription: $e');
    });
  }

  void _subscribeDoctorDoc(String doctorUid) {
    _doctorProfileSubscription?.cancel();
    _doctorProfileSubscription = FirebaseFirestore.instance
        .collection('doctors')
        .doc(doctorUid)
        .snapshots()
        .listen((doc) {
      if (!mounted) return;
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final photo = data['photoUrl'] as String?;
        setState(() {
          _doctorPhotoUrl = (photo != null && photo.trim().isNotEmpty) ? photo : null;
        });
      }
    });
  }

  Future<void> _initChat() async {
    try {
      final glucose = PatientActivityService.instance.latestRiskNotifier.value?.glucoseLevel;
      final chatId = await ChatService.instance.getOrCreateChat(
        doctorName: widget.doctorName,
        doctorId: widget.doctorId,
        doctorSpecialty: widget.specialty,
        glucoseNote: glucose,
      );

      if (!mounted) return;

      setState(() {
        _chatId = chatId;
        _isLoading = false;
      });

      _messageSubscription =
          ChatService.instance.streamMessages(chatId).listen((items) {
        if (!mounted) return;
        setState(() {
          _messages = items.map((m) => ChatMessage.fromRealtime(m)).toList();
        });
        _scrollToBottom();
      });

      // Pantau dokumen chat untuk foto dokter & ID dokter real-time
      _chatDocSubscription = FirebaseFirestore.instance
          .collection('consultation_chats')
          .doc(chatId)
          .snapshots()
          .listen((chatDoc) {
        if (!mounted) return;
        if (chatDoc.exists && chatDoc.data() != null) {
          final data = chatDoc.data()!;
          final photo = data['doctorPhotoUrl'] as String?;
          if (photo != null && photo.trim().isNotEmpty) {
            setState(() {
              _doctorPhotoUrl = photo;
            });
          }
          final resolvedDocId = data['doctorId'] as String?;
          if (resolvedDocId != null &&
              resolvedDocId.isNotEmpty &&
              _doctorProfileSubscription == null) {
            _subscribeDoctorDoc(resolvedDocId);
          }
        }
      });

      PatientChatNotificationService.instance.activeChatId = chatId;
      ChatService.instance.markAsReadByPatient(chatId);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    PatientChatNotificationService.instance.activeChatId = null;
    _doctorProfileSubscription?.cancel();
    _chatDocSubscription?.cancel();
    _messageSubscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage(
    String text, {
    String type = 'text',
    String? attachmentData,
    String? attachmentName,
    String? attachmentSize,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && attachmentData == null) return;
    if (_chatId == null) return;

    _controller.clear();

    final summary = type == 'image'
        ? (trimmed.isNotEmpty ? '📷 Foto: $trimmed' : '📷 Foto')
        : (type == 'document'
            ? '📄 ${attachmentName ?? "Dokumen"}'
            : trimmed);

    PatientActivityService.instance.recordConsultation(
      doctorName: widget.doctorName,
      specialty: widget.specialty,
      lastMessage: summary,
    );

    AdminActivityService.instance.logKonsultasi(
      patientName: '',
      doctorName: widget.doctorName,
    );

    try {
      await ChatService.instance.sendMessage(
        chatId: _chatId!,
        text: trimmed,
        senderRole: 'pasien',
        senderName: 'Pasien',
        type: type,
        attachmentData: attachmentData,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
      );
    } catch (e) {
      debugPrint('⚠️ Error sending message: $e');
    }

    _scrollToBottom();
  }

  /// Tampilkan Bottom Sheet Lampiran ala WhatsApp
  void _showAttachmentBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    colors: const [Color(0xFFFF5252), Color(0xFFFF1744)],
                    onTap: () async {
                      Navigator.pop(ctx);
                      final resultBase64 = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InAppCameraScreen(
                            title: 'Kamera Pasien D-Care',
                            subtitle: 'Arahkan kamera ke resep atau kondisi fisik Anda',
                          ),
                        ),
                      );
                      if (resultBase64 != null && resultBase64.isNotEmpty) {
                        _sendMessage(
                          '',
                          type: 'image',
                          attachmentData: resultBase64,
                          attachmentName:
                              'Foto_Medis_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          attachmentSize: '120 KB',
                        );
                      }
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library_rounded,
                    label: 'Galeri',
                    colors: const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSendImage(ImageSource.gallery);
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Dokumen',
                    colors: const [Color(0xFF42A5F5), Color(0xFF1976D2)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _showDocumentPickerSheet();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.water_drop_rounded,
                    label: 'Gula Darah',
                    colors: const [Color(0xFF26A69A), Color(0xFF00897B)],
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendLabSummaryAttachment();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF424242),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 65,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64String = base64Encode(bytes);
      final sizeKb = (bytes.lengthInBytes / 1024).round();
      final sizeStr = sizeKb > 1024
          ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
          : '$sizeKb KB';

      if (!mounted) return;
      _showImagePreviewDialog(
        bytes: bytes,
        base64String: base64String,
        fileName: picked.name,
        fileSize: sizeStr,
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showImagePreviewDialog({
    required Uint8List bytes,
    required String base64String,
    required String fileName,
    required String fileSize,
  }) {
    final captionController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_rounded, color: _primaryPink, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kirim Foto ($fileSize)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    controller: captionController,
                    style: GoogleFonts.poppins(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Tambah keterangan foto...',
                      hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.poppins(color: Colors.grey.shade700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          final caption = captionController.text.trim();
                          Navigator.pop(ctx);
                          _sendMessage(
                            caption,
                            type: 'image',
                            attachmentData: base64String,
                            attachmentName: fileName,
                            attachmentSize: fileSize,
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                        label: Text(
                          'Kirim',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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
  }

  void _showDocumentPickerSheet() {
    final docs = [
      {
        'title': 'Hasil_Lab_Glukosa_Darah.pdf',
        'desc': 'Hasil pemeriksaan lab gula darah & HbA1c',
        'size': '240 KB',
        'icon': Icons.picture_as_pdf_rounded,
        'color': const Color(0xFFE53935),
      },
      {
        'title': 'Surat_Rujukan_Klinis.pdf',
        'desc': 'Surat rujukan konsultasi dokter spesialis',
        'size': '175 KB',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF1E88E5),
      },
      {
        'title': 'Catatan_Resep_Obat_Pasien.pdf',
        'desc': 'Riwayat daftar resep dan obat yang dikonsumsi',
        'size': '110 KB',
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF43A047),
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _doctorBubbleBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insert_drive_file_rounded,
                        color: _primaryPink, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kirim Dokumen Medis',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: const Color(0xFF212121),
                        ),
                      ),
                      Text(
                        'Lampirkan hasil lab atau berkas rujukan',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...docs.map((d) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (d['color'] as Color).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        d['icon'] as IconData,
                        color: d['color'] as Color,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      d['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    subtitle: Text(
                      '${d['desc']} • ${d['size']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: const Icon(Icons.send_rounded,
                        color: _primaryPink, size: 18),
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendMessage(
                        'Lampiran Dokumen: ${d['title']}',
                        type: 'document',
                        attachmentName: d['title'] as String,
                        attachmentSize: d['size'] as String,
                        attachmentData: 'mock_pdf_patient',
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  final resultBase64 = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InAppCameraScreen(
                        title: 'Pindai Berkas Medis',
                        subtitle: 'Posisikan dokumen atau resep medis di dalam bingkai',
                      ),
                    ),
                  );
                  if (resultBase64 != null && resultBase64.isNotEmpty) {
                    _sendMessage(
                      '',
                      type: 'image',
                      attachmentData: resultBase64,
                      attachmentName:
                          'Dokumen_Scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
                      attachmentSize: '120 KB',
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _primaryPink.withValues(alpha: 0.4),
                      style: BorderStyle.solid,
                    ),
                    color: _doctorBubbleBg.withValues(alpha: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.document_scanner_rounded,
                          color: _primaryPink, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Foto / Scan Dokumen Fisik',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendLabSummaryAttachment() {
    final glucose = PatientActivityService.instance.latestRiskNotifier.value?.glucoseLevel;
    final textSummary = glucose != null && glucose.isNotEmpty
        ? 'Gula darah terakhir saya: $glucose'
        : 'Gula darah puasa saya: 110 mg/dL (Terkontrol)';

    _sendMessage(
      '📊 Laporan Glukosa Darah Terkini:\n$textSummary\nDikirim langsung dari pencatatan harian D-Care.',
      type: 'document',
      attachmentName: 'Ringkasan_Glukosa_Pasien.pdf',
      attachmentSize: '88 KB',
      attachmentData: 'mock_glucose_summary_pdf',
    );
  }

  void _openFullScreenImage(Uint8List bytes, String? name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              name ?? 'Foto',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(bytes),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentDetailModal(ChatMessage msg) {
    final name = msg.attachmentName ?? 'Dokumen.pdf';
    final size = msg.attachmentSize ?? '150 KB';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded,
                    color: Color(0xFFE53935), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ukuran: $size • Format Dokumen PDF Terenkripsi',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MedicalDocumentViewerScreen(
                          documentTitle: name,
                          patientName: 'verelgio_',
                          doctorName: widget.doctorName,
                          fileSize: size,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_rounded, color: Colors.white),
                  label: Text(
                    'Unduh & Buka Dokumen',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMessageOptions(ChatMessage msg) {
    final text = msg.text.isNotEmpty
        ? msg.text
        : (msg.attachmentName ?? (msg.type == 'image' ? 'Lampiran Foto' : 'Lampiran'));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _doctorBubbleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _doctorBubbleBorder),
                ),
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF424242),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              if (msg.text.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.copy_rounded, color: Color(0xFF424242), size: 20),
                  ),
                  title: Text(
                    'Salin Teks',
                    style: GoogleFonts.poppins(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: msg.text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Teks disalin ke clipboard', style: GoogleFonts.poppins()),
                        backgroundColor: _darkRose,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              if (msg.text.isNotEmpty) const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                ),
                title: Text(
                  'Hapus Pesan untuk Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                subtitle: Text(
                  'Pesan akan terhapus dari riwayat pasien dan dokter',
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteMessage(msg.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteMessage(String messageId) {
    if (messageId.isEmpty || _chatId == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Hapus Pesan?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Pesan ini akan dihapus secara permanen untuk Anda dan dokter.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ChatService.instance.deleteMessage(
                  chatId: _chatId!,
                  messageId: messageId,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesan berhasil dihapus', style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF333333),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus pesan: $e', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Hapus untuk Semua', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _confirmClearAllMessages() {
    if (_chatId == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Bersihkan Percakapan?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'Semua riwayat percakapan akan dihapus untuk Anda dan dokter. Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await ChatService.instance.clearAllMessages(_chatId!);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Seluruh percakapan berhasil dibersihkan', style: GoogleFonts.poppins()),
                    backgroundColor: const Color(0xFF333333),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal membersihkan percakapan: $e', style: GoogleFonts.poppins()),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text('Bersihkan Semua', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF1E1E1E),
            size: 30,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // Avatar Dokter dengan status Online
            Stack(
              clipBehavior: Clip.none,
              children: [
                DoctorAvatarWidget(
                  photoUrl: _doctorPhotoUrl,
                  size: 40,
                  initials: widget.initials,
                  border: Border.all(
                    color: _doctorBubbleBorder,
                    width: 1.5,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${widget.specialty.length > 5 ? '${widget.specialty.substring(0, 5)}...' : widget.specialty} • Online',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: const Color(0xFF8E8E8E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF1E1E1E)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) {
              if (val == 'clear') {
                _confirmClearAllMessages();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Bersihkan Percakapan',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(height: 1, color: _borderSoft),

          // Message list
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                // Pill tanggal "Hari ini"
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4, bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _doctorBubbleBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _doctorBubbleBorder, width: 1),
                    ),
                    child: Text(
                      'Hari ini',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _darkRose,
                      ),
                    ),
                  ),
                ),

                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: CircularProgressIndicator(color: _primaryPink, strokeWidth: 2.5),
                    ),
                  )
                else if (_messages.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _doctorBubbleBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _doctorBubbleBorder),
                        ),
                        child: Text(
                          'Sesi konsultasi real-time terhubung dengan ${widget.doctorName}.\nSilakan kirim keluhan atau gunakan pertanyaan cepat di bawah.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF555555),
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  ..._messages.map((msg) => _buildMessageBubble(msg)),
              ],
            ),
          ),

          // Quick action chips (Pertanyaan Cepat Soft Pink)
          Container(
            height: 36,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  backgroundColor: _inputBarBg,
                  side: const BorderSide(color: _borderSoft),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(
                    prompt,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _darkRose,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),

          // Input area soft pink bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: _inputBarBg,
              border: Border(
                top: BorderSide(color: _borderSoft, width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Tombol Plus (+) Soft Pink Gradient
                  InkWell(
                    onTap: _showAttachmentBottomSheet,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_softPinkLight, _primaryPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Text Field Tulis pesan...
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _borderSoft,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF1E1E1E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: const Color(0xFF9E9E9E),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Tombol Kirim Soft Pink Gradient
                  InkWell(
                    onTap: () => _sendMessage(_controller.text),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_softPinkLight, _primaryPink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
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

  /// Bubble Pesan: Dokter (Soft Pink Card), Pasien (Soft Pink Gradient)
  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    final isImage = msg.type == 'image';
    final isDocument = msg.type == 'document';

    Uint8List? imageBytes;
    if (isImage && msg.attachmentData != null && msg.attachmentData!.isNotEmpty) {
      try {
        imageBytes = base64Decode(msg.attachmentData!);
      } catch (_) {}
    }

    if (isUser) {
      // Bubble User / Pasien (Soft Pink Gradient)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            GestureDetector(
              onLongPress: () => _showMessageOptions(msg),
              onSecondaryTap: () => _showMessageOptions(msg),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_softPinkLight, _primaryPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(6),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryPink.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Lampiran Gambar Pasien
                    if (isImage && imageBytes != null) ...[
                      GestureDetector(
                        onTap: () => _openFullScreenImage(imageBytes!, msg.attachmentName),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            constraints: const BoxConstraints(
                              maxHeight: 200,
                              maxWidth: 240,
                            ),
                            color: Colors.black12,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Image.memory(imageBytes, fit: BoxFit.cover),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.fullscreen_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Lampiran Dokumen Pasien
                    if (isDocument) ...[
                      InkWell(
                        onTap: () => _showDocumentDetailModal(msg),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Color(0xFFE53935),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.attachmentName ?? 'Dokumen.pdf',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${msg.attachmentSize ?? "PDF"} • Ketuk untuk buka',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    if (msg.text.isNotEmpty)
                      Text(
                        msg.text,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.time,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF8E8E8E),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.done_all_rounded,
                    size: 14,
                    color: _primaryPink,
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _showMessageOptions(msg),
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        Icons.more_horiz_rounded,
                        size: 14,
                        color: Color(0xFFBDBDBD),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Bubble Dokter (Soft Pink Card)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Foto Dokter
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: DoctorAvatarWidget(
                photoUrl: _doctorPhotoUrl,
                size: 28,
                initials: widget.initials,
              ),
            ),

            // Konten Pesan & Waktu
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(msg),
                    onSecondaryTap: () => _showMessageOptions(msg),
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.74,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _doctorBubbleBg,
                        border: Border.all(color: _doctorBubbleBorder, width: 1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Lampiran Gambar Dokter
                          if (isImage && imageBytes != null) ...[
                            GestureDetector(
                              onTap: () => _openFullScreenImage(imageBytes!, msg.attachmentName),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                    maxWidth: 240,
                                  ),
                                  color: Colors.black12,
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      Image.memory(imageBytes, fit: BoxFit.cover),
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        margin: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(Icons.fullscreen_rounded,
                                            color: Colors.white, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          // Lampiran Dokumen Dokter
                          if (isDocument) ...[
                            InkWell(
                              onTap: () => _showDocumentDetailModal(msg),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F7),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Color(0xFFE53935),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            msg.attachmentName ?? 'Dokumen.pdf',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF212121),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${msg.attachmentSize ?? "PDF"} • Ketuk untuk buka',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],

                          if (msg.text.isNotEmpty)
                            Text(
                              msg.text,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF1E1E1E),
                                height: 1.45,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          msg.time,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: const Color(0xFF8E8E8E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _showMessageOptions(msg),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Icon(
                              Icons.more_horiz_rounded,
                              size: 14,
                              color: Color(0xFFBDBDBD),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
