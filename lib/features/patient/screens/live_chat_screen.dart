import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
}

/// Layar Chat Konsultasi Interaktif & Hidup
class LiveChatScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String initials;

  const LiveChatScreen({
    super.key,
    this.doctorName = 'Dr. Kaka, Sp.PD',
    this.specialty = 'Spesialis Penyakit Dalam',
    this.initials = 'DK',
  });

  @override
  State<LiveChatScreen> createState() => _LiveChatScreenState();
}

class _LiveChatScreenState extends State<LiveChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isDoctorTyping = false;

  late List<ChatMessage> _messages;

  final List<String> _quickPrompts = [
    'Gula darah puasa saya 108 mg/dL',
    'Ingin konsultasi pantangan makan',
    'Kapan jadwal evaluasi resep?',
    'Ada pusing ringan setelah minum obat',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        text: 'Halo Muhammad Nizam! 🌸 Saya ${widget.doctorName}. Bagaimana kondisi gula darah dan kesehatanmu hari ini? Ada keluhan yang ingin dikonsultasikan?',
        isUser: false,
        time: '09:00',
      ),
    ];
  }

  @override
  void dispose() {
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

  void _sendMessage(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(ChatMessage(
        text: trimmed,
        isUser: true,
        time: timeStr,
      ));
      _controller.clear();
      _isDoctorTyping = true;
    });

    _scrollToBottom();

    // Simulasi respons dokter yang hidup & komunikatif
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      String reply;
      final lower = trimmed.toLowerCase();
      if (lower.contains('108') || lower.contains('gula darah') || lower.contains('normal')) {
        reply = 'Bagus sekali Nizam! Angka 108 mg/dL menunjukkan gula darahmu terkontrol dengan sangat baik. Tetap pertahankan pola makan rendah gula ya!';
      } else if (lower.contains('makan') || lower.contains('pantangan') || lower.contains('nasi')) {
        reply = 'Untuk asupan makanan, utamakan karbohidrat kompleks seperti nasi merah atau oatmeal, perbanyak serat sayuran hijau, dan batasi konsumsi minuman manis kemasan.';
      } else if (lower.contains('pusing') || lower.contains('obat') || lower.contains('metformin')) {
        reply = 'Pusing ringan bisa terjadi penyesuaian tubuh. Pastikan obat diminum bersamaan atau sesaat setelah makan besar dan minumlah cukup air putih ya.';
      } else if (lower.contains('jadwal') || lower.contains('evaluasi') || lower.contains('resep')) {
        reply = 'Jadwal evaluasi resep berikutnya pada 20 Juni 2026. Jika obat habis lebih awal, kamu bisa pesan melalui Menu Penunjang ya.';
      } else {
        reply = 'Baik Nizam, terima kasih atas informasinya. Kondisimu tetap saya pantau di riwayat kesehatan. Segera hubungi saya kembali jika ada keluhan tambahan!';
      }

      final replyNow = DateTime.now();
      final replyTime = '${replyNow.hour.toString().padLeft(2, '0')}:${replyNow.minute.toString().padLeft(2, '0')}';

      setState(() {
        _isDoctorTyping = false;
        _messages.add(ChatMessage(
          text: reply,
          isUser: false,
          time: replyTime,
        ));
      });

      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5), // Soft pink background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF06292), // Soft Pink
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.initials,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: const Color(0xFFD81B60),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Online • Komunikasi Aktif',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner Komunikasi Sehat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              border: Border(
                bottom: BorderSide(color: const Color(0xFFF8BBD0), width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: Color(0xFFD81B60), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sesi konsultasi live dilindungi enkripsi medis RS D-Care.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF880E4F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Message list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Typing indicator
          if (_isDoctorTyping)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF8BBD0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFF06292),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.doctorName} sedang mengetik...',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF757575),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Quick action chips for quick communication
          Container(
            height: 38,
            margin: const EdgeInsets.only(bottom: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _quickPrompts.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return ActionChip(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFF8BBD0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  label: Text(
                    prompt,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFD81B60),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onPressed: () => _sendMessage(prompt),
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: const Color(0xFFF8BBD0), width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF8BBD0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E1E1E)),
                        decoration: InputDecoration(
                          hintText: 'Tulis pesan konsultasi...',
                          hintStyle: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF9E9E9E)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _sendMessage(_controller.text),
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF8DA1), Color(0xFFF06292)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
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

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFFFF8DA1), Color(0xFFF06292)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: const Color(0xFFF8BBD0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: isUser ? Colors.white : const Color(0xFF1E1E1E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: GoogleFonts.poppins(
                fontSize: 9.5,
                color: isUser ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
