import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studysync/core/constants/app_constants.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String programme,
    required int yearGroup,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'programme': programme,
      'year_group': yearGroup,
    });
    final token = response.data['token'] as String;
    final user = Map<String, dynamic>.from(response.data['user'] as Map);
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user', value: jsonEncode(user));
    return user;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['token'] as String;
    final user = Map<String, dynamic>.from(response.data['user'] as Map);
    await _storage.write(key: 'token', value: token);
    await _storage.write(key: 'user', value: jsonEncode(user));
    return user;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'token');
    return token != null && token.isNotEmpty;
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'token');
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userJson) as Map);
  }
}
