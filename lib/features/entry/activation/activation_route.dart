import '../../../domain/app_role.dart';

class ActivationArgs {
  const ActivationArgs({required this.phone, required this.role});

  final String phone;
  final AppRole role;
}
