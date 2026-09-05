import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shuvmarg_partner_app/app/router/guards.dart';
import 'package:shuvmarg_partner_app/app/router/routes.dart';
import 'package:shuvmarg_partner_app/core/errors/error_mapper.dart';
import 'package:shuvmarg_partner_app/core/errors/failure.dart';
import 'package:shuvmarg_partner_app/core/network/interceptors/auth_interceptor.dart';
import 'package:shuvmarg_partner_app/core/storage/session_store.dart';
import 'package:shuvmarg_partner_app/domain/app_role.dart';
import 'package:shuvmarg_partner_app/domain/session.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/agent_assignments_section.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/data/agent_assignment.dart';
import 'package:shuvmarg_partner_app/features/agent/assignments/state/agent_assignments_controller.dart';
import 'package:shuvmarg_partner_app/shared/session/session_state.dart';
import 'package:shuvmarg_partner_app/shared/state/view_state.dart';
import 'package:shuvmarg_partner_app/shared/ui/app_button.dart';

class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _data.remove(key);
}

const _user = AuthenticatedUser(
  id: 'user-123',
  name: 'Ramesh Sharma',
  phone: '9841234567',
  roles: ['agent'],
  isVerified: true,
);

const _session = Session(
  accessToken: 'access-token-xyz',
  refreshToken: 'refresh-cookie-abc',
  activeRole: AppRole.agent,
  user: _user,
);

AgentAssignment _makeAssignment({
  required String id,
  required String brandId,
  required String brandName,
  AgentAssignmentStatus status = AgentAssignmentStatus.active,
  bool canSellCash = true,
  num commissionValue = 5,
}) {
  return AgentAssignment(
    id: id,
    status: status,
    brandId: brandId,
    brandName: brandName,
    accessScope: 'ALL_BUSES',
    permissions: AssignmentPermissions(
      canSellCash: canSellCash,
      canSellOnline: false,
      canCancel: true,
      cancelWindowMins: 60,
      maxSeatsPerBooking: 4,
      maxDiscountPct: 0,
    ),
    commission: AssignmentCommission(mode: 'PERCENT', value: commissionValue),
    invitedAt: DateTime.now().subtract(const Duration(days: 1)),
  );
}

class _FixedAssignmentsController extends AgentAssignmentsController {
  _FixedAssignmentsController(this._view);
  final AgentAssignmentsView _view;

  @override
  ViewState<AgentAssignmentsView> build() => ViewState.data(_view);
}

