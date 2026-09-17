import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DevicePreviewWrapper extends StatefulWidget {
  final Widget child;

  const DevicePreviewWrapper({
    super.key,
    required this.child,
  });

  @override
  State<DevicePreviewWrapper> createState() => _DevicePreviewWrapperState();
}

class _DevicePreviewWrapperState extends State<DevicePreviewWrapper> {
  bool _usePhoneMockup = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If on real mobile screen or user disabled mockup, show full screen
        if (constraints.maxWidth <= 540 || !_usePhoneMockup) {
          return Stack(
            children: [
              widget.child,
              if (constraints.maxWidth > 540)
                Positioned(
                  top: 16,
                  right: 16,
                  child: _buildToggleFloatingButton(
                    isMockup: false,
                    onTap: () => setState(() => _usePhoneMockup = true),
                  ),
                ),
            ],
          );
        }

        // On desktop browser: render a realistic smartphone mockup
        final screenHeight = constraints.maxHeight;
        final phoneHeight = (screenHeight * 0.94).clamp(680.0, 840.0);
        const phoneWidth = 390.0; // Standard smartphone width

        return Scaffold(
          backgroundColor: const Color(0xFF141518),
          body: Stack(
            children: [
              // Subtle background ambient pattern
              Center(
                child: Container(
                  width: 500,
                  height: 500,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD91823).withValues(alpha: 0.12),
                        blurRadius: 180,
                        spreadRadius: 80,
                      ),
                    ],
                  ),
                ),
              ),

              // Centered Smartphone Frame
              Center(
                child: Container(
                  width: phoneWidth,
                  height: phoneHeight,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(48),
                    border: Border.all(
                      color: const Color(0xFF2E3138),
                      width: 8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 40,
                        spreadRadius: 8,
                        offset: const Offset(0, 16),
                      ),
                      BoxShadow(
                        color: const Color(0xFFD91823).withValues(alpha: 0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Stack(
                      children: [
                        // The actual Flutter App Screen
                        Positioned.fill(
                          child: widget.child,
                        ),

                        // Smartphone Top Speaker / Dynamic Island
                        Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 110,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF1A1A24),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  width: 32,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222226),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Smartphone Bottom Home Indicator Bar
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            width: 130,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Top Controls Header
              Positioned(
                top: 16,
                right: 20,
                child: _buildToggleFloatingButton(
                  isMockup: true,
                  onTap: () => setState(() => _usePhoneMockup = false),
                ),
              ),

              // Hint Label for the user
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Text(
                      '📱 Tampilan Mode HP D-Care (Diabetes Care)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildToggleFloatingButton({
    required bool isMockup,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF212228),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMockup ? Icons.fullscreen_rounded : Icons.phone_android_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isMockup ? 'Layar Penuh' : 'Mode Bingkai HP',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
