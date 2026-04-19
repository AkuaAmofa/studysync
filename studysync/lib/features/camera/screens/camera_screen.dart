import 'package:flutter/material.dart';

// TODO: CameraScreen — lets the user capture or pick an image to attach to a
// group note. Uses image_picker to open the camera or gallery. After capture,
// show a preview with a caption text field, then upload via StorageService
// and save the note via GroupService. Handles camera permission denial.

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Camera coming soon'),
          ],
        ),
      ),
    );
  }
}
