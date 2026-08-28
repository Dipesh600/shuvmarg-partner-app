import '../../core/errors/failure.dart';
import '../../core/errors/result.dart';
import '../../domain/app_role.dart';
import '../../domain/session.dart';

Result<Session> sessionFromResponse(
  Map<String, dynamic> body, {
  required AppRole fallbackRole,
  required String? refreshToken,
}) {
  final accessToken = body['accessToken'];
  if (accessToken is! String || accessToken.isEmpty) {
    return const Result.err(
      ServerFailure(
        message:
            'The server did not return a usable session. Please try again.',
      ),
    );
  }

  final rawUser = body['user'];
  if (rawUser is! Map) {
    return const Result.err(
      ServerFailure(
        message: 'The server returned an unexpected account response.',
      ),
    );
  }

  try {
    final roleValue = body['activeRole'];
    final role =
        AppRole.tryParse(roleValue is String ? roleValue : null) ??
        fallbackRole;
    return Result.ok(
      Session(
        accessToken: accessToken,
        activeRole: role,
        user: AuthenticatedUser.fromJson(rawUser.cast<String, dynamic>()),
        refreshToken: refreshToken,
      ),
    );
  } catch (error) {
    return Result.err(
      ServerFailure(
        message: 'The server returned an unexpected account response.',
        cause: error,
      ),
    );
  }
}
