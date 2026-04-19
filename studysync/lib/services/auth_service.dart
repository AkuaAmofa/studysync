import 'package:studysync/models/user_model.dart';

/// Handles authentication: login, register, logout, and session persistence.
/// TODO: Implement JWT-based auth against the Node.js backend at /api/auth.
class AuthService {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    // TODO: POST /api/auth/login, store token in flutter_secure_storage
    throw UnimplementedError('login not yet implemented');
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? studentId,
  }) async {
    // TODO: POST /api/auth/register
    throw UnimplementedError('register not yet implemented');
  }

  Future<void> logout() async {
    // TODO: Clear token from secure storage and invalidate session
    _currentUser = null;
  }

  Future<UserModel?> restoreSession() async {
    // TODO: Read token from flutter_secure_storage, validate with backend
    return null;
  }
}
