import 'package:flutter/material.dart';

// TODO: GroupDetailScreen — shows full info for a single study group: name,
// subject, description, location, member list, and shared notes/images.
// Displays a Join/Leave button based on membership state. Creator sees a
// Delete Group option. Fetches data via GroupService.getGroupById(id) and
// GroupService.getGroupMembers(id). Receives the group [id] as a route param.

class GroupDetailScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Details')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Group ID: $groupId'),
            const SizedBox(height: 8),
            const Text('Full implementation coming soon'),
          ],
        ),
      ),
    );
  }
}
