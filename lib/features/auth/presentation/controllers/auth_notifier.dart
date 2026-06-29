import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';

/// Sealed class defining the authentication states.
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserSession session;
  const Authenticated(this.session);
}

class Unauthenticated extends AuthState {
  final String? message;
  const Unauthenticated([this.message]);
}

class AuthError extends AuthState {
  final String errorMessage;
  const AuthError(this.errorMessage);
}

/// Presentation notifier orchestrating authentication state transitions.
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;

  AuthNotifier({required this.authRepository}) : super(const AuthInitial()) {
    // Attempt to restore a cached session immediately on creation so that
    // users who were previously authenticated are not forced to log in again
    // every time the app restarts.
    restoreSession();
  }

  /// Attempts to restore a previously cached session from the local Users
  /// table or secure storage. Transitions to [Authenticated] on success or
  /// [Unauthenticated] if no valid session is found.
  Future<void> restoreSession() async {
    state = const AuthLoading();
    try {
      final session = await authRepository.restoreSession();
      if (session != null) {
        state = Authenticated(session);
      } else {
        state = const Unauthenticated();
      }
    } catch (e) {
      state = const Unauthenticated();
    }
  }

  /// Log in with email credentials.
  Future<void> loginWithEmail(String email, String password) async {
    state = const AuthLoading();
    try {
      final session = await authRepository.loginWithEmail(email, password);
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Register a new account.
  Future<void> signup(String email, String password) async {
    state = const AuthLoading();
    try {
      final session = await authRepository.signup(email, password);
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Offline-capable login using local PIN.
  Future<void> loginWithPin(String pin) async {
    state = const AuthLoading();
    try {
      final session = await authRepository.loginWithPin(pin);
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Trigger biometric authentication.
  Future<void> loginWithBiometrics() async {
    state = const AuthLoading();
    try {
      final session = await authRepository.loginWithBiometrics();
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Activate Guest Session mode.
  Future<void> loginAsGuest() async {
    state = const AuthLoading();
    try {
      final session = await authRepository.loginAsGuest();
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Google credential sign in.
  Future<void> loginWithGoogle() async {
    state = const AuthLoading();
    try {
      final session = await authRepository.loginWithGoogle();
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Apple credential sign in.
  Future<void> loginWithApple() async {
    state = const AuthLoading();
    try {
      final session = await authRepository.loginWithApple();
      state = Authenticated(session);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Request password reset.
  Future<void> forgotPassword(String email) async {
    state = const AuthLoading();
    try {
      await authRepository.forgotPassword(email);
      state = const Unauthenticated('Password reset email sent successfully.');
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Ends the active session and clears cache.
  Future<void> logout() async {
    state = const AuthLoading();
    await authRepository.logout();
    state = const Unauthenticated();
  }

  /// Sets offline authentication PIN.
  Future<void> setOfflinePin(String pin) async {
    if (state is Authenticated) {
      final session = (state as Authenticated).session;
      await authRepository.setOfflinePin(pin, session);
    }
  }
}

/// Provider exposing AuthNotifier state to widgets.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(authRepository: repository);
});
