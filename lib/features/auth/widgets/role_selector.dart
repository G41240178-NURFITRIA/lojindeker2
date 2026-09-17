import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';

enum UserRole { pasien, dokter, admin }

class RoleSelector extends StatelessWidget {
  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;

  const RoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildRoleButton(
            role: UserRole.pasien,
            label: 'Pasien',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleButton(
            role: UserRole.dokter,
            label: 'Dokter',
            icon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildRoleButton(
            role: UserRole.admin,
            label: 'Admin',
            icon: Icons.person_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = selectedRole == role;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onRoleChanged(role),
        borderRadius: BorderRadius.circular(30),
        splashColor: Colors.white.withValues(alpha: 0.2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: isSelected ? Colors.white : Colors.transparent,
            border: Border.all(
              color: Colors.white,
              width: 1.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.roleActiveText : AppColors.roleInactiveText,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? AppColors.roleActiveText : AppColors.roleInactiveText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
