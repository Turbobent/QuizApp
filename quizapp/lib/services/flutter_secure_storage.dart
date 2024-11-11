// services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Create an instance of FlutterSecureStorage
  final _storage = FlutterSecureStorage();

  // Write a value to secure storage
  Future<void> writeToken(String token) async {
    await _storage.write(key: 'jwt', value: token);
  }

  // Read the token from secure storage
  Future<String?> readToken() async {
    return await _storage.read(key: 'jwt');
  }

  // Delete the token from secure storage
  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt');
  }
}
