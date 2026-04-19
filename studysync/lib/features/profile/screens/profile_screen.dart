import 'package:flutter/material.dart';

// TODO: ProfileScreen — displays the logged-in user's avatar, name, student ID,
// and a list of groups they have joined. Allows editing name and avatar via
// image_picker. Shows a logout button that calls AuthService.logout() and
// navigates back to /login. Uses cached_network_image for the avatar.

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            SizedBox(height: 16),
            Text('Profile coming soon'),
          ],
        ),
      ),
    );
  }
}
