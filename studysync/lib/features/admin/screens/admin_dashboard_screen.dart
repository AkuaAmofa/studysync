import 'package:flutter/material.dart';

// TODO: AdminDashboardScreen — restricted to users with isAdmin == true.
// Shows aggregate stats (total groups, active users, reported content) and
// lists all groups with the ability to delete any group via
// GroupService.deleteGroup(). Guard this route in app_router.dart so that
// non-admin users are redirected to /map.

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.admin_panel_settings_outlined,
                size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Admin dashboard coming soon'),
          ],
        ),
      ),
    );
  }
}
