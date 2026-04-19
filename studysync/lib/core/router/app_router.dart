import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/features/admin/screens/admin_dashboard_screen.dart';
import 'package:studysync/features/auth/screens/login_screen.dart';
import 'package:studysync/features/auth/screens/register_screen.dart';
import 'package:studysync/features/camera/screens/camera_screen.dart';
import 'package:studysync/features/groups/screens/create_group_screen.dart';
import 'package:studysync/features/groups/screens/group_detail_screen.dart';
import 'package:studysync/features/map/screens/map_screen.dart';
import 'package:studysync/features/profile/screens/profile_screen.dart';
import 'package:studysync/features/splash/screens/splash_screen.dart';

// Shell scaffold that holds the bottom navigation bar.
class _ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

  static const _tabs = [
    NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Map'),
    NavigationDestination(icon: Icon(Icons.group_outlined), label: 'Groups'),
    NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'Camera'),
    NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: _tabs,
      ),
    );
  }
}

// A minimal placeholder for the /groups tab inside the shell.
class _GroupsListScreen extends StatelessWidget {
  const _GroupsListScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Groups')),
      body: const Center(child: Text('Groups list coming soon')),
    );
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // ── Unauthenticated routes ──────────────────────────────────────────
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, _) => const RegisterScreen(),
      ),

      // ── Admin (standalone, no bottom nav) ──────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminDashboardScreen(),
      ),

      // ── Main shell with bottom navigation ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _ShellScaffold(navigationShell: shell),
        branches: [
          // Branch 0 — Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (_, _) => const MapScreen(),
                routes: [
                  GoRoute(
                    path: 'create-group',
                    builder: (_, _) => const CreateGroupScreen(),
                  ),
                  GoRoute(
                    path: 'group/:id',
                    builder: (_, state) => GroupDetailScreen(
                      groupId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1 — Groups list
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (_, _) => const _GroupsListScreen(),
              ),
            ],
          ),

          // Branch 2 — Camera
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/camera',
                builder: (_, _) => const CameraScreen(),
              ),
            ],
          ),

          // Branch 3 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
