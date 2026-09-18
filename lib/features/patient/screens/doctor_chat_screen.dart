import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatMessage {
  final String text;
  final bool isMe;
  final String time;

  const ChatMessage({
    required this.text,
    required this.isMe,
    required this.time,
  });
}

class DoctorChatScreen extends StatefulWidget {
  final String doctorName;
  final String initials;
  final String specialty;
  final bool isOnline;

  const DoctorChatScreen({
    super.key,
    required this.doctorName,
    required this.initials,
    required this.specialty,
    required this.isOnline,
  });

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickTopics = [
    'Konsultasi hasil gula darah',
    'Panduan dosis insulin',
    'Keluhan pusing dan lemas',
    'Jadwal kontrol berikutnya',
  ];

  @override
  void initState() {
    super.initState();
    _initializeMessages();
  }

  void _initializeMessages() {
    if (widget.isOnline) {
      _messages.addAll([
        ChatMessage(
          text:
              'Halo! Saya ${widget.doctorName} (${widget.specialty}). Ada yang bisa saya bantu terkait konsultasi kesehatan diabetes Anda hari ini?',
          isMe: false,
          time: '14:02',
        ),
      ]);
    } else {
      _messages.addAll([
        ChatMessage(
          text:
              'Halo! Saat ini saya sedang offline. Jam praktek saya berikutnya adalah besok pukul 09:00 - 14:00. Anda tetap dapat meninggalkan pesan di sini, dan saya akan merespon sesegera mungkin.',
          isMe: false,
          time: 'Kemarin',
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? presetText]) {
    final text = presetText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isMe: true,
          time: timeStr,
        ),
      );
      if (presetText == null) {
        _messageController.clear();
      }
    });

    _scrollToBottom();

    if (widget.isOnline) {
      setState(() => _isTyping = true);
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _isTyping = false;
          _messages.add(
            ChatMessage(
              text:
                  'Terima kasih atas informasinya. Mohon catat kadar gula darah puasa dan 2 jam setelah makan terakhir Anda, agar saya dapat memberikan evaluasi yang lebih tepat.',
              isMe: false,
              time: timeStr,
            ),
          );
        });
        _scrollToBottom();
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF1F1),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF141414),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFDECEE),
              ),
              child: Center(
                child: Text(
                  widget.initials,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8B2326),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.doctorName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF141414),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isOnline
                              ? const Color(0xFF00C48C)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.isOnline ? 'Online' : 'Offline',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: widget.isOnline
                              ? const Color(0xFF00B074)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.phone_outlined,
              color: Color(0xFFBA171E),
              size: 22,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Panggilan suara akan segera tersedia.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF141414),
              size: 22,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Quick topics suggestion chips
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white.withValues(alpha: 0.6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _quickTopics.map((topic) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _sendMessage(topic),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFE5D5D5),
                          ),
                        ),
                        child: Text(
                          topic,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF8B2326),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),

          // Bottom Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isMe ? const Color(0xFFBA171E) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.4,
                color: msg.isMe ? Colors.white : const Color(0xFF141414),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: msg.isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : const Color(0xFF8C8C8C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFBA171E),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.doctorName} sedang mengetik...',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF6ECEB),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.attach_file_rounded,
                  color: Color(0xFF8B2326),
                  size: 20,
                ),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF1F1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEADBDB),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF141414),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tulis pesan konsultasi...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF9E9E9E),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: () => _sendMessage(),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFBA171E),
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
    );
  }
}
