import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:accessibility_super_app/features/auth/data/repositories/auth_repository.dart';
import 'package:accessibility_super_app/features/auth/domain/exceptions/auth_exception.dart';
import 'package:accessibility_super_app/features/auth/presentation/controllers/auth_notifier.dart';

/// Manual Mock Repository supporting testing stubbing.
class MockAuthRepository extends AuthRepository {
  final bool shouldSucceed;
  final bool hasPinCached;
  final String cachedPin;

  MockAuthRepository({
    this.shouldSucceed = true,
    this.hasPinCached = true,
    this.cachedPin = '1234',
  }) : super(
          dio: Dio(),
          secureStorage: const FlutterSecureStorage(),
        );

  @override
  Future<UserSession> loginWithEmail(String email, String password) async {
    if (shouldSucceed) {
      return UserSession(userId: 'mock-uid-123', email: email);
    }
    throw InvalidCredentialsException();
  }

  @override
  Future<UserSession> loginWithPin(String pin) async {
    if (!hasPinCached) {
      throw PinNotSetException();
    }
    if (pin == cachedPin) {
      return const UserSession(userId: 'mock-uid-123', email: 'cached.user@mock.com');
    }
    throw InvalidCredentialsException(message: 'Incorrect PIN entered.');
  }

  @override
  Future<UserSession> loginAsGuest() async {
    return const UserSession(
      userId: 'guest-session',
      email: 'guest@accessibilityapp.org',
      isGuest: true,
    );
  }

  @override
  Future<void> logout() async {}
}

void main() {
  group('AuthNotifier Tests', () {
    test('Verify initial state is AuthInitial', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(shouldSucceed: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(authNotifierProvider), isA<AuthInitial>());
    });

    test('Verify successful email login state flow', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(shouldSucceed: true),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      // Trigger login
      final loginFuture = notifier.loginWithEmail('user@mock.com', 'password123');

      // Expect transitioning to Loading
      expect(container.read(authNotifierProvider), isA<AuthLoading>());

      await loginFuture;

      // Expect transitioning to Authenticated with correct session
      final finalState = container.read(authNotifierProvider);
      expect(finalState, isA<Authenticated>());
      expect((finalState as Authenticated).session.email, equals('user@mock.com'));
    });

    test('Verify invalid credentials email login state flow', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(shouldSucceed: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      // Trigger login
      final loginFuture = notifier.loginWithEmail('wrong@mock.com', 'wrong_pass');

      expect(container.read(authNotifierProvider), isA<AuthLoading>());

      await loginFuture;

      // Expect transitioning to AuthError
      final finalState = container.read(authNotifierProvider);
      expect(finalState, isA<AuthError>());
      expect(
        (finalState as AuthError).errorMessage,
        contains('INVALID_CREDENTIALS'),
      );
    });

    test('Verify successful offline PIN matching state flow', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(cachedPin: '5678'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      // Trigger PIN login
      final pinFuture = notifier.loginWithPin('5678');

      expect(container.read(authNotifierProvider), isA<AuthLoading>());

      await pinFuture;

      // Expect transitioning to Authenticated
      final finalState = container.read(authNotifierProvider);
      expect(finalState, isA<Authenticated>());
      expect((finalState as Authenticated).session.email, equals('cached.user@mock.com'));
    });

    test('Verify guest session state flow', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            MockAuthRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authNotifierProvider.notifier);

      // Trigger Guest login
      final guestFuture = notifier.loginAsGuest();

      expect(container.read(authNotifierProvider), isA<AuthLoading>());

      await guestFuture;

      final finalState = container.read(authNotifierProvider);
      expect(finalState, isA<Authenticated>());
      expect((finalState as Authenticated).session.isGuest, isTrue);
    });
  });
}
