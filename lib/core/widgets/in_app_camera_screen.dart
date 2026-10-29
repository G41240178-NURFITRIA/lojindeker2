import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';

/// Layar Kamera Interaktif D-Care (Lensa Kamera Live dengan Viewfinder Medis)
/// Menampilkan feed kamera aktif secara langsung (tanpa layar hitam),
/// dilengkapi garis bidik medis, toggle flash, flip kamera, dan tombol jepret langsung (1 langkah).
/// Juga dilengkapi fallback otomatis ke kamera HP bawaan bila diperlukan.
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFrontCamera = false;
  int _flashMode = 0; // 0: Auto, 1: On, 2: Off
  bool _isCapturing = false;
  bool _isLoading = true;
  String? _initError;
  Uint8List? _capturedImageBytes;
  late AnimationController _shutterAnimController;
  late AnimationController _scannerAnimController;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _shutterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      if (state == AppLifecycleState.resumed) {
        _initCamera();
      }
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
      _isCameraInitialized = false;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _initError = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        final camera = _cameras.firstWhere(
          (c) =>
              c.lensDirection ==
              (_isFrontCamera
                  ? CameraLensDirection.front
                  : CameraLensDirection.back),
          orElse: () => _cameras.first,
        );
        await _setupController(camera);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _initError = 'Kamera tidak ditemukan pada perangkat';
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error init camera: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _initError = e.toString();
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium, // Medium cepat & kompatibel di semua HP
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
          _isLoading = false;
          _initError = null;
        });
      } else {
        controller.dispose();
      }
    } catch (e) {
      debugPrint('⚠️ Error setup camera controller: $e');
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isLoading = false;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _shutterAnimController.dispose();
    _scannerAnimController.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    setState(() {
      _flashMode = (_flashMode + 1) % 3;
    });

    FlashMode mode = FlashMode.auto;
    String status = 'Flash Otomatis';
    if (_flashMode == 1) {
      mode = FlashMode.always;
      status = 'Flash Aktif';
    } else if (_flashMode == 2) {
      mode = FlashMode.off;
      status = 'Flash Nonaktif';
    }

    try {
      await _cameraController!.setFlashMode(mode);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status, style: GoogleFonts.poppins(fontSize: 12)),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isCameraInitialized = false;
      _isLoading = true;
    });

    await _cameraController?.dispose();
    final targetDirection = _isFrontCamera
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == targetDirection,
      orElse: () => _cameras.first,
    );
    await _setupController(camera);
  }

  /// Ambil foto langsung dari galeri
  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
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

  /// Ambil foto menggunakan Kamera HP Bawaan (Native Camera)
  Future<void> _pickFromNativeCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
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
      debugPrint('⚠️ Error pick native camera: $e');
    }
  }

  /// Jepret Foto Langsung dari Kamera (1 Langkah)
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      // 1. Animasi Shutter Flash
      await _shutterAnimController.forward();
      _shutterAnimController.reverse();

      // 2. Jepret langsung dari sensor kamera live
      if (_cameraController != null &&
          _isCameraInitialized &&
          _cameraController!.value.isInitialized) {
        final XFile photo = await _cameraController!.takePicture();
        final bytes = await photo.readAsBytes();
        if (mounted) {
          setState(() {
            _capturedImageBytes = bytes;
          });
        }
      } else {
        // Fallback cadangan ke kamera bawaan HP jika live sensor belum siap
        await _pickFromNativeCamera();
      }
    } catch (e) {
      debugPrint('⚠️ Error capture photo: $e');
      // Jika terjadi error pada live capture, coba panggil kamera HP
      await _pickFromNativeCamera();
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

  /// Tampilan Kamera Aktif / Viewfinder Live
  Widget _buildViewfinderScreen() {
    return Stack(
      children: [
        // Efek Flash Shutter Putih
        AnimatedBuilder(
          animation: _shutterAnimController,
          builder: (ctx, child) {
            return Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.white.withValues(
                    alpha: _shutterAnimController.value * 0.95,
                  ),
                ),
              ),
            );
          },
        ),

        // 1. Area Viewfinder Tengah dengan Feed Kamera Langsung (Bukan Layar Hitam)
        Center(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 68, 20, 115),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  // Feed Kamera Live dengan Scale Responsif
                  if (_cameraController != null &&
                      _isCameraInitialized &&
                      _cameraController!.value.isInitialized)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final size = constraints.biggest;
                        var scale = size.aspectRatio *
                            _cameraController!.value.aspectRatio;
                        if (scale < 1) scale = 1 / scale;

                        return ClipRect(
                          child: Transform.scale(
                            scale: scale,
                            child: Center(
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        );
                      },
                    )
                  else
                    // Tampilan Viewfinder Ramah Saat Kamera Menyiapkan / Butuh Kamera HP
                    Container(
                      color: const Color(0xFF161928),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                                ),
                                child: _isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.photo_camera_rounded,
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _isLoading
                                    ? 'Menyiapkan Kamera Medis...'
                                    : 'Kamera Siap Digunakan',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isLoading
                                    ? 'Sedang menghubungkan ke sensor kamera perangkat Anda'
                                    : (_initError ?? 'Gunakan kamera bawaan HP atau pilih dari galeri untuk mengambil berkas medis Anda'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: _pickFromNativeCamera,
                                icon: const Icon(Icons.camera_alt_rounded,
                                    size: 17, color: Colors.white),
                                label: Text(
                                  'Buka Kamera HP Langsung',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12.5,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Efek Grid Kamera 3x3
                  Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.15),
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
                                color: Colors.white.withValues(alpha: 0.15),
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
                                color: Colors.white.withValues(alpha: 0.15),
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
                                color: Colors.white.withValues(alpha: 0.15),
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
                                color: AppColors.primary.withValues(alpha: 0.7),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Lingkaran Fokus di Tengah
                  Container(
                    width: 72,
                    height: 72,
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
                        horizontal: 14,
                        vertical: 6,
                      ),
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
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
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
                        _isCameraInitialized
                            ? (_isFrontCamera
                                ? 'Kamera Depan'
                                : 'Kamera Utama')
                            : 'Kamera HP Aktif',
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tombol Pilihan Cepat Kamera HP
                IconButton(
                  tooltip: 'Gunakan Kamera HP Bawaan',
                  onPressed: _pickFromNativeCamera,
                  icon: const Icon(
                    Icons.phone_android_rounded,
                    color: Colors.white,
                    size: 22,
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
                    size: 24,
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

                // Tombol Shutter Utama (Jepret Foto Langsung 1 Langkah)
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
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              Text(
                'Pratinjau Hasil Foto',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 48), // Spacer penyeimbang
            ],
          ),
        ),

        // Foto Hasil Jepretan
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.memory(
                _capturedImageBytes!,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),
          ),
        ),

        // Action Buttons: Ulangi / Kirim
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          color: Colors.black.withValues(alpha: 0.85),
          child: Row(
            children: [
              // Tombol Ulangi Foto
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _capturedImageBytes = null);
                  },
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Ulangi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
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
              // Tombol Kirim Foto
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _confirmAndSend,
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    'Gunakan Foto',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
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

  /// Helper Gambar Sudut Siku-Siku Merah Muda (Corner Frame)
  Widget _buildCorner({required bool top, required bool left}) {
    const double size = 26;
    const double thickness = 3.5;
    const color = Color(0xFFFF2D55);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Garis horizontal
          Positioned(
            top: top ? 0 : null,
            bottom: top ? null : 0,
            left: 0,
            right: 0,
            child: Container(
              height: thickness,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Garis vertikal
          Positioned(
            top: 0,
            bottom: 0,
            left: left ? 0 : null,
            right: left ? null : 0,
            child: Container(
              width: thickness,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
