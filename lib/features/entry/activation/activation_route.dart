import '../../../domain/app_role.dart';

class ActivationArgs {
  const ActivationArgs({required this.role, this.phone});

  final String? phone;
  final AppRole role;
}
