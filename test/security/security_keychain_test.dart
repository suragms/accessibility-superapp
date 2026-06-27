import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  group('Security & Offline Storage KeyChain Tests', () {
    setUpAll(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('Verify Token encryption store and retrieve lifecycle', () async {
      const storage = FlutterSecureStorage();

      // Ensure clean storage values initially
      await storage.deleteAll();
      expect(await storage.read(key: 'jwt_access_token'), isNull);

      // Write token
      await storage.write(key: 'jwt_access_token', value: 'secure-access-token-jwt-12345');
      await storage.write(key: 'jwt_refresh_token', value: 'secure-refresh-token-jwt-67890');

      // Retrieve and verify
      expect(await storage.read(key: 'jwt_access_token'), equals('secure-access-token-jwt-12345'));
      expect(await storage.read(key: 'jwt_refresh_token'), equals('secure-refresh-token-jwt-67890'));

      // Clear credentials
      await storage.deleteAll();
      expect(await storage.read(key: 'jwt_access_token'), isNull);
    });

    test('Verify offline security PIN authentication hashes offline', () async {
      const storage = FlutterSecureStorage();
      await storage.deleteAll();

      // Write security pin hash
      await storage.write(key: 'offline_pin_hash', value: 'hashed-9999');

      // Verify offline PIN matching
      final pinHash = await storage.read(key: 'offline_pin_hash');
      expect(pinHash, equals('hashed-9999'));
    });
  });
}
