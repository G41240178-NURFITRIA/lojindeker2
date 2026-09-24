import 'package:flutter/material.dart';

/// App color palette matching the Diabetes Care visual design (Soft Pink Theme)
class AppColors {
  // Soft Pink brand palette
  static const Color primary = Color(0xFFF06292);
  static const Color primaryDark = Color(0xFFD81B60);
  static const Color primaryLight = Color(0xFFFF94B2);
  static const Color primaryAccent = Color(0xFFFF4081);

  // Background soft pink tints
  static const Color softPinkBg = Color(0xFFFFF0F5);
  static const Color softPinkCard = Color(0xFFFCE4EC);
  static const Color softPinkBorder = Color(0xFFF8BBD0);

  // Primary gradient background colors (Soft Pink)
  static const Color bgGradientTop = Color(0xFFFF94B2);
  static const Color bgGradientMid = Color(0xFFF06292);
  static const Color bgGradientBottom = Color(0xFFD81B60);

  // Bottom Stethoscope watermark
  static const Color watermarkRed = Color(0xFFC2185B);

  // Brand title colors
  static const Color titleWhite = Color(0xFFFFFFFF);
  static const Color brandCareCoral = Color(0xFFFFD1DC);
  static const Color subtitleWhite = Color(0xFFEEEEEE);

  // Role button colors
  static const Color roleBorder = Colors.white;
  static const Color roleInactiveBg = Colors.transparent;
  static const Color roleActiveBg = Colors.white;
  static const Color roleActiveText = Color(0xFFD81B60);
  static const Color roleInactiveText = Colors.white;

  // Form input fields
  static const Color inputBg = Colors.white;
  static const Color inputIcon = Color(0xFFD81B60);
  static const Color inputHint = Color(0xFF9E9E9E);
  static const Color inputText = Color(0xFF212121);

  // Glossy CTA & Log In button (Rich Rose / Crimson)
  static const Color ctaGlossTop = Color(0xFFFF7597);
  static const Color ctaGradientStart = Color(0xFFE91E63);
  static const Color ctaGradientEnd = Color(0xFFC2185B);
  static const Color ctaShadow = Color(0x66C2185B);

  // Backward-compatible aliases
  static const Color cyanGlossTop = ctaGlossTop;
  static const Color cyanGradientStart = ctaGradientStart;
  static const Color cyanGradientEnd = ctaGradientEnd;
  static const Color cyanShadow = ctaShadow;

  // Forgot password
  static const Color forgotPasswordText = Color(0xFFF0F0F0);
}
