import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FigmaAuthField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;

  const FigmaAuthField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<FigmaAuthField> createState() => _FigmaAuthFieldState();
}

class _FigmaAuthFieldState extends State<FigmaAuthField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2C2C2C),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF7EAEA),
            borderRadius: BorderRadius.circular(14),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF8B2529),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              hintText: widget.hintText,
              hintStyle: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFB57E81),
                fontWeight: FontWeight.w400,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF8B2529),
                        size: 18,
                      ),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
