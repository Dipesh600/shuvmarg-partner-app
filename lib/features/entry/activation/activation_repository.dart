import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/result.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_service.dart';
import '../../../domain/app_role.dart';
import '../../../shared/session/session_providers.dart';

abstract interface class ActivationGateway {
  Future<Result<String>> sendOtp(String phone, AppRole role);
}

final activationRepositoryProvider = Provider<ActivationGateway>((ref) {
  return ActivationRepository(ref.watch(apiServiceProvider));
});

class ActivationRepository implements ActivationGateway {
  const ActivationRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<String>> sendOtp(String phone, AppRole role) async {
    final result = await _api.post(
      ApiPaths.activateSendOtp,
      body: {'phone': phone},
      authenticated: false,
      appSource: role,
    );
    return result.map((body) {
      final data = body['data'];
      final expiresIn = data is Map ? data['expiresIn'] : null;
      return expiresIn is String ? expiresIn : '5 minutes';
    });
  }
}
