import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.softPinkBg,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xFF212121),
        displayColor: const Color(0xFF212121),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.cyanGradientEnd,
      ),
    );
  }
}
