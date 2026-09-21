import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Layar Chat Konsultasi Interaktif (Tema Soft Pink)
class LiveChatScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String initials;

  const LiveChatScreen({
    super.key,
    this.doctorName = 'Dr. Kaka',
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

  // Palette soft pink matching the app's brand theme
  static const Color _primaryPink = Color(0xFFF06292);       // Soft Pink Brand
  static const Color _darkRose = Color(0xFFD81B60);          // Deep Soft Pink
  static const Color _softPinkLight = Color(0xFFFF94B2);     // Light Soft Pink
  static const Color _doctorBubbleBg = Color(0xFFFCE4EC);    // Soft Pink Bubble dokter
  static const Color _doctorBubbleBorder = Color(0xFFF8BBD0);// Soft Pink Border dokter
  static const Color _inputBarBg = Color(0xFFFFF0F5);        // Soft Pink bar background
  static const Color _borderSoft = Color(0xFFF8BBD0);

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
        text: 'Selamat siang. Bagaimana perkembangan kadar gula darah Anda hari ini?',
        isUser: false,
        time: '12:30',
      ),
      ChatMessage(
        text: 'Perkembangan kadar gula saya sangat baik hari ini, lebih baik sebelumnya.',
        isUser: true,
        time: '12:45',
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
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

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
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      String reply;
      final lower = trimmed.toLowerCase();
      if (lower.contains('108') ||
          lower.contains('gula darah') ||
          lower.contains('normal') ||
          lower.contains('baik')) {
        reply =
            'Bagus sekali! Angka dan perkembangan tersebut menunjukkan kondisi gula darah Anda terkontrol dengan sangat baik. Tetap pertahankan pola makan rendah gula ya!';
      } else if (lower.contains('makan') ||
          lower.contains('pantangan') ||
          lower.contains('nasi')) {
        reply =
            'Untuk asupan makanan, utamakan karbohidrat kompleks seperti nasi merah atau oatmeal, perbanyak sayuran hijau, dan batasi konsumsi minuman manis kemasan.';
      } else if (lower.contains('pusing') ||
          lower.contains('obat') ||
          lower.contains('metformin')) {
        reply =
            'Pusing ringan bisa terjadi penyesuaian tubuh. Pastikan obat diminum teratur sesaat setelah makan dan perbanyak minum air putih ya.';
      } else if (lower.contains('jadwal') ||
          lower.contains('evaluasi') ||
          lower.contains('resep')) {
        reply =
            'Jadwal evaluasi kontrol rutin berikutnya pada 20 Juni 2026. Anda juga dapat memeriksa menu resep di aplikasi.';
      } else {
        reply =
            'Baik, terima kasih atas informasinya. Kondisi Anda akan terus saya pantau. Segera kabari jika ada keluhan tambahan ya!';
      }

      final replyNow = DateTime.now();
      final replyTime =
          '${replyNow.hour.toString().padLeft(2, '0')}:${replyNow.minute.toString().padLeft(2, '0')}';

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
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _doctorBubbleBorder,
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: _doctorBubbleBg,
                          child: Center(
                            child: Text(
                              widget.initials,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: _darkRose,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
                    '${widget.specialty.length > 5 ? widget.specialty.substring(0, 5) + '...' : widget.specialty} • Online',
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

                // Daftar pesan
                ..._messages.map((msg) => _buildMessageBubble(msg)),

                // Typing indicator dokter
                if (_isDoctorTyping) _buildTypingIndicator(),
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
            // Avatar Logo Dokter
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 2, right: 8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _doctorBubbleBg,
                      child: Center(
                        child: Text(
                          widget.initials,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: _darkRose,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Konten Pesan & Waktu
            Column(
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
          ],
        ),
      );
    }
  }

  /// Typing indicator dokter: bubble tiga titik soft pink
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2, right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  size: 16,
                  color: _darkRose,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _doctorBubbleBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _doctorBubbleBorder, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _primaryPink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _primaryPink,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _primaryPink,
                    shape: BoxShape.circle,
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
