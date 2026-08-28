import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/core/errors/error_mapper.dart';
import 'package:shuvmarg_partner_app/core/errors/failure.dart';

void main() {
  test('ACCOUNT_NOT_ACTIVATED is routed to self-service activation', () {
    final request = RequestOptions(path: '/api/login');
    final failure = ErrorMapper.fromDio(
      DioException(
        requestOptions: request,
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
          requestOptions: request,
          statusCode: 403,
          data: const {
            'success': false,
            'message': 'Your account has not been activated yet.',
            'errorCode': 'ACCOUNT_NOT_ACTIVATED',
          },
        ),
      ),
    );

    expect(failure, isA<AccountBlockedFailure>());
    expect((failure as AccountBlockedFailure).isActivatable, isTrue);
  });
}
