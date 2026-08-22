import 'package:flutter/foundation.dart';

import '../../core/errors/failure.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — canonical async screen state
///
/// Every data-backed screen renders exactly one of these. Making the states a
/// sealed set means a screen's `switch` is exhaustive — a new state cannot be
/// added without the analyser flagging every screen that has not handled it —
/// and it removes the "three separate booleans" bug class (`isLoading`,
/// `hasError`, `data != null`) that let the old build show a spinner and an
/// error at once, or data underneath a spinner.
///
/// The distinction the old build lacked and this encodes:
///   • [ViewLoadingFirst] — nothing to show yet → skeleton.
///   • [ViewLoadingRefresh] — we already have data and are refetching → keep the
///     data on screen with a quiet indicator, never blank it.
/// The same split applies to failure: an [ViewErrorAuth] sends the user to
/// sign-in, an [ViewOffline] shows a reconnect banner, an [ViewErrorForbidden]
/// shows a support/gate card — three different shapes, not one red string.
///
/// [T] is the loaded payload (a model, a list, a record). States that predate a
/// successful load carry no payload; [ViewLoadingRefresh] and [ViewSubmitting]
/// carry the last-known [data] so the screen need not blank while working.
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
sealed class ViewState<T> {
  const ViewState();

  /// Nothing has been requested yet. Distinct from loading so a screen can, for
  /// example, wait for a parameter before its first fetch.
  const factory ViewState.initial() = ViewInitial<T>;

  /// First load, no data to show → skeleton.
  const factory ViewState.loadingFirst() = ViewLoadingFirst<T>;

  /// Refetching while [data] is already on screen → keep it, show a quiet
  /// indicator rather than a skeleton.
  const factory ViewState.loadingRefresh(T data) = ViewLoadingRefresh<T>;

  /// Loaded successfully.
  const factory ViewState.data(T data) = ViewData<T>;

  /// Loaded successfully but there is nothing to show. Carries screen-specific
  /// [message] copy ("No bookings yet") rather than a generic blank.
  const factory ViewState.empty([String? message]) = ViewEmpty<T>;

  /// A failure the user can retry directly (5xx, unknown, timeout that isn't a
  /// connectivity drop). The screen offers a "Try again" button.
  const factory ViewState.errorRetryable(Failure failure) =
      ViewErrorRetryable<T>;

  /// The session is gone. The screen routes to sign-in; it does not offer retry.
  const factory ViewState.errorAuth(Failure failure) = ViewErrorAuth<T>;

  /// Authorised-but-forbidden: a blocked account or an unapproved agent gate.
  /// The screen shows a support/gate card, not a retry button.
  const factory ViewState.errorForbidden(Failure failure) =
      ViewErrorForbidden<T>;

  /// No usable connection. The screen shows an offline banner and retries on
  /// reconnect. Carries the [failure] so copy can distinguish a timeout.
  const factory ViewState.offline(Failure failure) = ViewOffline<T>;

  /// A write is in flight (submit, save, confirm). Carries the last-known
  /// [data] so a screen that submits over existing content keeps showing it.
  const factory ViewState.submitting([T? data]) = ViewSubmitting<T>;

  /// A submit was rejected for the request's contents. [failure] carries the
  /// backend message; [fieldErrors] maps a field name to its error where the
  /// endpoint's shape is known (empty otherwise — see [ValidationFailure]).
  const factory ViewState.submitFieldErrors(
    Failure failure, [
    Map<String, String> fieldErrors,
  ]) = ViewSubmitFieldErrors<T>;

  /// The loaded payload where this state carries one, else `null`.
  ///
  /// Lets a widget read data without re-matching in cases where "show data if
  /// we have any" is the whole rule.
  T? get dataOrNull => switch (this) {
    ViewData<T>(:final data) => data,
    ViewLoadingRefresh<T>(:final data) => data,
    ViewSubmitting<T>(:final data) => data,
    _ => null,
  };

  /// Whether any load or write is in flight.
  bool get isBusy => switch (this) {
    ViewLoadingFirst<T>() ||
    ViewLoadingRefresh<T>() ||
    ViewSubmitting<T>() => true,
    _ => false,
  };

