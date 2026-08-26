import 'package:flutter/foundation.dart';

import 'failure.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — Result
///
/// Every repository and API method returns `Result<T>` instead of throwing.
/// Exceptions escaping into widget code is what produced the red error screens
/// the redesign brief calls out; making failure part of the return type means the
/// analyser will not let a call site forget it exists.
///
/// Usage:
/// ```dart
/// switch (await repo.loadDashboard()) {
///   case Ok(:final value): state = Data(value);
///   case Err(:final failure): state = ErrorState(failure);
/// }
/// ```
/// ─────────────────────────────────────────────────────────────────────────────
@immutable
sealed class Result<T> {
  const Result();

  /// Wraps [value] as a success.
  const factory Result.ok(T value) = Ok<T>;

  /// Wraps [failure] as a failure.
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// The value, or `null` on failure.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure, or `null` on success.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// Collapses both branches into a single value.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };

  /// Transforms a success value, passing failures through untouched.
  ///
  /// Used to keep parsing next to the call rather than inside `ApiService`:
  /// ```dart
  /// final result = (await api.get(ApiPaths.agentDashboard))
  ///     .map(AgentDashboard.fromJson);
  /// ```
  /// If [transform] throws, the throw becomes a [ServerFailure] — a bad payload
  /// is a server problem, not a crash.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Err<T>(:final failure) => Err<R>(failure),
    Ok<T>(:final value) => _guard(() => transform(value)),
  };

  static Result<R> _guard<R>(R Function() body) {
    try {
      return Ok<R>(body());
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Result.map: payload parse failed: $error\n$stack');
      }
      return Err<R>(
        ServerFailure(
          message: 'We could not read the response from the server.',
          cause: error,
        ),
      );
    }
  }
}

/// A successful [Result].
@immutable
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';

  @override
  bool operator ==(Object other) =>
      other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T>, value);
}

/// A failed [Result].
@immutable
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  String toString() => 'Err($failure)';

  @override
  bool operator ==(Object other) =>
      other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err<T>, failure);
}