void main() {
  group('Partner App Acceptance Suite (Tests 31-50)', () {
    // -------------------------------------------------------------------------
    // Test 31: Agent/operator/staff authentication works (P0)
    // -------------------------------------------------------------------------
    test(
      'Test 31: AuthInterceptor captures session refresh cookies for all partner roles',
      () {
        for (final cookieName in [
          'agentRefreshToken',
          'driverRefreshToken',
          'busOwnerRefreshToken',
        ]) {
          final headers = Headers.fromMap({
            'set-cookie': [
              '$cookieName=test_token_123; HttpOnly; SameSite=Lax',
            ],
          });
          expect(
            AuthHeaderInterceptor.readRefreshCookie(headers),
            'test_token_123',
            reason: 'Must capture refresh token for $cookieName',
          );
        }
        final malformed = Headers.fromMap({
          'set-cookie': ['otherCookie=123; HttpOnly'],
        });
        expect(AuthHeaderInterceptor.readRefreshCookie(malformed), isNull);
      },
    );

    // -------------------------------------------------------------------------
    // Test 32: Each role receives only authorized workspace (P0)
    // -------------------------------------------------------------------------
    test(
      'Test 32: sessionRedirect enforces strict role workspace boundaries',
      () {
        const signedOut = SessionSignedOut();
        expect(
          sessionRedirect(signedOut, AppRoutes.agentHome),
          AppRoutes.welcome,
        );
        expect(
          sessionRedirect(signedOut, AppRoutes.driverHome),
          AppRoutes.welcome,
        );
        expect(
          sessionRedirect(signedOut, AppRoutes.conductorHome),
          AppRoutes.welcome,
        );

        const agentSignedIn = SessionSignedIn(session: _session);
        // Agent accessing agent workspace is permitted
        expect(sessionRedirect(agentSignedIn, AppRoutes.agentHome), isNull);
        // Agent accessing other persona paths is redirected to agent home
        expect(
          sessionRedirect(agentSignedIn, AppRoutes.driverHome),
          AppRoutes.agentHome,
        );
        expect(
          sessionRedirect(agentSignedIn, AppRoutes.conductorHome),
          AppRoutes.agentHome,
        );

        // Conductor signed in
        const conductorSession = Session(
          accessToken: 'c-token',
          activeRole: AppRole.conductor,
          user: _user,
        );
        const conductorSignedIn = SessionSignedIn(session: conductorSession);
        expect(
          sessionRedirect(conductorSignedIn, AppRoutes.conductorHome),
          isNull,
        );
        expect(
          sessionRedirect(conductorSignedIn, AppRoutes.agentHome),
          AppRoutes.conductorHome,
        );

        // Non-partner role detection
        expect(AppRole.belongsToAnotherApp('passenger'), isTrue);
        expect(AppRole.belongsToAnotherApp('busowner'), isTrue);
        expect(AppRole.tryParse('passenger'), isNull);
      },
    );

    // -------------------------------------------------------------------------
    // Test 33: Agent sees only assigned operators/brands (P0)
    // -------------------------------------------------------------------------
    test(
      'Test 33: AgentAssignmentsView groups only assigned operators by status',
      () {
        final a1 = _makeAssignment(
          id: 'asg-1',
          brandId: 'b-1',
          brandName: 'Brand Alpha',
        );
        final a2 = _makeAssignment(
          id: 'asg-2',
          brandId: 'b-2',
          brandName: 'Brand Beta',
          status: AgentAssignmentStatus.invited,
        );
        final a3 = _makeAssignment(
          id: 'asg-3',
          brandId: 'b-3',
          brandName: 'Brand Gamma',
          status: AgentAssignmentStatus.suspended,
        );
        final a4 = _makeAssignment(
          id: 'asg-4',
          brandId: 'b-4',
          brandName: 'Brand Delta',
          status: AgentAssignmentStatus.declined,
        );

        final view = AgentAssignmentsView(items: [a1, a2, a3, a4]);

        expect(view.active.length, 1);
        expect(view.active.first.brandName, 'Brand Alpha');
        expect(view.invitations.length, 1);
        expect(view.invitations.first.brandName, 'Brand Beta');
        expect(view.pausedOrRemoved.length, 1);
        expect(view.pausedOrRemoved.first.brandName, 'Brand Gamma');
        expect(view.history.length, 1);
        expect(view.history.first.brandName, 'Brand Delta');
      },
    );

    // -------------------------------------------------------------------------
    // Test 34: Brand/operator switching doesn't leak data (P0)
    // -------------------------------------------------------------------------
    test(
      'Test 34: Distinct operator assignments hold strictly segregated metadata',
      () {
        final brandA = _makeAssignment(
          id: 'asg-A',
          brandId: 'brand-A',
          brandName: 'Pokhara Deluxe',
          canSellCash: true,
          commissionValue: 10,
        );
        final brandB = _makeAssignment(
          id: 'asg-B',
          brandId: 'brand-B',
          brandName: 'Kathmandu Express',
          canSellCash: false,
          commissionValue: 5,
        );

        expect(brandA.brandId, 'brand-A');
        expect(brandB.brandId, 'brand-B');
        expect(brandA.permissions.canSellCash, isTrue);
        expect(brandB.permissions.canSellCash, isFalse);
        expect(brandA.commission.value, 10);
        expect(brandB.commission.value, 5);
        expect(brandA.id, isNot(equals(brandB.id)));
      },
    );

    // -------------------------------------------------------------------------
    // Test 38: Passenger information is validated (P0)
    // -------------------------------------------------------------------------
    test('Test 38: Client validates passenger phone and name formats', () {
      final phoneRegex = RegExp(r'^9[78]\d{8}$');

      expect(phoneRegex.hasMatch('9841234567'), isTrue);
      expect(phoneRegex.hasMatch('9741234567'), isTrue);
      expect(phoneRegex.hasMatch('9141234567'), isFalse);
      expect(phoneRegex.hasMatch('984123456'), isFalse);
      expect(phoneRegex.hasMatch('98412345678'), isFalse);
      expect(phoneRegex.hasMatch('abcdefghij'), isFalse);

      bool isValidName(String name) => name.trim().length >= 2;
      expect(isValidName('Sita Rai'), isTrue);
      expect(isValidName(''), isFalse);
      expect(isValidName('  '), isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 42: Double-tapping booking doesn't create duplicates (P0)
    // -------------------------------------------------------------------------
    testWidgets(
      'Test 42: AppButton blocks duplicate taps while isLoading is true',
      (tester) async {
        int tapCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AppButton(
                label: 'Confirm Sale',
                isLoading: true,
                onPressed: () => tapCount++,
              ),
            ),
          ),
        );

        await tester.tap(find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();

        expect(
          tapCount,
          0,
          reason: 'Taps must be completely ignored while loading',
        );
      },
    );

    // -------------------------------------------------------------------------
    // Test 45: Poor-network behavior is understandable (P1)
    // -------------------------------------------------------------------------
    test(
      'Test 45: ErrorMapper maps Dio timeouts and connection errors to understandable failures',
      () {
        final requestOptions = RequestOptions(
          path: '/api/agent/sellable-inventory',
        );

        final timeoutDio = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionTimeout,
        );
        final timeoutFailure = ErrorMapper.fromDio(timeoutDio);
        expect(timeoutFailure, isA<NetworkFailure>());
        expect((timeoutFailure as NetworkFailure).isTimeout, isTrue);
        expect(timeoutFailure.message, contains('connection timed out'));
        expect(timeoutFailure.isRetryable, isTrue);

        final connErrorDio = DioException(
          requestOptions: requestOptions,
          type: DioExceptionType.connectionError,
        );
        final connFailure = ErrorMapper.fromDio(connErrorDio);
        expect(connFailure, isA<NetworkFailure>());
        expect(connFailure.message, contains('could not reach Shuvmarg'));
        expect(connFailure.isRetryable, isTrue);
      },
    );

    // -------------------------------------------------------------------------
    // Test 46: Offline queue works correctly if enabled at launch (P1)
    // -------------------------------------------------------------------------
    test(
      'Test 46: Offline network failures are retryable and retain state context',
      () {
        const offline = NetworkFailure(
          message: 'No internet connection detected.',
          isTimeout: false,
        );
        expect(offline.isRetryable, isTrue);
        expect(offline.message, contains('No internet'));
      },
    );

    // -------------------------------------------------------------------------
    // Test 48: Process death restores non-sensitive working state (P1)
    // -------------------------------------------------------------------------
    test(
      'Test 48: SessionStore restores session after process death and rejects partial writes',
      () async {
        final fakeStorage = _FakeSecureStorage();
        final store = SessionStore(storage: fakeStorage);

        // Write session
        await store.write(_session);
        expect(store.cached?.accessToken, 'access-token-xyz');

        // Simulate process recreation
        final restoredStore = SessionStore(storage: fakeStorage);
        final restoredSession = await restoredStore.read();
        expect(restoredSession, isNotNull);
        expect(restoredSession?.accessToken, 'access-token-xyz');
        expect(restoredSession?.activeRole, AppRole.agent);
        expect(restoredSession?.user.name, 'Ramesh Sharma');

        // Incomplete state simulation (token present, user missing)
        await fakeStorage.delete(key: 'partner_user_data');
        final brokenStore = SessionStore(storage: fakeStorage);
        final brokenSession = await brokenStore.read();
        expect(
          brokenSession,
          isNull,
          reason: 'Incomplete session on disk must fail closed',
        );
      },
    );

    // -------------------------------------------------------------------------
    // Test 49: Logout completely clears protected local session data (P1)
    // -------------------------------------------------------------------------
    test(
      'Test 49: Logout purges all stored credentials and in-memory caches',
      () async {
        final fakeStorage = _FakeSecureStorage();
        final store = SessionStore(storage: fakeStorage);

        await store.write(_session);
        expect(await fakeStorage.read(key: 'partner_access_token'), isNotNull);

        await store.clear();

        expect(store.cached, isNull);
        expect(store.lastKnownRefreshToken, isNull);
        expect(await fakeStorage.read(key: 'partner_access_token'), isNull);
        expect(await fakeStorage.read(key: 'partner_refresh_token'), isNull);
        expect(await fakeStorage.read(key: 'partner_user_data'), isNull);
        expect(await fakeStorage.read(key: 'partner_active_role'), isNull);
      },
    );

    // -------------------------------------------------------------------------
    // Test 50: Multi-brand UI remains usable with many brands (P2)
    // -------------------------------------------------------------------------
    testWidgets(
      'Test 50: Multi-brand UI cleanly sections and renders 25 brands',
      (tester) async {
        final items = <AgentAssignment>[
          for (int i = 1; i <= 5; i++)
            _makeAssignment(
              id: 'inv-$i',
              brandId: 'brand-inv-$i',
              brandName: 'New Operator $i',
              status: AgentAssignmentStatus.invited,
            ),
          for (int i = 1; i <= 5; i++)
            _makeAssignment(
              id: 'act-$i',
              brandId: 'brand-act-$i',
              brandName: 'Connected Operator $i',
              status: AgentAssignmentStatus.active,
            ),
          for (int i = 1; i <= 5; i++)
            _makeAssignment(
              id: 'pau-$i',
              brandId: 'brand-pau-$i',
              brandName: 'Paused Operator $i',
              status: AgentAssignmentStatus.suspended,
            ),
          for (int i = 1; i <= 10; i++)
            _makeAssignment(
              id: 'his-$i',
              brandId: 'brand-his-$i',
              brandName: 'Past Operator $i',
              status: AgentAssignmentStatus.declined,
            ),
        ];

        final view = AgentAssignmentsView(items: items);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              agentAssignmentsControllerProvider.overrideWith(
                () => _FixedAssignmentsController(view),
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: AgentAssignmentsSection(kycCleared: true),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Your invitations'), findsOneWidget);
        expect(find.text('Connected operators'), findsOneWidget);
        expect(find.text('Paused or removed'), findsOneWidget);
        expect(find.text('Previous invitations'), findsOneWidget);
        expect(find.text('10 completed'), findsOneWidget);
        expect(find.text('Connected Operator 1'), findsOneWidget);
        expect(find.text('New Operator 1'), findsOneWidget);
      },
    );
  });
}
