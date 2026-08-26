import 'package:dio/dio.dart';

import 'backend_error_code.dart';
import 'failure.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — error mapper
///
/// The single place a transport-level problem becomes a domain [Failure].
/// Keeping it in one function means every screen gets the same interpretation of
/// the same response, and the mapping can be corrected in one edit.
///
/// Two rules this enforces that the previous client broke:
///
///   1. **The status code is read before the body is trusted.** Previously a 403
///      body was `json.decode`d and returned as a success value, so an
///      authorisation error looked like data.
///   2. **A non-JSON body never escapes as an exception.** Proxies and tunnels
///      return HTML; that becomes a [ServerFailure] with a readable message
///      rather than a `FormatException` thrown during a widget build.
/// ─────────────────────────────────────────────────────────────────────────────
abstract final class ErrorMapper {
  /// Converts a Dio exception into the matching [Failure].
  static Failure fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(
          message:
              'The connection timed out. Check your signal and try again.',
          isTimeout: true,
          cause: error,
        );

      case DioExceptionType.connectionError:
        return NetworkFailure(
          message:
              'We could not reach Shuvmarg. Check your internet connection.',
          cause: error,
        );

      case DioExceptionType.badCertificate:
        return NetworkFailure(
          message: 'The secure connection to Shuvmarg could not be verified.',
          cause: error,
        );

      case DioExceptionType.cancel:
        return CancelledFailure(cause: error);

      case DioExceptionType.badResponse:
        return _fromResponse(error.response!, error);

      case DioExceptionType.unknown:
        // Dio funnels a decode failure on an otherwise-OK response here, along
        // with anything it could not classify.
        return UnknownFailure(
          message: 'Something went wrong. Please try again.',
          statusCode: error.response?.statusCode,
          cause: error,
        );
    }
  }

  /// Converts an unexpected non-Dio throw (a parse bug, a plugin failure).
  static Failure fromUnexpected(Object error) => UnknownFailure(
    message: 'Something went wrong. Please try again.',
    cause: error,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // Response mapping
  // ───────────────────────────────────────────────────────────────────────────

  static Failure _fromResponse(Response<dynamic> response, Object? cause) {
    final status = response.statusCode ?? 0;
    final body = readJsonBody(response.data);
    final rawCode = _stringOrNull(body['errorCode']);
    final code = BackendErrorCode.parse(rawCode);
    final message = _stringOrNull(body['message']) ?? _defaultMessageFor(status);

    // The error code, where present, is more specific than the status code —
    // ACCOUNT_LOCKED arrives as a 429 but is a lockout, not a rate limit.
    if (code.isAccountBlocked) {
      final contact = _mapOrEmpty(body['contact']);
      return AccountBlockedFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
        reason: _stringOrNull(body['reason']),
        blockedAt: _dateOrNull(body['suspendedAt'] ?? body['bannedAt']),
        supportEmail: _stringOrNull(contact['email']),
        supportPhone: _stringOrNull(contact['phone']),
      );
    }

    if (code.isThrottled || status == 429) {
      return ThrottledFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
        retryAfter: _retryAfterOf(response),
      );
    }

    return switch (status) {
      400 || 422 => ValidationFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
      ),
      401 => AuthFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
        cause: cause,
      ),
      403 => ForbiddenFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
      ),
      404 => NotFoundFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
      ),
      >= 500 => ServerFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
        cause: cause,
      ),
      _ => UnknownFailure(
        message: message,
        code: code,
        rawCode: rawCode,
        statusCode: status,
        data: body,
        cause: cause,
      ),
    };
  }

  /// Coerces a response body into a JSON object.
  ///
  /// Returns an empty map for anything that is not one — HTML from a proxy, a
  /// bare string, `null`, or a top-level list. The caller then falls back to a
  /// status-derived message instead of showing markup to the user.
  static Map<String, dynamic> readJsonBody(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return const {};
  }

  static String _defaultMessageFor(int status) => switch (status) {
    400 || 422 => 'Please check the details you entered and try again.',
    401 => 'Your session has expired. Please sign in again.',
    403 => 'You do not have access to this.',
    404 => 'We could not find what you were looking for.',
    408 => 'The request took too long. Please try again.',
    409 => 'That conflicts with something already saved.',
    413 => 'That file is too large to upload.',
    429 => 'Too many attempts. Please wait a moment and try again.',
    >= 500 => 'Shuvmarg is having trouble right now. Please try again shortly.',
    _ => 'Something went wrong. Please try again.',
  };

  /// Reads `Retry-After`.
  ///
  /// Only the delta-seconds form is handled, which is what `express-rate-limit`
  /// emits. The HTTP-date form returns `null`; screens must already cope with a
  /// missing value because account lockout puts the wait in the message instead.
  static Duration? _retryAfterOf(Response<dynamic> response) {
    final raw = response.headers.value('retry-after');
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    if (seconds == null || seconds <= 0) return null;
    return Duration(seconds: seconds);
  }

  static String? _stringOrNull(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return const {};
  }

  static DateTime? _dateOrNull(dynamic value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
