import '../../../domain/app_role.dart';

class PasswordRecoveryArgs {
  const PasswordRecoveryArgs({required this.role, this.phone = ''});

  final AppRole role;
  final String phone;
}
