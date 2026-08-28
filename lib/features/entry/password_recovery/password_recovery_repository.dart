import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_service.dart';
import '../../../domain/app_role.dart';
import '../../../shared/session/session_providers.dart';

abstract interface class PasswordRecoveryGateway {
  Future<Result<void>> requestCode(String phone);
  Future<Result<void>> verifyCode(String phone, String otp);
  Future<Result<void>> resendCode(String phone);
}

final passwordRecoveryRepositoryProvider = Provider<PasswordRecoveryGateway>((
  ref,
) {
  return PasswordRecoveryRepository(ref.watch(apiServiceProvider));
});

class PasswordRecoveryRepository implements PasswordRecoveryGateway {
  const PasswordRecoveryRepository(this._api);

  final ApiService _api;

  Future<Result<void>> _post(String path, Map<String, String> body) async {
    final result = await _api.post(
      path,
      body: body,
      authenticated: false,
      appSource: AppRole.agent,
    );
    return result.map((_) {});
  }

  @override
  Future<Result<void>> requestCode(String phone) =>
      _post(ApiPaths.agentRequestPasswordReset, {'phone': phone});

  @override
  Future<Result<void>> verifyCode(String phone, String otp) =>
      _post(ApiPaths.agentVerifyOtpForReset, {'phone': phone, 'otp': otp});

  @override
  Future<Result<void>> resendCode(String phone) =>
      _post(ApiPaths.agentResendOtpForReset, {'phone': phone});
}
