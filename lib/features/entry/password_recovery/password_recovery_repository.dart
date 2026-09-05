import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_service.dart';
import '../../../domain/app_role.dart';
import '../../../shared/session/session_providers.dart';

abstract interface class PasswordRecoveryGateway {
  Future<Result<void>> requestCode(String phone, AppRole role);
  Future<Result<void>> verifyCode(String phone, String otp, AppRole role);
  Future<Result<void>> resendCode(String phone, AppRole role);
}

final passwordRecoveryRepositoryProvider = Provider<PasswordRecoveryGateway>((
  ref,
) {
  return PasswordRecoveryRepository(ref.watch(apiServiceProvider));
});

class PasswordRecoveryRepository implements PasswordRecoveryGateway {
  const PasswordRecoveryRepository(this._api);

  final ApiService _api;

  Future<Result<void>> _post(
    String path,
    Map<String, String> body,
    AppRole role,
  ) async {
    final result = await _api.post(
      path,
      body: body,
      authenticated: false,
      appSource: role,
    );
    return result.map((_) {});
  }

  @override
  Future<Result<void>> requestCode(String phone, AppRole role) => _post(
    role == AppRole.driver
        ? ApiPaths.driverRequestPasswordReset
        : ApiPaths.agentRequestPasswordReset,
    {'phone': phone},
    role,
  );

  @override
  Future<Result<void>> verifyCode(String phone, String otp, AppRole role) =>
      _post(
        role == AppRole.driver
            ? ApiPaths.driverVerifyOtpForReset
            : ApiPaths.agentVerifyOtpForReset,
        {'phone': phone, 'otp': otp},
        role,
      );

  @override
  Future<Result<void>> resendCode(String phone, AppRole role) => _post(
    role == AppRole.driver
        ? ApiPaths.driverResendOtpForReset
        : ApiPaths.agentResendOtpForReset,
    {'phone': phone},
    role,
  );
}
