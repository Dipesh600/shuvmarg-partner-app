import '../../../domain/agent_identity.dart';

enum AgentWorkspaceKind { operatorOwned, platform, unsupported }

AgentWorkspaceKind workspaceKindForScope(AgentScope? scope) => switch (scope) {
  AgentScope.operatorOwned => AgentWorkspaceKind.operatorOwned,
  AgentScope.platform => AgentWorkspaceKind.platform,
  null => AgentWorkspaceKind.unsupported,
};
