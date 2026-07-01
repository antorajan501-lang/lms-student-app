import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken      = 'auth_token';
  static const _keyUserId     = 'user_id';
  static const _keyUserEmail  = 'user_email';
  static const _keyUserName   = 'user_name';
  static const _keyUserRole   = 'user_role';

  Future<void> saveToken(String token) =>
      _storage.write(key: _keyToken, value: token);

  Future<String?> getToken() => _storage.read(key: _keyToken);

  Future<void> saveUserData({
    required int id,
    required String email,
    required String name,
    required int role,
  }) async {
    await Future.wait([
      _storage.write(key: _keyUserId,    value: id.toString()),
      _storage.write(key: _keyUserEmail, value: email),
      _storage.write(key: _keyUserName,  value: name),
      _storage.write(key: _keyUserRole,  value: role.toString()),
    ]);
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'id':    await _storage.read(key: _keyUserId),
      'email': await _storage.read(key: _keyUserEmail),
      'name':  await _storage.read(key: _keyUserName),
      'role':  await _storage.read(key: _keyUserRole),
    };
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserName() => _storage.read(key: _keyUserName);

  Future<String?> getUserEmail() => _storage.read(key: _keyUserEmail);

  Future<String?> getUserId() => _storage.read(key: _keyUserId);

  Future<void> clearAll() => _storage.deleteAll();
}
