import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Alias untuk penggunaan avatar secara umum (dokter, pasien, admin)
typedef AppAvatarWidget = DoctorAvatarWidget;

/// Widget avatar serbaguna yang mendukung:
/// - Base64 Data URI (data:image/...;base64,...)
/// - Base64 raw string
/// - Network URL (http / https)
/// - Local Asset path (assets/...)
/// - File path (khusus mobile / desktop non-web)
/// - Fallback dinamis (initials / ikon person)
class DoctorAvatarWidget extends StatelessWidget {
  /// Cache memory untuk gambar base64 agar tidak di-decode ulang setiap frame/detik
  static final Map<String, Uint8List> _base64Cache = {};

  final String? photoUrl;
  final double size;
  final String? initials;
  final Color? backgroundColor;
  final Color? iconColor;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final bool isCircle;
  final VoidCallback? onTap;

  const DoctorAvatarWidget({
    super.key,
    required this.photoUrl,
    this.size = 48,
    this.initials,
    this.backgroundColor,
    this.iconColor,
    this.border,
    this.borderRadius,
    this.isCircle = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarContent = _buildAvatarContent();

    Widget widget;
    if (isCircle) {
      widget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.softPinkCard,
          shape: BoxShape.circle,
          border: border,
        ),
        child: ClipOval(
          child: avatarContent,
        ),
      );
    } else {
      widget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.softPinkCard,
          borderRadius: borderRadius ?? BorderRadius.circular(14),
          border: border,
        ),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(14),
          child: avatarContent,
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: isCircle
            ? BorderRadius.circular(size / 2)
            : (borderRadius ?? BorderRadius.circular(14)),
        child: widget,
      );
    }

    return widget;
  }

  Widget _buildAvatarContent() {
    final photo = photoUrl?.trim();
    if (photo != null && photo.isNotEmpty) {
      // 1. Data URI atau Base64 Image (dengan caching & gaplessPlayback)
      if (photo.startsWith('data:image') || _isLikelyBase64(photo)) {
        try {
          Uint8List? bytes = _base64Cache[photo];
          if (bytes == null) {
            final cleanBase64 = photo.contains(',') ? photo.split(',').last : photo;
            bytes = base64Decode(cleanBase64);
            if (_base64Cache.length > 60) _base64Cache.clear();
            _base64Cache[photo] = bytes;
          }
          return Image.memory(
            bytes,
            key: ValueKey('b64_${photo.hashCode}'),
            width: size,
            height: size,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) => _buildFallback(),
          );
        } catch (e) {
          debugPrint('⚠️ Error decoding base64 photo: $e');
        }
      }

      // 2. Network URL (http / https) dengan gaplessPlayback
      if (photo.startsWith('http://') || photo.startsWith('https://') || photo.startsWith('blob:')) {
        return Image.network(
          photo,
          key: ValueKey('net_$photo'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }

      // 3. Asset Image dengan gaplessPlayback
      if (photo.startsWith('assets/')) {
        return Image.asset(
          photo,
          key: ValueKey('ast_$photo'),
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      }
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    if (initials != null && initials!.trim().isNotEmpty) {
      return Container(
        color: backgroundColor ?? AppColors.softPinkCard,
        child: Center(
          child: Text(
            initials!.trim().toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w700,
              color: iconColor ?? AppColors.primary,
            ),
          ),
        ),
      );
    }

    return Container(
      color: backgroundColor ?? AppColors.softPinkCard,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.58,
          color: iconColor ?? AppColors.primary,
        ),
      ),
    );
  }

  bool _isLikelyBase64(String s) {
    if (s.length < 50) return false;
    final clean = s.replaceAll('\n', '').replaceAll('\r', '').replaceAll(' ', '');
    final sample = clean.length > 60 ? clean.substring(0, 60) : clean;
    return RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(sample);
  }
}
