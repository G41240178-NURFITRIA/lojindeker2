import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

class AppLogoBadge extends StatelessWidget {
  final double size;

  const AppLogoBadge({
    super.key,
    this.size = 135,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3D Glossy Emblem
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.bgGradientTop.withValues(alpha: 0.4),
                blurRadius: 25,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback vector render if image fails to load
                return _buildFallbackLogo();
              },
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Brand Title: DIABETES CARE
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'DIABETES ',
                style: GoogleFonts.montserrat(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.titleWhite,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              TextSpan(
                text: 'CARE',
                style: GoogleFonts.montserrat(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.brandCareCoral,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Subtitle: MONITOR • CONTROL • LIVE BETTER
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSubtitleWord('MONITOR'),
              _buildDot(),
              _buildSubtitleWord('CONTROL'),
              _buildDot(),
              _buildSubtitleWord('LIVE BETTER'),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildSubtitleWord(String word) {
    return Text(
      word,
      style: GoogleFonts.montserrat(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AppColors.subtitleWhite.withValues(alpha: 0.92),
      ),
    );
  }

  static Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 7),
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppColors.brandCareCoral,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildFallbackLogo() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgGradientBottom,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.water_drop_rounded,
          color: Colors.white,
          size: 64,
        ),
      ),
    );
  }
}
