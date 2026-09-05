import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/result.dart';
import '../../domain/driver_profile.dart';
import '../../shared/session/session_providers.dart';
import '../../shared/state/view_state.dart';
import 'driver_profile_repository.dart';

final driverProfileRepositoryProvider = Provider<DriverProfileGateway>((ref) {
  return DriverProfileRepository(ref.watch(apiServiceProvider));
});

final driverProfileControllerProvider =
    NotifierProvider.autoDispose<
      DriverProfileController,
      ViewState<DriverProfile>
    >(DriverProfileController.new);

class DriverProfileController
    extends AutoDisposeNotifier<ViewState<DriverProfile>> {
  bool _disposed = false;

  @override
  ViewState<DriverProfile> build() {
    ref.onDispose(() => _disposed = true);
    Future.microtask(load);
    return const ViewState.loadingFirst();
  }

  Future<void> load() async {
    final existing = state.dataOrNull;
    _set(
      existing == null
          ? const ViewState.loadingFirst()
          : ViewState.loadingRefresh(existing),
    );

    final result = await ref.read(driverProfileRepositoryProvider).load();
    if (_disposed) return;
    switch (result) {
      case Ok(:final value):
        _set(ViewState.data(value));
      case Err(:final failure):
        _set(ViewState.fromFailure<DriverProfile>(failure));
    }
  }

  void _set(ViewState<DriverProfile> next) {
    if (!_disposed) state = next;
  }
}
