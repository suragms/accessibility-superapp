import 'exceptions.dart';
import '../../features/auth/domain/exceptions/auth_exception.dart';

/// Representation of business-level failures returned from Domain repositories.
/// Strictly decoupled from UI or data layer specifics.
sealed class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: [$code] $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure({required String message, String? code})
      : super(message, code);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({required String message, String? code})
      : super(message, code);
}

class LocationFailure extends Failure {
  const LocationFailure({required String message, String? code})
      : super(message, code);
}

class SpeechFailure extends Failure {
  const SpeechFailure({required String message, String? code})
      : super(message, code);
}

class AuthFailure extends Failure {
  const AuthFailure({required String message, String? code})
      : super(message, code);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required String message, String? code})
      : super(message, code);
}

class UnknownFailure extends Failure {
  const UnknownFailure({required String message, String? code})
      : super(message, code);
}

/// Extension mapping AppExceptions to Failures directly.
extension ExceptionToFailureExtension on Object {
  Failure toFailure() {
    if (this is NetworkException) {
      return NetworkFailure(
        message: (this as NetworkException).message,
        code: (this as NetworkException).code,
      );
    }
    if (this is DatabaseException) {
      return DatabaseFailure(
        message: (this as DatabaseException).message,
        code: (this as DatabaseException).code,
      );
    }
    if (this is LocationException) {
      return LocationFailure(
        message: (this as LocationException).message,
        code: (this as LocationException).code,
      );
    }
    if (this is SpeechException) {
      return SpeechFailure(
        message: (this as SpeechException).message,
        code: (this as SpeechException).code,
      );
    }
    if (this is AuthException) {
      return AuthFailure(
        message: (this as AuthException).message,
        code: (this as AuthException).code,
      );
    }
    if (this is ValidationException) {
      return ValidationFailure(
        message: (this as ValidationException).message,
        code: (this as ValidationException).code,
      );
    }
    return UnknownFailure(message: toString());
  }
}
