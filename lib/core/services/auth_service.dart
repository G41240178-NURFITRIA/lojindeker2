// Re-export auth service baru dari services/auth_service.dart
// File ini dipertahankan untuk kompatibilitas backward
// Kode baru sebaiknya mengimpor langsung dari:
//   package:d_care/services/auth_service.dart
//   package:d_care/models/app_user.dart

export '../../services/auth_service.dart';
export '../../models/app_user.dart';

// UserRole compatibility shim (legacy code masih pakai UserRole dari role_selector)
// Tidak perlu re-export UserRole karena masih ada di role_selector.dart
