import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/core/network/interceptors/auth_interceptor.dart';

void main() {
  test('captures every refresh-cookie name used by the backend portals', () {
    for (final name in [
      'agentRefreshToken',
      'driverRefreshToken',
      'busOwnerRefreshToken',
      'passengerRefreshToken',
      'refreshToken',
    ]) {
      final headers = Headers.fromMap({
        'set-cookie': ['$name=token-for-$name; HttpOnly; SameSite=Lax'],
      });

      expect(
        AuthHeaderInterceptor.readRefreshCookie(headers),
        'token-for-$name',
        reason: 'the $name cookie must keep its portal session renewable',
      );
    }
  });

  test('does not accept lookalike or cleared refresh cookies', () {
    final lookalike = Headers.fromMap({
      'set-cookie': ['notAgentRefreshToken=attacker-value; HttpOnly'],
    });
    final cleared = Headers.fromMap({
      'set-cookie': ['agentRefreshToken=; Max-Age=0; HttpOnly'],
    });

    expect(AuthHeaderInterceptor.readRefreshCookie(lookalike), isNull);
    expect(AuthHeaderInterceptor.readRefreshCookie(cleared), isNull);
  });
}
