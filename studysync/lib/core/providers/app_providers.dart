import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:studysync/services/auth_service.dart';
import 'package:studysync/services/group_service.dart';
import 'package:studysync/services/location_service.dart';
import 'package:studysync/services/storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final groupServiceProvider = Provider<GroupService>((ref) {
  final authService = ref.read(authServiceProvider);
  return GroupService(authService: authService);
});

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService());
