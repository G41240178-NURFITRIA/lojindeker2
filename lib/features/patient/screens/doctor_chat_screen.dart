import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  final bool isRead;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
    this.isRead = false,
  });
}

class DoctorChatScreen extends StatefulWidget {
  final String doctorName;
  final String initials;
  final String specialty;
  final bool isOnline;

  const DoctorChatScreen({
    super.key,
    this.doctorName = 'Dr. Kaka',
    this.initials = 'DK',
    this.specialty = 'Spesialis Penyakit Dalam',
    this.isOnline = true,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _showTyping = true;
  late AnimationController _dotAnimController;

  @override
  void initState() {
    super.initState();

    _dotAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _messages.addAll([
      const ChatMessage(
        text:
            'Selamat siang. Bagaimana perkembangan kadar gula darah Anda hari ini?',
        isMe: false,
        time: '12:30',
      ),
      const ChatMessage(
        text:
            'Perkembangan kadar gula saya sangat baik hari ini, lebih baik sebelumnya.',
        isMe: true,
        time: '12:45',
        isRead: true,
      ),
    ]);
  }

  @override
  void dispose() {
    _dotAnimController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
          time: timeStr,
          isRead: true,
        ),
      );
      if (customText == null) {
        _messageController.clear();
      }
      _showTyping = true;
    });

    _scrollToBottom();

    // Simulate doctor reply
    Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      setState(() {
        _showTyping = false;
        _messages.add(
          ChatMessage(
            text:
                'Bagus sekali! Tetap pertahankan pola makan sehat, pantau kadar gula secara berkala, dan jangan lupa konsumsi obat sesuai anjuran ya.',
            isMe: false,
            time: timeStr,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0D0D0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lampirkan Dokumen Medis',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6E1E24),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildAttachmentItem(
                      icon: Icons.camera_alt_rounded,
                      label: 'Foto Kamera',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage('[Foto Pemeriksaan Gula Darah]');
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage('[Hasil Tes Lab Gula Darah.jpg]');
                      },
                    ),
                    _buildAttachmentItem(
                      icon: Icons.description_rounded,
                      label: 'Dokumen',
                      onTap: () {
                        Navigator.pop(ctx);
                        _sendMessage('[Laporan Medis Berkala.pdf]');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFFF9EAEA),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF6E1E24), size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF0DDDD),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                      color: Color(0xFF1E1E1E),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Avatar with circular border and online indicator
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFFE8B6B9),
                            width: 1.2,
                          ),
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                Icons.medical_services_rounded,
                                color: Color(0xFF893638),
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Green Online Dot at bottom-right
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  // Doctor Name and Subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6E1E24),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${widget.specialty} • Online',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF666666),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat messages list
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              children: [
                // Date pill "Hari Ini"
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 18),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F2F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Hari Ini',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ),
                ),

                // Render Messages
                ..._messages.map((msg) => _buildMessageItem(msg)),

                // Typing indicator "..."
                if (_showTyping) _buildTypingIndicatorBubble(),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage msg) {
    if (msg.isMe) {
      // User Message (Right-aligned, Maroon)
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFF893638),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                msg.text,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.4,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFFAF1F1),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    msg.time,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF5A1C20),
                    ),
                  ),
                  if (msg.isRead) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.done_all_rounded,
                      size: 15,
                      color: Color(0xFF5A1C20),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Doctor Message (Left-aligned, Soft Pink with mini logo)
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Small Doctor Logo beside the bubble
                Container(
                  width: 24,
                  height: 24,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE8B6B9),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF893638),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),

                // Doctor Bubble
                Flexible(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.76,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8EBEB),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      msg.text,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF222222),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                msg.time,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF555555),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTypingIndicatorBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14, left: 6),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 66,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF9EAEA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFFEBDADA),
              width: 1,
            ),
          ),
          child: AnimatedBuilder(
            animation: _dotAnimController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final double delay = index * 0.2;
                  final double progress =
                      ((_dotAnimController.value - delay) % 1.0);
                  final double scale =
                      0.8 + 0.35 * (1 - (progress - 0.5).abs() * 2);
                  final double opacity =
                      0.5 + 0.5 * (1 - (progress - 0.5).abs() * 2);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 6.5 * scale,
                    height: 6.5 * scale,
                    decoration: BoxDecoration(
                      color: const Color(0xFF666666)
                          .withValues(alpha: opacity.clamp(0.4, 1.0)),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7F7),
        border: Border(
          top: BorderSide(
            color: Color(0xFFF2DEDE),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: SafeArea(
        top: false,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F2),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFECCECE),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            children: [
              // Circular '+' Button in Maroon
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showAttachmentOptions,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6E1E24),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Text Field Input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1E1E1E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF666666),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Circular Send Button in Maroon
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _sendMessage(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6E1E24),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
