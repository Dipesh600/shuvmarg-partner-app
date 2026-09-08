import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('staging uses the shared Shuvmarg staging backend', () {
      expect(
        AppEnvironment.resolveBaseUrl(selectedFlavor: AppFlavor.staging),
        'https://api-staging.shuvmarg.com',
      );
    });

    test('production remains isolated from staging', () {
      expect(
        AppEnvironment.resolveBaseUrl(selectedFlavor: AppFlavor.production),
        'https://api.shuvmarg.com',
      );
    });

    test('an explicit development override is normalized', () {
      expect(
        AppEnvironment.resolveBaseUrl(
          selectedFlavor: AppFlavor.local,
          override: ' http://192.168.1.20:7012/ ',
        ),
        'http://192.168.1.20:7012',
      );
    });
  });
}
