import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/database/app_database.dart';
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
/// Offline-first: persists user data to the local Drift Users table so that
/// PIN login, email/password login, and session restore all work without network.
class AuthRepository {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  final AppDatabase database;

  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';
  static const String _pinHashKey = 'offline_pin_hash';
  static const String _sessionUserKey = 'session_user_data';

  AuthRepository({
    required this.dio,
    required this.secureStorage,
    required this.database,
  });

  // ---------------------------------------------------------------------------
  // Online + offline-fallback authentication
  // ---------------------------------------------------------------------------

  /// Verifies credentials with remote endpoint and saves local offline hashes
  /// on success. If the network is unreachable, falls back to local DB auth
  /// so the app works fully offline after first registration.
  Future<UserSession> loginWithEmail(String email, String password) async {
    final passwordHash = sha256.convert(utf8.encode(password)).toString();

    // --- Try the network first ---
    try {
      final response = await dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        final userId = data['user_id'] as String;

        await secureStorage.write(key: _accessTokenKey, value: accessToken);
        await secureStorage.write(key: _refreshTokenKey, value: refreshToken);

        final session = UserSession(userId: userId, email: email);
        await _cacheSession(session);
        await _persistUserToDatabase(session, passwordHash: passwordHash);

        return session;
      }
      throw InvalidCredentialsException();
    } on DioException {
      // Network unavailable – fall through to local auth
    }

