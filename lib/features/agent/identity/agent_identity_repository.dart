import 'package:dio/dio.dart' show CancelToken;

import '../../../core/errors/result.dart';
import '../../../core/network/api_paths.dart';
import '../../../core/network/api_service.dart';
import '../../../domain/agent_identity.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — agent identity repository
///
/// The only place `GET /api/agent/me` and `GET /api/agent/me/code` are called.
/// Every request goes through [ApiService], so auth headers, refresh-on-401 and
/// failure mapping stay in one place (production_project_rules.md §4.2).
///
/// Both methods return [Result] and never throw: a screen cannot forget that a
/// network call can fail, because the failure is in the return type.
/// ─────────────────────────────────────────────────────────────────────────────
class AgentIdentityRepository {
  const AgentIdentityRepository(this._api);

  final ApiService _api;

  /// The agent's own identity.
  ///
  /// Readable at every KYC status — unlike `/api/agent/profile`, this endpoint
  /// is not behind `requireApprovedAgent` — so an agent at DRAFT still sees
  /// their code and where they are in verification.
  Future<Result<AgentIdentity>> load({CancelToken? cancelToken}) async {
    final result = await _api.get(ApiPaths.agentMe, cancelToken: cancelToken);
    return result.map((json) => AgentIdentity.fromJson(_data(json)));
  }

  /// The code plus the server-composed share sentence.
  Future<Result<AgentCodeShare>> loadShareableCode({
    CancelToken? cancelToken,
  }) async {
    final result = await _api.get(
      ApiPaths.agentMeCode,
      cancelToken: cancelToken,
    );
    return result.map((json) => AgentCodeShare.fromJson(_data(json)));
  }

  /// Unwraps the `{success, message, data}` envelope every agent endpoint uses.
  ///
  /// Throws when `data` is absent or is not an object, which [Result.map] turns
  /// into a `ServerFailure` — a malformed envelope is a server problem, and this
  /// is the boundary that stops it becoming a null dereference in a widget.
  static Map<String, dynamic> _data(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Response had no "data" object.');
  }
}
