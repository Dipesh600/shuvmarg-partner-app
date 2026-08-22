import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../domain/app_role.dart';
import '../config/app_environment.dart';
import '../errors/error_mapper.dart';
import '../errors/failure.dart';
import '../errors/result.dart';
import '../storage/session_store.dart';
import 'interceptors/auth_interceptor.dart';

/// A decoded JSON object.
typedef JsonMap = Map<String, dynamic>;

/// ─────────────────────────────────────────────────────────────────────────────
/// Shuvmarg Partner — ApiService
///
/// The single network entry point (production_project_rules.md §4.2). No widget,
/// controller or repository constructs a `Dio`, an `HttpClient` or an `http`
/// call of its own; everything goes through here, so auth, role selection,
/// timeouts, refresh and error mapping are applied uniformly and can be changed
/// in one place.
///
/// It returns [Result] and never throws. Callers cannot forget to handle failure,
/// because the failure is in the return type.
///
/// This is an instance, not a bag of statics. The previous implementation was
/// entirely static, which made it impossible to inject a fake in a test or to run
/// two configurations side by side.
///
/// Response parsing is *not* done here. Methods hand back a [JsonMap] and each
/// repository maps it to its own model with `Result.map`, which keeps endpoint
/// knowledge next to the feature that owns it.
/// ─────────────────────────────────────────────────────────────────────────────
class ApiService {
  ApiService({
    required SessionStore store,
    required Future<void> Function() onSessionExpired,
    Dio? client,
  }) : _store = store,
       _dio = client ?? Dio(_baseOptions()) {
    _dio.interceptors.add(AuthHeaderInterceptor(_store));
    _dio.interceptors.add(
      TokenRefreshInterceptor(
        store: _store,
        client: _dio,
        onSessionExpired: onSessionExpired,
      ),
    );
    if (AppEnvironment.verboseNetworkLogs) {
      _dio.interceptors.add(_RedactingLogInterceptor());
    }
  }

  final SessionStore _store;
  final Dio _dio;

  static BaseOptions _baseOptions() => BaseOptions(
    baseUrl: AppEnvironment.baseUrl,
    connectTimeout: AppEnvironment.connectTimeout,
    receiveTimeout: AppEnvironment.receiveTimeout,
    sendTimeout: AppEnvironment.receiveTimeout,
    contentType: Headers.jsonContentType,
    responseType: ResponseType.json,
    // Non-2xx must raise, so it reaches the refresh interceptor and the error
    // mapper. The previous client accepted every status and decoded the body
    // regardless, which is how a 403 came back looking like data.
    validateStatus: (status) => status != null && status >= 200 && status < 300,
  );

  // ───────────────────────────────────────────────────────────────────────────
  // JSON verbs
  // ───────────────────────────────────────────────────────────────────────────

