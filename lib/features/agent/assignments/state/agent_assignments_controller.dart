import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/session/session_providers.dart';
import '../../../../shared/state/view_state.dart';
import '../data/agent_assignment.dart';
import '../data/agent_assignment_repository.dart';

@immutable
class AgentAssignmentsView {
  const AgentAssignmentsView({
    required this.items,
    this.submittingId,
    this.notice,
    this.noticeIsError = false,
  });

  final List<AgentAssignment> items;
  final String? submittingId;
  final String? notice;
  final bool noticeIsError;

  List<AgentAssignment> get invitations => items
      .where((item) => item.status == AgentAssignmentStatus.invited)
      .toList(growable: false);

  List<AgentAssignment> get active => items
      .where((item) => item.status == AgentAssignmentStatus.active)
      .toList(growable: false);

  List<AgentAssignment> get pausedOrRemoved => items
      .where(
        (item) =>
            item.status == AgentAssignmentStatus.suspended ||
            item.status == AgentAssignmentStatus.revoked,
      )
      .toList(growable: false);

  List<AgentAssignment> get history =>
      items.where((item) => item.status.isPast).toList(growable: false);

  AgentAssignmentsView copyWith({
    String? submittingId,
    bool clearSubmitting = false,
    String? notice,
    bool clearNotice = false,
    bool? noticeIsError,
  }) {
    return AgentAssignmentsView(
      items: items,
      submittingId: clearSubmitting ? null : submittingId ?? this.submittingId,
      notice: clearNotice ? null : notice ?? this.notice,
      noticeIsError: noticeIsError ?? this.noticeIsError,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AgentAssignmentsView &&
      listEquals(other.items, items) &&
      other.submittingId == submittingId &&
      other.notice == notice &&
      other.noticeIsError == noticeIsError;

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(items), submittingId, notice, noticeIsError);
}

final agentAssignmentRepositoryProvider = Provider<AgentAssignmentGateway>((
  ref,
) {
  return AgentAssignmentRepository(ref.watch(apiServiceProvider));
});

final agentAssignmentsControllerProvider =
    NotifierProvider.autoDispose<
      AgentAssignmentsController,
      ViewState<AgentAssignmentsView>
    >(AgentAssignmentsController.new);

class AgentAssignmentsController
    extends AutoDisposeNotifier<ViewState<AgentAssignmentsView>> {
  bool _disposed = false;

  @override
  ViewState<AgentAssignmentsView> build() {
    ref.onDispose(() => _disposed = true);
    Future.microtask(load);
    return const ViewState.loadingFirst();
  }

  Future<void> load({String? notice, bool noticeIsError = false}) async {
    final existing = state.dataOrNull;
    _set(
      existing == null
          ? const ViewState.loadingFirst()
          : ViewState.loadingRefresh(existing),
    );
    final result = await ref.read(agentAssignmentRepositoryProvider).load();
    if (_disposed) return;
    switch (result) {
      case Ok(:final value):
        _set(
          ViewState.data(
            AgentAssignmentsView(
              items: value,
              notice: notice,
              noticeIsError: noticeIsError,
            ),
          ),
        );
      case Err(:final failure):
        _set(ViewState.fromFailure<AgentAssignmentsView>(failure));
    }
  }

  Future<void> accept(String assignmentId) {
    return _respond(assignmentId, accept: true);
  }

  Future<void> decline(String assignmentId, String? reason) {
    return _respond(assignmentId, accept: false, reason: reason);
  }

  Future<void> _respond(
    String assignmentId, {
    required bool accept,
    String? reason,
  }) async {
    final existing = state.dataOrNull;
    if (existing == null || state is ViewSubmitting<AgentAssignmentsView>) {
      return;
    }
    _set(
      ViewState.submitting(
        existing.copyWith(submittingId: assignmentId, clearNotice: true),
      ),
    );

    final repository = ref.read(agentAssignmentRepositoryProvider);
    final result = accept
        ? await repository.accept(assignmentId)
        : await repository.decline(assignmentId, reason);
    if (_disposed) return;

    switch (result) {
      case Ok():
        await load(
          notice: accept
              ? 'Invitation accepted. Your access is now connected.'
              : 'Invitation declined.',
        );
      case Err(:final failure):
        if (failure is AuthFailure || failure is AccountBlockedFailure) {
          _set(ViewState.fromFailure<AgentAssignmentsView>(failure));
          return;
        }
        await load(notice: failure.message, noticeIsError: true);
    }
  }

  void _set(ViewState<AgentAssignmentsView> next) {
    if (!_disposed) state = next;
  }
}
