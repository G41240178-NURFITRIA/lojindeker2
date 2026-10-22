import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/admin_activity_service.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/patient_activity_service.dart';
import '../../../core/services/patient_chat_notification_service.dart';
import '../../../core/widgets/doctor_avatar_widget.dart';

/// Model pesan chat
class ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });

  factory ChatMessage.fromRealtime(RealtimeChatMessage rm) {
    return ChatMessage(
      text: rm.text,
      isUser: rm.isPatient,
      time: rm.time,
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

  void _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _chatId == null) return;

    _controller.clear();

    PatientActivityService.instance.recordConsultation(
      doctorName: widget.doctorName,
      specialty: widget.specialty,
      lastMessage: trimmed,
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
      );
    } catch (e) {
      debugPrint('⚠️ Error sending message: $e');
    }

    _scrollToBottom();
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
                    onTap: () {},
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

    if (isUser) {
      // Bubble User / Pasien (Soft Pink Gradient)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Text(
                msg.text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
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
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.74,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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
                    child: Text(
                      msg.text,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF1E1E1E),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      msg.time,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF8E8E8E),
                      ),
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
