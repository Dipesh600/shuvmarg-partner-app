import '../../../domain/app_role.dart';

class ForcePasswordArgs {
  const ForcePasswordArgs({required this.tempToken, required this.role});

  final String tempToken;
  final AppRole role;
}