    // --- Offline fallback: verify against local Users table ---
    return _loginOffline(email, passwordHash);
  }

  /// Registers a new user. Tries the network first; on connection failure,
  /// creates the user entirely in the local database (offline-first).
  Future<UserSession> signup(String email, String password) async {
    final passwordHash = sha256.convert(utf8.encode(password)).toString();

    // --- Try the network first ---
    try {
      final response = await dio.post('/auth/signup', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201 && response.data != null) {
        return loginWithEmail(email, password);
      }
      throw InvalidCredentialsException(
        message: 'Signup failed. Please try again.',
      );
    } on DioException {
      // Network unavailable – create user locally
    }

    // --- Offline signup: check if email already exists locally ---
    final existing = await _readUserByEmail(email);
    if (existing != null) {
      throw InvalidCredentialsException(
        message: 'An account with this email already exists.',
      );
    }

    // Generate a local UUID-style ID for the offline user
    final userId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final session = UserSession(userId: userId, email: email);
    await _persistUserToDatabase(session, passwordHash: passwordHash);
    await _cacheSession(session);

    return session;
  }

  // ---------------------------------------------------------------------------
  // Offline authentication (PIN + session restore)
  // ---------------------------------------------------------------------------

  /// Offline PIN matching verification using the local Users table.
  /// Falls back to secure storage for backward compatibility.
  Future<UserSession> loginWithPin(String pin) async {
    final enteredPinHash = sha256.convert(utf8.encode(pin)).toString();

    // Primary path: read PIN hash from the local Users table
    final cachedUser = await _readUserFromDatabase();
    if (cachedUser != null && cachedUser.pinHash != null) {
      if (cachedUser.pinHash == enteredPinHash) {
        return UserSession(
          userId: cachedUser.id,
          email: cachedUser.email ?? '',
        );
      }
      throw InvalidCredentialsException(message: 'Incorrect PIN entered.');
    }

    // Fallback: legacy secure-storage PIN hash
    final cachedPinHash = await secureStorage.read(key: _pinHashKey);
    if (cachedPinHash != null) {
      if (cachedPinHash == enteredPinHash) {
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

    throw PinNotSetException();
  }

  /// Sets an offline authentication PIN code.
  /// Writes to both secure storage and the local Users table.
  Future<void> setOfflinePin(String pin, UserSession session) async {
    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    await secureStorage.write(key: _pinHashKey, value: pinHash);
    await _cacheSession(session);

    // Persist PIN hash to the local Users table for offline-first reads
    await _upsertUserPinHash(session.userId, pinHash);
  }

  /// Attempts to restore a previously cached session from local storage.
  /// Returns null if no cached session exists (user must log in again).
  Future<UserSession?> restoreSession() async {
    // Primary: read from local Users table
    final cachedUser = await _readUserFromDatabase();
    if (cachedUser != null && cachedUser.email != null) {
      return UserSession(
        userId: cachedUser.id,
        email: cachedUser.email!,
      );
    }

    // Fallback: secure storage
    final cachedUserJson = await secureStorage.read(key: _sessionUserKey);
    if (cachedUserJson != null) {
      final data = json.decode(cachedUserJson) as Map<String, dynamic>;
      return UserSession(
        userId: data['userId'] as String,
        email: data['email'] as String,
        isGuest: data['isGuest'] as bool,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Social / mock logins (persist to Users table for offline availability)
  // ---------------------------------------------------------------------------

  /// Mock Google login authentication integration.
  Future<UserSession> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final session = const UserSession(
      userId: 'google-1093',
      email: 'user.google@gmail.com',
    );
    await _cacheSession(session);
    await _persistUserToDatabase(session);
    return session;
  }

  /// Mock Apple login authentication integration.
  Future<UserSession> loginWithApple() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    final session = const UserSession(
      userId: 'apple-0298',
      email: 'user.apple@icloud.com',
    );
    await _cacheSession(session);
    await _persistUserToDatabase(session);
    return session;
  }

  /// Initiates guest usage mode with offline access.
  Future<UserSession> loginAsGuest() async {
    const session = UserSession(
      userId: 'guest-session',
      email: 'guest@accessibilityapp.org',
      isGuest: true,
    );
    await _cacheSession(session);
    await _persistUserToDatabase(session);
    return session;
  }

  /// Simulates biometric verification.
  Future<UserSession> loginWithBiometrics() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Try local DB first
    final cachedUser = await _readUserFromDatabase();
    if (cachedUser != null && cachedUser.email != null) {
      return UserSession(
        userId: cachedUser.id,
        email: cachedUser.email!,
      );
    }

    // Fallback to secure storage
    final cachedUserJson = await secureStorage.read(key: _sessionUserKey);
    if (cachedUserJson != null) {
      final data = json.decode(cachedUserJson) as Map<String, dynamic>;
      return UserSession(
        userId: data['userId'] as String,
        email: data['email'] as String,
        isGuest: data['isGuest'] as bool,
      );
    }

    throw OfflineSessionException(
      message: 'No active session cached for biometric unlock.',
    );
  }

  /// Password reset email sender.
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post('/auth/forgot-password', data: {'email': email});
    } on DioException {
      // Silently ignore – offline has no email to send
    }
  }

  /// Clean session tokens on logout.
  Future<void> logout() async {
    await secureStorage.delete(key: _accessTokenKey);
    await secureStorage.delete(key: _refreshTokenKey);
    await secureStorage.delete(key: _sessionUserKey);
    await secureStorage.delete(key: _pinHashKey);
  }

  // ---------------------------------------------------------------------------
  // Private helpers – offline authentication
  // ---------------------------------------------------------------------------

  /// Offline email/password login: looks up the user by email in the local
  /// database and compares the stored password hash.
  Future<UserSession> _loginOffline(
    String email,
    String passwordHash,
  ) async {
    final user = await _readUserByEmail(email);
    if (user == null) {
      throw InvalidCredentialsException(
        message: 'No account found for this email. Please sign up first.',
      );
    }

    if (user.passwordHash == passwordHash) {
      final session = UserSession(userId: user.id, email: email);
      await _cacheSession(session);
      return session;
    }

    throw InvalidCredentialsException(
      message: 'Incorrect password. Please try again.',
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers – database persistence
  // ---------------------------------------------------------------------------

  /// Writes the authenticated user to the local Drift Users table so that
  /// offline PIN login and session restore have local data to read.
  Future<void> _persistUserToDatabase(
    UserSession session, {
    String? passwordHash,
  }) async {
    await database.into(database.users).insertOnConflictUpdate(
          UsersCompanion.insert(
            id: session.userId,
            email: Value(session.email),
            name: const Value.absent(),
            token: const Value.absent(),
            batteryLevel: const Value(100),
            pinHash: const Value.absent(),
            passwordHash: Value(passwordHash),
          ),
        );
  }

  /// Reads the current user row from the local Users table.
  Future<User?> _readUserFromDatabase() async {
    final cachedUserJson = await secureStorage.read(key: _sessionUserKey);
    if (cachedUserJson == null) return null;

    final data = json.decode(cachedUserJson) as Map<String, dynamic>;
    final userId = data['userId'] as String;

    final query = database.select(database.users)
      ..where((u) => u.id.equals(userId));
    return query.getSingleOrNull();
  }

  /// Reads a user row by email address from the local Users table.
  Future<User?> _readUserByEmail(String email) async {
    final query = database.select(database.users)
      ..where((u) => u.email.equals(email));
    return query.getSingleOrNull();
  }

  /// Updates only the PIN hash for a user row.
  Future<void> _upsertUserPinHash(String userId, String pinHash) async {
    await (database.update(database.users)..where((u) => u.id.equals(userId)))
        .write(UsersCompanion(pinHash: Value(pinHash)));
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

/// Provides mock Dio instance specifically configured for Auth endpoints
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
  final database = ref.watch(databaseProvider);
  return AuthRepository(
    dio: dio,
    secureStorage: secureStorage,
    database: database,
  );
});
