import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

/// Layar Kamera Interaktif D-Care (Bentuk Kamera dengan Viewfinder)
/// Menampilkan antarmuka visual kamera lengkap: viewfinder, garis bidik medis,
/// tombol flash, flip kamera, tombol shutter, dan pratinjau foto sebelum dikirim.
class InAppCameraScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const InAppCameraScreen({
    super.key,
    this.title = 'Kamera Medis D-Care',
    this.subtitle = 'Arahkan kamera ke resep, obat, atau berkas medis Anda',
  });

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with TickerProviderStateMixin {
  bool _isFrontCamera = false;
  int _flashMode = 0; // 0: Auto, 1: On, 2: Off
  bool _isCapturing = false;
  Uint8List? _capturedImageBytes;
  late AnimationController _shutterAnimController;
  late AnimationController _scannerAnimController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _shutterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shutterAnimController.dispose();
    _scannerAnimController.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _flashMode = (_flashMode + 1) % 3;
    });
    final status = _flashMode == 0
        ? 'Flash Otomatis'
        : _flashMode == 1
            ? 'Flash Aktif'
            : 'Flash Nonaktif';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(status, style: GoogleFonts.poppins(fontSize: 12)),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _flipCamera() {
    setState(() {
      _isFrontCamera = !_isFrontCamera;
    });
  }

  /// Ambil foto langsung dari galeri
  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _capturedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error pick gallery: $e');
    }
  }

  /// Jepret Foto Asli menggunakan Lensa Kamera
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      // 1. Efek kilat shutter
      await _shutterAnimController.forward();
      _shutterAnimController.reverse();

      // 2. Buka kamera asli perangkat
      XFile? file;
      try {
        file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1024,
        );
      } catch (_) {
        // Fallback untuk browser PC jika kamera native tidak tersedia
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1024,
        );
      }

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (mounted) {
          setState(() {
            _capturedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error capture photo: $e');
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _confirmAndSend() {
    if (_capturedImageBytes == null) return;
    final base64Str = base64Encode(_capturedImageBytes!);
    Navigator.of(context).pop(base64Str);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _capturedImageBytes != null
            ? _buildPreviewScreen()
            : _buildViewfinderScreen(),
      ),
    );
  }

  /// Tampilan Kamera Aktif / Viewfinder
  Widget _buildViewfinderScreen() {
    return Stack(
      children: [
        // Efek Flash Shutter Putih
        AnimatedBuilder(
          animation: _shutterAnimController,
          builder: (ctx, child) {
            return Positioned.fill(
              child: Container(
                color: Colors.white
                    .withValues(alpha: _shutterAnimController.value * 0.95),
              ),
            );
          },
        ),

        // 1. Area Viewfinder Tengah dengan Animasi Pemindai Medis
        Center(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 68, 20, 115),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1C29),
                  Color(0xFF10121A),
                  Color(0xFF1E1624),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Efek Grid Kamera 3x3
                Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),

                // Garis Pemindai Laser Medis (Animasi Bergerak Naik-Turun)
                AnimatedBuilder(
                  animation: _scannerAnimController,
                  builder: (ctx, child) {
                    return Align(
                      alignment: Alignment(
                        0,
                        -0.85 + (_scannerAnimController.value * 1.7),
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        height: 2.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary.withValues(alpha: 0.9),
                              Colors.white,
                              AppColors.primary.withValues(alpha: 0.9),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Indikator Fokus Medis Tengah
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.filter_center_focus_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),

                // Sudut Viewfinder Siku Pink
                Positioned(
                  top: 14,
                  left: 14,
                  child: _buildCorner(top: true, left: true),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _buildCorner(top: true, left: false),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: _buildCorner(top: false, left: true),
                ),
                Positioned(
                  bottom: 14,
                  right: 14,
                  child: _buildCorner(top: false, left: false),
                ),

                // Label Petunjuk di dalam bingkai
                Positioned(
                  bottom: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.document_scanner_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Posisikan berkas / foto di dalam bingkai',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Bar Bagian Atas (Header Controls)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: Colors.black.withValues(alpha: 0.75),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isFrontCamera ? 'Kamera Depan' : 'Kamera Utama (Belakang)',
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _flashMode == 0
                        ? Icons.flash_auto_rounded
                        : _flashMode == 1
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                    color: _flashMode == 1 ? Colors.amber : Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Bar Bagian Bawah (Tombol Jepret & Navigasi)
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            color: Colors.black.withValues(alpha: 0.85),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tombol Ambil dari Galeri
                InkWell(
                  onTap: _pickFromGallery,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),

                // Tombol Shutter Utama (Jepret Foto Asli)
                GestureDetector(
                  onTap: _capturePhoto,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFFD81B60),
                                size: 30,
                              ),
                            ),
                    ),
                  ),
                ),

                // Tombol Putar Kamera (Flip)
                InkWell(
                  onTap: _flipCamera,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.flip_camera_android_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Tampilan Pratinjau Sebelum Mengirim
  Widget _buildPreviewScreen() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.black,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _capturedImageBytes = null);
                },
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 22),
              ),
              Text(
                'Pratinjau Hasil Foto',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 44),
            ],
          ),
        ),

        // Gambar Hasil Foto
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.memory(
              _capturedImageBytes!,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),

        // Bottom Controls: Ulangi vs Kirim
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          color: Colors.black.withValues(alpha: 0.9),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _capturedImageBytes = null);
                  },
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: Text(
                    'Ulangi Foto',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmAndSend,
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  label: Text(
                    'Kirim Foto',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD81B60),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({required bool top, required bool left}) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top
              ? const BorderSide(color: Color(0xFFE91E63), width: 3.5)
              : BorderSide.none,
          bottom: !top
              ? const BorderSide(color: Color(0xFFE91E63), width: 3.5)
              : BorderSide.none,
          left: left
              ? const BorderSide(color: Color(0xFFE91E63), width: 3.5)
              : BorderSide.none,
          right: !left
              ? const BorderSide(color: Color(0xFFE91E63), width: 3.5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
