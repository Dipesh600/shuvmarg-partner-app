import '../../../../core/errors/result.dart';
import '../../../../core/network/api_paths.dart';
import '../../../../core/network/api_service.dart';
import 'agent_assignment.dart';

abstract interface class AgentAssignmentGateway {
  Future<Result<List<AgentAssignment>>> load();
  Future<Result<AgentAssignment>> accept(String assignmentId);
  Future<Result<AgentAssignment>> decline(String assignmentId, String? reason);
}

class AgentAssignmentRepository implements AgentAssignmentGateway {
  const AgentAssignmentRepository(this._api);

  final ApiService _api;

  @override
  Future<Result<List<AgentAssignment>>> load() async {
    final result = await _api.get(
      ApiPaths.agentAssignments,
      query: const {'page': 1, 'limit': 50},
    );
    return result.map((json) {
      final rows = json['data'];
      if (rows is! List) {
        throw const FormatException('Response had no assignment list.');
      }
      return rows
          .map((row) => AgentAssignment.fromJson(_map(row)))
          .toList(growable: false);
    });
  }

  @override
  Future<Result<AgentAssignment>> accept(String assignmentId) async {
    final result = await _api.post(
      ApiPaths.acceptAgentAssignment(assignmentId),
      body: const <String, dynamic>{},
    );
    return result.map(_assignmentFromEnvelope);
  }

  @override
  Future<Result<AgentAssignment>> decline(
    String assignmentId,
    String? reason,
  ) async {
    final result = await _api.post(
      ApiPaths.declineAgentAssignment(assignmentId),
      body: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return result.map(_assignmentFromEnvelope);
  }

  static AgentAssignment _assignmentFromEnvelope(Map<String, dynamic> json) {
    return AgentAssignment.fromJson(_map(json['data']));
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    throw const FormatException('Response had no assignment object.');
  }
}
