import '../../../../core/error/exceptions.dart';

sealed class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException({String message = 'Invalid username or password.'})
      : super(message, 'INVALID_CREDENTIALS');
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException({String message = 'Session has expired; please login again.'})
      : super(message, 'SESSION_EXPIRED');
}

class PinNotSetException extends AuthException {
  const PinNotSetException({String message = 'Offline access PIN has not been set.'})
      : super(message, 'PIN_NOT_SET');
}

class OfflineSessionException extends AuthException {
  const OfflineSessionException({String message = 'Offline login failed. No credentials cached.'})
      : super(message, 'OFFLINE_SESSION_FAILED');
}

class BiometricException extends AuthException {
  const BiometricException({required String message, String? code})
      : super(message, code ?? 'BIOMETRIC_ERROR');
}
