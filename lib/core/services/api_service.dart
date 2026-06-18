import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shuvmarg_partner_app/core/services/api_endpoints.dart';

/// Lightweight HTTP wrapper — plain `http` package (no Dio complexity needed).
/// Automatically attaches:
///   • Content-Type: application/json
///   • X-App-Source: agent   (so the backend knows this is the partner app)
///   • Authorization: Bearer <token>  when [token] is provided
class ApiService {
  ApiService._();

  static const _headers = {
    'Content-Type': 'application/json',
    'X-App-Source': 'agent',
  };

  static const _timeout = Duration(seconds: 15);

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // ── Unauthenticated POST ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String url,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: _headers,
          body: json.encode(body),
        )
        .timeout(
          _timeout,
          onTimeout: () => throw Exception('Request timed out. Check your connection.'),
        );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ── Authenticated POST ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authPost(
    String url,
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await http
        .post(
          Uri.parse(url),
          headers: _authHeaders(token),
          body: json.encode(body),
        )
        .timeout(
          _timeout,
          onTimeout: () => throw Exception('Request timed out. Check your connection.'),
        );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ── Authenticated GET ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authGet(
    String url,
    String token,
  ) async {
    final response = await http
        .get(Uri.parse(url), headers: _authHeaders(token))
        .timeout(
          _timeout,
          onTimeout: () => throw Exception('Request timed out. Check your connection.'),
        );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ── Unauthenticated GET ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(String url) async {
    final response = await http
        .get(Uri.parse(url), headers: _headers)
        .timeout(
          _timeout,
          onTimeout: () => throw Exception('Request timed out. Check your connection.'),
        );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ── Authenticated PATCH ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> authPatch(
    String url,
    Map<String, dynamic> body,
    String token,
  ) async {
    final response = await http.patch(
      Uri.parse(url),
      headers: _authHeaders(token),
      body: json.encode(body),
    );
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // ── Multipart upload (for document/file upload) ───────────────────────────
  static Future<Map<String, dynamic>> authMultipart({
    required String url,
    required String token,
    required File file,
    required Map<String, String> fields,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll({
      'X-App-Source': 'agent',
      'Authorization': 'Bearer $token',
    });
    request.fields.addAll(fields);

    // Detect MIME type from file extension
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType(mimeParts[0], mimeParts[1]),
    ));

    final streamed = await request.send().timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw Exception('Upload timed out. Check your connection.'),
    );
    final body = await streamed.stream.bytesToString();
    return json.decode(body) as Map<String, dynamic>;
  }
}

// ── Auth-specific API methods ────────────────────────────────────────────────

class AuthApi {
  AuthApi._();

  static Future<Map<String, dynamic>> sendPhoneOtp(String phone) =>
      ApiService.post(ApiEndpoints.sendPhoneOtp, {'phone': phone});

  static Future<Map<String, dynamic>> verifyPhoneOtp(String phone, String otp) =>
      ApiService.post(ApiEndpoints.verifyPhoneOtp, {'phone': phone, 'otp': otp});

  static Future<Map<String, dynamic>> completeRegistration({
    required String phone,
    required String name,
    String? password,        // null for existing users (upgrade path)
    String? email,
    String address = 'Nepal',
    String gender = 'male',
  }) =>
      ApiService.post(ApiEndpoints.completeRegistration, {
        'phone': phone,
        'name': name,
        'address': address,
        'gender': gender,
        // Only send password for new user path — backend ignores it on upgrade
        if (password != null && password.isNotEmpty) 'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      });

  static Future<Map<String, dynamic>> login(String phone, String password) =>
      ApiService.post(ApiEndpoints.login, {
        'emailOrPhone': phone,
        'password': password,
      });

  static Future<Map<String, dynamic>> resendOtp(
          String phone, String purpose) =>
      ApiService.post(ApiEndpoints.resendOtp, {
        'phone': phone,
        'purpose': purpose,
      });

  static Future<Map<String, dynamic>> requestPasswordReset(String phone) =>
      ApiService.post(
          ApiEndpoints.requestPasswordReset, {'emailOrPhone': phone});

  static Future<Map<String, dynamic>> verifyOtpForReset(
          String phone, String otp) =>
      ApiService.post(
          ApiEndpoints.verifyOtpForReset, {'emailOrPhone': phone, 'otp': otp});

  static Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) =>
      ApiService.post(ApiEndpoints.resetPassword, {
        'emailOrPhone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });
}

// ── Agent Application API methods ────────────────────────────────────────────

class AgentApi {
  AgentApi._();

  /// Save draft data for any step. Partial data is fine — only provided
  /// fields are updated on the server.
  static Future<Map<String, dynamic>> saveDraft(
    Map<String, dynamic> data,
    String token,
  ) =>
      ApiService.authPost(ApiEndpoints.agentAppSave, data, token);

  /// Upload a single KYC document as multipart/form-data.
  /// [documentType] must be one of: citizenship_front, citizenship_back,
  /// shop_photo, pan_card, business_registration
  static Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String documentType,
    required String token,
  }) =>
      ApiService.authMultipart(
        url: ApiEndpoints.agentAppDocument,
        token: token,
        file: file,
        fields: {'documentType': documentType},
      );

  /// Submit the completed application for admin review.
  static Future<Map<String, dynamic>> submitApplication(String token) =>
      ApiService.authPost(ApiEndpoints.agentAppSubmit, {}, token);

  /// Get current application status + all saved data.
  static Future<Map<String, dynamic>> getStatus(String token) =>
      ApiService.authGet(ApiEndpoints.agentAppStatus, token);

  /// Get agent profile (post-approval only).
  static Future<Map<String, dynamic>> getProfile(String token) =>
      ApiService.authGet(ApiEndpoints.agentProfile, token);

  /// Get dashboard stats (post-approval only).
  static Future<Map<String, dynamic>> getDashboard(String token) =>
      ApiService.authGet(ApiEndpoints.agentDashboard, token);
}