  Future<Result<JsonMap>> get(
    String path, {
    JsonMap? query,
    bool authenticated = true,
    AppRole? appSource,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.get<dynamic>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated, appSource: appSource),
      ),
    );
  }

  Future<Result<JsonMap>> post(
    String path, {
    Object? body,
    JsonMap? query,
    bool authenticated = true,
    AppRole? appSource,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.post<dynamic>(
        path,
        data: body,
        queryParameters: query,
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated, appSource: appSource),
      ),
    );
  }

  Future<Result<JsonMap>> put(
    String path, {
    Object? body,
    bool authenticated = true,
    AppRole? appSource,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.put<dynamic>(
        path,
        data: body,
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated, appSource: appSource),
      ),
    );
  }

  Future<Result<JsonMap>> patch(
    String path, {
    Object? body,
    bool authenticated = true,
    AppRole? appSource,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.patch<dynamic>(
        path,
        data: body,
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated, appSource: appSource),
      ),
    );
  }

  Future<Result<JsonMap>> delete(
    String path, {
    Object? body,
    bool authenticated = true,
    AppRole? appSource,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.delete<dynamic>(
        path,
        data: body,
        cancelToken: cancelToken,
        options: _options(authenticated: authenticated, appSource: appSource),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Multipart upload
  // ───────────────────────────────────────────────────────────────────────────

  /// Sends a `multipart/form-data` request, used for KYC document upload.
  ///
  /// [buildForm] is a factory rather than a value on purpose. A [FormData] body
  /// is a single-use stream — once its file parts have been read they cannot be
  /// replayed — so an access token that expires mid-upload cannot be recovered by
  /// the refresh interceptor's generic replay. Given a builder, this method
  /// rebuilds the body and re-sends once after the interceptor has obtained a new
  /// token, which turns an unavoidable 401 into a delay instead of a lost upload.
  Future<Result<JsonMap>> upload(
    String path, {
    required FormData Function() buildForm,
    bool authenticated = true,
    AppRole? appSource,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    Future<Result<JsonMap>> attempt() => _send(
      () => _dio.post<dynamic>(
        path,
        data: buildForm(),
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: _options(
          authenticated: authenticated,
          appSource: appSource,
          // Uploads run over mobile networks and need a longer window than the
          // default read timeout allows.
          sendTimeout: AppEnvironment.uploadTimeout,
          receiveTimeout: AppEnvironment.uploadTimeout,
        ),
      ),
    );

    final tokenBefore = _store.cached?.accessToken;
    final first = await attempt();

    final failure = first.failureOrNull;
    final tokenChanged = _store.cached?.accessToken != tokenBefore;

    // Retry only when the token demonstrably changed underneath us — i.e. the
    // interceptor refreshed successfully but could not replay a stream body.
    // Without that check a genuine 401 would be retried pointlessly.
    if (failure is AuthFailure && tokenChanged && _store.cached != null) {
      return attempt();
    }
    return first;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Binary download
  // ───────────────────────────────────────────────────────────────────────────

  /// Fetches raw bytes — used for `/api/agent/documents/view`, an authenticated
  /// proxy that streams an uploaded document.
  ///
  /// It has to go through this service rather than a plain image URL because the
  /// request needs the bearer token; documents are never publicly readable.
  Future<Result<Uint8List>> getBytes(
    String path, {
    JsonMap? query,
    bool authenticated = true,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        cancelToken: cancelToken,
        options: _options(
          authenticated: authenticated,
        ).copyWith(responseType: ResponseType.bytes),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        return const Err(
          ServerFailure(message: 'The server returned an empty document.'),
        );
      }
      return Ok(Uint8List.fromList(data));
    } on DioException catch (error) {
      return Err(ErrorMapper.fromDio(error));
    } catch (error) {
      return Err(ErrorMapper.fromUnexpected(error));
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Internals
  // ───────────────────────────────────────────────────────────────────────────

  Options _options({
    required bool authenticated,
    AppRole? appSource,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) {
    return Options(
      sendTimeout: sendTimeout,
      receiveTimeout: receiveTimeout,
      extra: {
        AuthExtras.skipAuth: !authenticated,
        AuthExtras.appSource: ?appSource,
      },
    );
  }

  /// Runs [request] and normalises every outcome into a [Result].
  ///
  /// Nothing escapes: a transport error, a non-2xx status and an undecodable body
  /// all become a [Failure]. This is the boundary that keeps raw exceptions out
  /// of the widget tree.
  Future<Result<JsonMap>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      final body = ErrorMapper.readJsonBody(response.data);

      if (body.isEmpty && response.data != null) {
        // A 2xx whose body is not a JSON object — typically an HTML page from a
        // proxy or tunnel. The previous client called `json.decode` on this
        // unguarded and threw a FormatException out of a widget build.
        return const Err(
          ServerFailure(
            message: 'The server sent an unexpected response. Please try again.',
          ),
        );
      }

      // A handful of endpoints answer 2xx while reporting `success: false`.
      // Honour the flag: the status alone would make this look like data.
      if (body['success'] == false) {
        final message = body['message'];
        return Err(
          UnknownFailure(
            message: message is String && message.trim().isNotEmpty
                ? message.trim()
                : 'The request could not be completed. Please try again.',
            statusCode: response.statusCode,
            data: body,
          ),
        );
      }

      return Ok(body);
    } on DioException catch (error) {
      return Err(ErrorMapper.fromDio(error));
    } catch (error) {
      return Err(ErrorMapper.fromUnexpected(error));
    }
  }

  /// Cancels in-flight requests and releases the underlying client.
  void dispose() => _dio.close(force: true);
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Debug-only request log.
///
/// Dio's bundled `LogInterceptor` prints all headers, which puts bearer tokens in
/// the console and from there into shared screenshots and pasted logs. This one
/// logs the same shape with credentials redacted, and is only installed when
/// [AppEnvironment.verboseNetworkLogs] is true — never in a release build.
/// ─────────────────────────────────────────────────────────────────────────────
class _RedactingLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    final source = options.headers['X-App-Source'];
    if (source != null) debugPrint('   X-App-Source: $source');
    if (options.headers.containsKey('Authorization')) {
      debugPrint('   Authorization: Bearer <redacted>');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '✗ ${err.response?.statusCode ?? err.type.name} '
      '${err.requestOptions.method} ${err.requestOptions.path}',
    );
    final code = ErrorMapper.readJsonBody(err.response?.data)['errorCode'];
    if (code != null) debugPrint('   errorCode: $code');
    handler.next(err);
  }
}
