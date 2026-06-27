abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => '$runtimeType: [$code] $message';
}

class NetworkException extends AppException {
  const NetworkException({required String message, String? code})
      : super(message, code);
}

class DatabaseException extends AppException {
  const DatabaseException({required String message, String? code})
      : super(message, code);
}

class LocationException extends AppException {
  const LocationException({required String message, String? code})
      : super(message, code);
}

class SpeechException extends AppException {
  const SpeechException({required String message, String? code})
      : super(message, code);
}

class AuthException extends AppException {
  const AuthException({required String message, String? code})
      : super(message, code);
}

class ValidationException extends AppException {
  const ValidationException({required String message, String? code})
      : super(message, code);
}
