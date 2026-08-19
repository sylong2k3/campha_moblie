import '../l10n/l10n.dart';
import 'user_role.dart';

/// Nhãn hiển thị theo ngôn ngữ app khi backend chỉ trả role code.
extension UserRoleL10n on UserRole {
  String displayLabel(AppLocalizations l10n) {
    return switch (this) {
      UserRole.systemAdmin => l10n.roleSystemAdmin,
      UserRole.soTnmt => l10n.roleSoTnmt,
      UserRole.soXd => l10n.roleSoXd,
      UserRole.ubndTp => l10n.roleUbndTp,
      UserRole.citizen => l10n.roleCitizen,
      UserRole.guest => l10n.roleGuest,
    };
  }

  String shortLabel(AppLocalizations l10n) {
    return switch (this) {
      UserRole.systemAdmin => l10n.roleSystemAdminShort,
      UserRole.soTnmt => l10n.roleSoTnmtShort,
      UserRole.soXd => l10n.roleSoXdShort,
      UserRole.ubndTp => l10n.roleUbndTpShort,
      UserRole.citizen => l10n.roleCitizenShort,
      UserRole.guest => l10n.roleGuestShort,
    };
  }
}