  /// Maps a [Failure] to the right *load* failure state.
  ///
  /// This is the single place the failure taxonomy is turned into UI intent, so
  /// every screen treats an auth failure, an offline drop and a forbidden gate
  /// the same way. Submit flows use [fromSubmitFailure] instead, which keeps the
  /// current [data] visible behind the error.
  ///
  ///   • [NetworkFailure]           → [ViewOffline]
  ///   • [AuthFailure]              → [ViewErrorAuth]
  ///   • [ForbiddenFailure],
  ///     [AccountBlockedFailure]    → [ViewErrorForbidden]
  ///   • everything else            → [ViewErrorRetryable]
  static ViewState<T> fromFailure<T>(Failure failure) => switch (failure) {
    NetworkFailure() => ViewOffline<T>(failure),
    AuthFailure() => ViewErrorAuth<T>(failure),
    ForbiddenFailure() || AccountBlockedFailure() => ViewErrorForbidden<T>(
      failure,
    ),
    _ => ViewErrorRetryable<T>(failure),
  };
}

/// See [ViewState.initial].
final class ViewInitial<T> extends ViewState<T> {
  const ViewInitial();

  @override
  bool operator ==(Object other) => other is ViewInitial<T>;

  @override
  int get hashCode => (ViewInitial<T>).hashCode;
}

/// See [ViewState.loadingFirst].
final class ViewLoadingFirst<T> extends ViewState<T> {
  const ViewLoadingFirst();

  @override
  bool operator ==(Object other) => other is ViewLoadingFirst<T>;

  @override
  int get hashCode => (ViewLoadingFirst<T>).hashCode;
}

/// See [ViewState.loadingRefresh].
final class ViewLoadingRefresh<T> extends ViewState<T> {
  const ViewLoadingRefresh(this.data);

  final T data;

  @override
  bool operator ==(Object other) =>
      other is ViewLoadingRefresh<T> && other.data == data;

  @override
  int get hashCode => Object.hash(ViewLoadingRefresh<T>, data);
}

/// See [ViewState.data].
final class ViewData<T> extends ViewState<T> {
  const ViewData(this.data);

  final T data;

  @override
  bool operator ==(Object other) => other is ViewData<T> && other.data == data;

  @override
  int get hashCode => Object.hash(ViewData<T>, data);
}

/// See [ViewState.empty].
final class ViewEmpty<T> extends ViewState<T> {
  const ViewEmpty([this.message]);

  /// Screen-specific empty copy, or `null` for the screen's default.
  final String? message;

  @override
  bool operator ==(Object other) =>
      other is ViewEmpty<T> && other.message == message;

  @override
  int get hashCode => Object.hash(ViewEmpty<T>, message);
}

/// See [ViewState.errorRetryable].
final class ViewErrorRetryable<T> extends ViewState<T> {
  const ViewErrorRetryable(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is ViewErrorRetryable<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(ViewErrorRetryable<T>, failure);
}

/// See [ViewState.errorAuth].
final class ViewErrorAuth<T> extends ViewState<T> {
  const ViewErrorAuth(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is ViewErrorAuth<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(ViewErrorAuth<T>, failure);
}

/// See [ViewState.errorForbidden].
final class ViewErrorForbidden<T> extends ViewState<T> {
  const ViewErrorForbidden(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is ViewErrorForbidden<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(ViewErrorForbidden<T>, failure);
}

/// See [ViewState.offline].
final class ViewOffline<T> extends ViewState<T> {
  const ViewOffline(this.failure);

  final Failure failure;

  @override
  bool operator ==(Object other) =>
      other is ViewOffline<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(ViewOffline<T>, failure);
}

/// See [ViewState.submitting].
final class ViewSubmitting<T> extends ViewState<T> {
  const ViewSubmitting([this.data]);

  /// Last-known data to keep on screen behind the in-flight write, if any.
  final T? data;

  @override
  bool operator ==(Object other) =>
      other is ViewSubmitting<T> && other.data == data;

  @override
  int get hashCode => Object.hash(ViewSubmitting<T>, data);
}

/// See [ViewState.submitFieldErrors].
final class ViewSubmitFieldErrors<T> extends ViewState<T> {
  const ViewSubmitFieldErrors(this.failure, [this.fieldErrors = const {}]);

  final Failure failure;

  /// Field name → message, where the endpoint's error shape is known. Empty
  /// when the backend gave only a top-level message.
  final Map<String, String> fieldErrors;

  @override
  bool operator ==(Object other) =>
      other is ViewSubmitFieldErrors<T> &&
      other.failure == failure &&
      mapEquals(other.fieldErrors, fieldErrors);

  @override
  int get hashCode =>
      Object.hash(ViewSubmitFieldErrors<T>, failure, Object.hashAllUnordered(
        fieldErrors.entries.map((e) => Object.hash(e.key, e.value)),
      ));
}
