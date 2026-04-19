import 'package:studysync/models/group_model.dart';
import 'package:studysync/models/member_model.dart';

/// Manages study group CRUD operations and membership.
/// TODO: Implement all methods against the Node.js REST API at /api/groups.
class GroupService {
  Future<List<GroupModel>> getNearbyGroups({
    required double latitude,
    required double longitude,
    double radiusKm = 2.0,
  }) async {
    // TODO: GET /api/groups?lat=&lng=&radius=
    return [];
  }

  Future<GroupModel> createGroup({
    required String name,
    required String subject,
    required String description,
    required double latitude,
    required double longitude,
    required String locationName,
    required int maxMembers,
  }) async {
    // TODO: POST /api/groups
    throw UnimplementedError('createGroup not yet implemented');
  }

  Future<GroupModel> getGroupById(String groupId) async {
    // TODO: GET /api/groups/:id
    throw UnimplementedError('getGroupById not yet implemented');
  }

  Future<void> joinGroup(String groupId) async {
    // TODO: POST /api/groups/:id/join
  }

  Future<void> leaveGroup(String groupId) async {
    // TODO: DELETE /api/groups/:id/members/me
  }

  Future<List<MemberModel>> getGroupMembers(String groupId) async {
    // TODO: GET /api/groups/:id/members
    return [];
  }

  Future<void> deleteGroup(String groupId) async {
    // TODO: DELETE /api/groups/:id (admin or creator only)
  }
}
