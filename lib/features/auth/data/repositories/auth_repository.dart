import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/exceptions/auth_exception.dart';

/// Representation of an active user session.
class UserSession {
  final String userId;
  final String email;
  final bool isGuest;

  const UserSession({
    required this.userId,
    required this.email,
    this.isGuest = false,
  });
}

/// Repository executing remote API calls and local offline authentication procedures.
class AuthRepository {
  final Dio dio;
  final FlutterSecureStorage secureStorage;

  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _pinHashKey = 'offline_pin_hash';
  static const String _sessionUserKey = 'session_user_data';

  AuthRepository({
    required this.dio,
    required this.secureStorage,
  });

  /// Verifies credentials with remote endpoint and saves local offline hashes on success.
  Future<UserSession> loginWithEmail(String email, String password) async {
    try {
      // In production API Gateway, resolves email credentials
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        final userId = data['user_id'] as String;

        // Save session tokens securely
        await secureStorage.write(key: _accessTokenKey, value: accessToken);
        await secureStorage.write(key: _refreshTokenKey, value: refreshToken);

        final session = UserSession(userId: userId, email: email);
        await _cacheSession(session);
        
        // Cache a SHA-256 password hash locally for offline fallback authentication
        final pwdHash = sha256.convert(utf8.encode(password)).toString();
        await secureStorage.write(key: 'offline_password_hash', value: pwdHash);

        return session;
      }
      throw InvalidCredentialsException();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw InvalidCredentialsException();
      }
      rethrow;
    }
  }

  /// Registers a new user.
  Future<UserSession> signup(String email, String password) async {
    try {
      final response = await dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 && response.data != null) {
        // Registration returns 201 Created and response content

        return loginWithEmail(email, password);
      }
      throw InvalidCredentialsException(message: 'Signup failed. Please try again.');
    } catch (e) {
      rethrow;
    }
  }

  /// Offline PIN matching verification using encrypted SHA-256 local hashes.
  Future<UserSession> loginWithPin(String pin) async {
    final cachedPinHash = await secureStorage.read(key: _pinHashKey);
    if (cachedPinHash == null) {
      throw PinNotSetException();
    }

    final enteredPinHash = sha256.convert(utf8.encode(pin)).toString();
    if (cachedPinHash == enteredPinHash) {
      // PIN matches, retrieve cached user info
      final cachedUserJson = await secureStorage.read(key: _sessionUserKey);
      if (cachedUserJson != null) {
        final data = json.decode(cachedUserJson) as Map<String, dynamic>;
        return UserSession(
          userId: data['userId'] as String,
          email: data['email'] as String,
          isGuest: data['isGuest'] as bool,
        );
      }
    }
    throw InvalidCredentialsException(message: 'Incorrect PIN entered.');
  }

  /// Sets an offline authentication PIN code.
  Future<void> setOfflinePin(String pin, UserSession session) async {
    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    await secureStorage.write(key: _pinHashKey, value: pinHash);
    await _cacheSession(session);
  }

  /// Mock Google login authentication integration.
  Future<UserSession> loginWithGoogle() async {
    // In production, uses google_sign_in package to obtain tokens, then posts to API Gateway
    await Future.delayed(const Duration(milliseconds: 1500));
    final session = const UserSession(userId: 'google-1093', email: 'user.google@gmail.com');
    await _cacheSession(session);
    return session;
  }

  /// Mock Apple login authentication integration.
  Future<UserSession> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final session = const UserSession(userId: 'apple-0298', email: 'user.apple@icloud.com');
    await _cacheSession(session);
    return session;
  }

  /// Initiates guest usage mode with offline access.
  Future<UserSession> loginAsGuest() async {
    final session = const UserSession(
      userId: 'guest-session',
      email: 'guest@accessibilityapp.org',
      isGuest: true,
    );
    await _cacheSession(session);
    return session;
  }

  /// Simulates biometric verification.
  Future<UserSession> loginWithBiometrics() async {
    // In production, uses local_auth to trigger TouchID/FaceID dialog
    await Future.delayed(const Duration(milliseconds: 1000));
    final cachedUserJson = await secureStorage.read(key: _sessionUserKey);
    if (cachedUserJson != null) {
      final data = json.decode(cachedUserJson) as Map<String, dynamic>;
      return UserSession(
        userId: data['userId'] as String,
        email: data['email'] as String,
        isGuest: data['isGuest'] as bool,
      );
    }
    throw OfflineSessionException(message: 'No active session cached for biometric unlock.');
  }

  /// Password reset email sender.
  Future<void> forgotPassword(String email) async {
    await dio.post('/auth/forgot-password', data: {'email': email});
  }

  /// Clean session tokens on logout.
  Future<void> logout() async {
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: _sessionUserKey);
  }

  Future<void> _cacheSession(UserSession session) async {
    final jsonStr = json.encode({
      'userId': session.userId,
      'email': session.email,
      'isGuest': session.isGuest,
    });
    await secureStorage.write(key: _sessionUserKey, value: jsonStr);
  }
}

// Global Provider definitions (using basic providers for stable compiling)
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// Provides mock Dio instance specifically configured for Auth endpoints
final authDioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.accessibilitysuperapp.com',
    connectTimeout: const Duration(seconds: 15),
  ));
  return dio;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(authDioProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(dio: dio, secureStorage: secureStorage);
});
