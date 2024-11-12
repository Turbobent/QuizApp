// services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // Create an instance of FlutterSecureStorage
  final _storage = FlutterSecureStorage();
  // Method to write data with a key
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Write a value to secure storage
  Future<void> writeToken(String token) async {
    await _storage.write(key: 'jwt', value: token);
  }

  // Convenience method to store userID
  Future<void> writeUserID(String userID) async {
    await write('userID', userID);
  }

  Future<String?> readUserID() async {
    return await _storage.read(key: 'userID') as String?;
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
