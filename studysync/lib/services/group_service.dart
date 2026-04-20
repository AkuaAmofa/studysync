import 'package:dio/dio.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/services/auth_service.dart';

class GroupService {
  final AuthService _authService;
  final Dio _dio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  GroupService({required AuthService authService})
      : _authService = authService;

  Future<Options> _authOptions() async {
    final token = await _authService.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<List<Map<String, dynamic>>> getNearbyGroups(
      double lat, double lng) async {
    final response = await _dio.get(
      '/groups/nearby',
      queryParameters: {'lat': lat, 'lng': lng},
      options: await _authOptions(),
    );
    final raw = response.data['groups'] as List;
    return raw.map((g) => Map<String, dynamic>.from(g as Map)).toList();
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      await _dio.post('/groups/$groupId/join', options: await _authOptions());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/groups',
      data: data,
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(response.data['group'] as Map);
  }

  Future<Map<String, dynamic>> getGroupById(String groupId) async {
    final response = await _dio.get(
      '/groups/$groupId',
      options: await _authOptions(),
    );
    return Map<String, dynamic>.from(response.data['group'] as Map);
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      await _dio.delete('/groups/$groupId/leave',
          options: await _authOptions());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> endGroup(String groupId) async {
    await _dio.patch('/groups/$groupId/end', options: await _authOptions());
  }

  Future<List<Map<String, dynamic>>> getGroupMembers(String groupId) async {
    final response = await _dio.get(
      '/groups/$groupId/members',
      options: await _authOptions(),
    );
    final raw = response.data['members'] as List;
    return raw.map((m) => Map<String, dynamic>.from(m as Map)).toList();
  }

  Future<void> addNote({
    required String groupId,
    required String imageBase64,
    required String caption,
  }) async {
    final auth = await _authOptions();
    await _dio.post(
      '/groups/$groupId/notes',
      data: {'image_url': imageBase64, 'caption': caption},
      options: Options(
        headers: auth.headers,
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getNotes(String groupId) async {
    final response = await _dio.get(
      '/groups/$groupId/notes',
      options: await _authOptions(),
    );
    final raw = response.data['notes'] as List;
    return raw.map((n) => Map<String, dynamic>.from(n as Map)).toList();
  }
}
