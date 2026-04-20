import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/providers/app_providers.dart';
import 'package:studysync/features/admin/screens/admin_dashboard_screen.dart';
import 'package:studysync/features/auth/screens/login_screen.dart';
import 'package:studysync/features/auth/screens/register_screen.dart';
import 'package:studysync/features/camera/screens/camera_screen.dart';
import 'package:studysync/features/groups/screens/create_group_screen.dart';
import 'package:studysync/features/groups/screens/group_detail_screen.dart';
import 'package:studysync/features/map/screens/map_screen.dart';
import 'package:studysync/features/profile/screens/profile_screen.dart';
import 'package:studysync/features/splash/screens/splash_screen.dart';

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

// Routes that require authentication (shell routes).
const _protectedPaths = ['/map', '/groups', '/camera', '/profile'];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.read(authServiceProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final path = state.matchedLocation;

      // Let splash handle its own redirect.
      if (path == '/splash') return null;

      final isAuth = await authService.isLoggedIn();
      final isOnAuth = path == '/login' || path == '/register';
      final isProtected =
          _protectedPaths.any((p) => path == p || path.startsWith('$p/'));

      if (!isAuth && isProtected) return '/login';
      if (isAuth && isOnAuth) return '/map';
      return null;
    },
    routes: [
      // ── Unauthenticated ────────────────────────────────────────────────
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

      // ── Admin ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin',
        builder: (_, _) => const AdminDashboardScreen(),
      ),

      // ── Main shell with bottom navigation ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => _ShellScaffold(navigationShell: shell),
        branches: [
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (_, _) => const _GroupsListScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/camera',
                builder: (_, state) {
                  final groupId = state.uri.queryParameters['groupId'];
                  return CameraScreen(groupId: groupId);
                },
              ),
            ],
          ),
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
