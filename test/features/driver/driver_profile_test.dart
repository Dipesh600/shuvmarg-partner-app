import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/domain/driver_profile.dart';
import 'package:shuvmarg_partner_app/domain/session.dart';
import 'package:shuvmarg_partner_app/features/driver/driver_home_screen.dart';
import 'package:shuvmarg_partner_app/features/driver/driver_profile_controller.dart';
import 'package:shuvmarg_partner_app/shared/session/session_controller.dart';
import 'package:shuvmarg_partner_app/shared/session/session_providers.dart';
import 'package:shuvmarg_partner_app/shared/session/session_state.dart';
import 'package:shuvmarg_partner_app/shared/state/view_state.dart';

const _sharedUser = AuthenticatedUser(
  id: 'user-1',
  name: 'Bijay chaudhary',
  phone: '9863053420',
  roles: ['passenger', 'agent', 'driver'],
  isVerified: true,
);

final _driverProfile = DriverProfile.fromJson({
  'driverId': 'driver-1',
  'fullName': 'dipesh chaudhary',
  'phone': '9863053420',
  'email': null,
  'gender': 'male',
  'experienceYears': 4,
  'brand': {'id': 'brand-1', 'name': 'Dai Bhai Travels', 'code': 'DBT'},
  'operationalStatus': 'AVAILABLE',
  'accessStatus': 'ACTIVE',
  'license': {
    'number': '34554677887987',
    'type': 'HV',
    'expiry': '2029-07-20T00:00:00.000Z',
    'documentUploaded': true,
  },
  'medicalCertificate': {'expiry': null, 'documentUploaded': false},
});

class _SignedInDriverController extends SessionController {
  @override
  SessionState build() => const SessionSignedIn(
    session: Session(
      accessToken: 'token',
      activeRole: AppRole.driver,
      user: _sharedUser,
    ),
  );
}

class _FixedDriverProfileController extends DriverProfileController {
  @override
  ViewState<DriverProfile> build() => ViewState.data(_driverProfile);
}

void main() {
  test('parses the complete Driver profile without document storage data', () {
    expect(_driverProfile.fullName, 'dipesh chaudhary');
    expect(_driverProfile.experienceYears, 4);
    expect(_driverProfile.license.number, '34554677887987');
    expect(_driverProfile.license.type, 'HV');
    expect(_driverProfile.license.documentUploaded, isTrue);
    expect(_driverProfile.medicalCertificate.documentUploaded, isFalse);
  });

  test(
    'rejects an incomplete Driver identity instead of inventing defaults',
    () {
      expect(
        () => DriverProfile.fromJson(const {'driverId': 'driver-1'}),
        throwsFormatException,
      );
    },
  );

  testWidgets(
    'Driver dashboard uses DriverProfile name for a multi-role account',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(
              _SignedInDriverController.new,
            ),
            driverProfileControllerProvider.overrideWith(
              _FixedDriverProfileController.new,
            ),
          ],
          child: const MaterialApp(home: DriverHomeScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('dipesh chaudhary'), findsOneWidget);
      expect(find.text('dipesh'), findsOneWidget);
      expect(find.text('Bijay chaudhary'), findsNothing);
      expect(find.text('34554677887987'), findsOneWidget);
      expect(find.text('4 years'), findsOneWidget);
      expect(find.text('Document on file'), findsOneWidget);
    },
  );
}
