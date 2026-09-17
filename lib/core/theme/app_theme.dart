import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.bgGradientTop,
      scaffoldBackgroundColor: AppColors.bgGradientMid,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bgGradientTop,
        primary: AppColors.bgGradientTop,
        secondary: AppColors.cyanGradientEnd,
      ),
    );
  }
}
