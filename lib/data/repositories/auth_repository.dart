import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../network/api_client.dart';
import '../models/session.dart';
import '../models/user.dart';

export '../models/session.dart' show LoginRequest, RegisterRequest;

class AuthRepository {
  final ApiClient _api;
  User? _currentUser;

  static const _tokenKey = 'x_session_token';
  static const _userIdKey = 'user_id';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  AuthRepository(this._api);

  User? get currentUser => _currentUser;

  Stream<void> get onAuthExpired => _api.onAuthExpired;

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> restoreSession() async {
    final token = await getToken();
    if (token != null) {
      _api.setToken(token);
      try {
        final data = await _api.fetchSelf();
        _currentUser = User.fromJson(data);
      } catch (_) {
        await logout();
      }
    }
  }

  Future<Session> login(String email, String password) async {
    final response = await _api.login(LoginRequest(
      email: email,
      password: password,
      friendlyName: 'Stoat Mobile',
    ).toJson());

    final session = Session.fromJson(response);
    _api.setToken(session.token);

    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userIdKey, value: session.userId);

    // Fetch user info
    final userData = await _api.fetchSelf();
    _currentUser = User.fromJson(userData);

    return session;
  }

  Future<Session> register(String email, String password, {String? username}) async {
    final response = await _api.register(RegisterRequest(
      email: email,
      password: password,
      username: username,
    ).toJson());

    final session = Session.fromJson(response);
    _api.setToken(session.token);

    await _storage.write(key: _tokenKey, value: session.token);
    await _storage.write(key: _userIdKey, value: session.userId);

    final userData = await _api.fetchSelf();
    _currentUser = User.fromJson(userData);

    return session;
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}
    await clearSession();
  }

  /// Clear all local session state (called on logout or 401)
  Future<void> clearSession() async {
    _api.setToken(null);
    _currentUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
  }
}
