import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A production-grade JWT Interceptor for Dio.
/// Key Features:
/// 1. Intercepts outgoing requests to append `Authorization: Bearer <token>`.
/// 2. Seamlessly intercepts 401 Unauthorized responses to perform an atomic token refresh.
/// 3. Safely queues failed requests and retries them upon successful token rotation.
class JwtInterceptor extends QueuedInterceptor {
  final Dio dio;
  final FlutterSecureStorage secureStorage;
  
  static const String _accessTokenKey = 'jwt_access_token';
  static const String _refreshTokenKey = 'jwt_refresh_token';

  JwtInterceptor({
    required this.dio,
    required this.secureStorage,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Read cached token securely
    final accessToken = await secureStorage.read(key: _accessTokenKey);
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // If request failed with 401 Unauthorized, perform token refresh flow
    if (err.response?.statusCode == 401) {
      final refreshToken = await secureStorage.read(key: _refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          // Perform refreshing logic atomically
          final newTokens = await _performTokenRefresh(refreshToken);
          final newAccessToken = newTokens['access_token'];
          final newRefreshToken = newTokens['refresh_token'];

          if (newAccessToken != null && newRefreshToken != null) {
            // Save fresh tokens
            await secureStorage.write(key: _accessTokenKey, value: newAccessToken);
            await secureStorage.write(key: _refreshTokenKey, value: newRefreshToken);

            // Retry failed request with new token
            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

            final response = await dio.fetch(requestOptions);
            return handler.resolve(response);
          }
        } catch (e) {
          // Clear session tokens upon refresh failures (triggers redirection to login)
          await secureStorage.delete(key: _accessTokenKey);
          await secureStorage.delete(key: _refreshTokenKey);
        }
      }
    }
    super.onError(err, handler);
  }

  /// Communicates with API Gateway to swap expired token.
  Future<Map<String, String>> _performTokenRefresh(String refreshToken) async {
    try {
      // In production gateway, this endpoints resolves refresh requests
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'No-Authentication': 'true'}),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'access_token': data['access_token'] as String,
          'refresh_token': data['refresh_token'] as String,
        };
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        message: 'Invalid refresh response status.',
      );
    } catch (e) {
      rethrow;
    }
  }
}
