import 'package:flutter/material.dart';

// TODO: MapScreen — the main map view showing nearby active study groups as
// custom markers on a GoogleMap widget. Uses LocationService to centre the
// camera on the user's position. Tapping a marker navigates to
// /map/group/:id. A FAB opens /map/create-group. Refreshes group pins
// every 30 seconds via a periodic timer.

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Map')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Map coming soon'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: context.push('/map/create-group')
        },
        icon: const Icon(Icons.add),
        label: const Text('New Group'),
      ),
    );
  }
}
