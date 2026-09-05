import 'package:dio/dio.dart' show CancelToken;

import '../../core/errors/result.dart';
import '../../core/network/api_paths.dart';
import '../../core/network/api_service.dart';
import '../../domain/driver_profile.dart';

abstract interface class DriverProfileGateway {
  Future<Result<DriverProfile>> load({CancelToken? cancelToken});
}

/// The only caller of `GET /api/driver/me` in the app.
class DriverProfileRepository implements DriverProfileGateway {
  const DriverProfileRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<DriverProfile>> load({CancelToken? cancelToken}) async {
    final result = await _api.get(ApiPaths.driverMe, cancelToken: cancelToken);
    return result.map((json) {
      final data = json['data'];
      if (data is! Map) {
        throw const FormatException('Response had no "data" object.');
      }
      return DriverProfile.fromJson(data.cast<String, dynamic>());
    });
  }
}
