import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  LatLng? _currentPosition;
  List<Map<String, dynamic>> _groups = [];
  final _filteredGroupsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  List<Marker> _markers = [];
  String _selectedFilter = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';
  double _radiusKm = 5.0;
  bool _isLoading = true;
  String? _locationError;
  Timer? _refreshTimer;

  static const _filters = ['All', 'CS', 'Business', 'MIS', 'Engineering'];

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _applyFilter();
      });
    });
    // Show map immediately; groups + GPS run after first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _rebuildMarkers();
      });
      _fetchGroups();
      _initGps();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: 10),
        (_) => _fetchGroups(),
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    _searchController.dispose();
    _filteredGroupsNotifier.dispose();
    super.dispose();
  }

  // ── Init & data fetching ─────────────────────────────────────────────────

  static const _ashesi = LatLng(5.7602, -0.2168);

  void _safeMove(LatLng pos) {
    try { _mapController.move(pos, 17.0); } catch (_) {}
  }

  // Shows last-known position instantly, then refines with a real GPS fix.
  Future<void> _initGps() async {
    final locationService = ref.read(locationServiceProvider);

    // Step 1: instant pin + fetch from cached position (no GPS radio needed).
    final last = await Geolocator.getLastKnownPosition();
    if (mounted && last != null) {
      final latLng = LatLng(last.latitude, last.longitude);
      setState(() { _currentPosition = latLng; _rebuildMarkers(); });
      _safeMove(latLng);
      _fetchGroups(); // re-fetch from real coords immediately
    }

    // Step 2: accurate fix in background.
    final position = await locationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      // Accurate GPS failed — if we already have a position from step 1,
      // groups were already fetched. Nothing more to do.
      return;
    }
    final latLng = LatLng(position.latitude, position.longitude);
    debugPrint('[MapScreen] GPS fix: ${latLng.latitude}, ${latLng.longitude}');
    setState(() { _currentPosition = latLng; _rebuildMarkers(); });
    _safeMove(latLng);
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    final lat = _currentPosition?.latitude ?? _ashesi.latitude;
    final lng = _currentPosition?.longitude ?? _ashesi.longitude;
    try {
      final groupService = ref.read(groupServiceProvider);
      final groups = await groupService.getNearbyGroups(lat, lng);
      debugPrint('[MapScreen] fetched ${groups.length} groups from ($lat, $lng)');
      if (mounted) {
        setState(() {
          _groups = groups;
          _applyFilter();
          _rebuildMarkers();
        });
      }
    } catch (e) {
      debugPrint('[MapScreen] _fetchGroups error: $e');
    }
  }

  // MySQL DECIMAL columns arrive as Strings via mysql2 → JSON → Dio.
  static double? _d(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');
  static int _i(dynamic v, int fallback) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? fallback;
  static bool _isMember(dynamic v) =>
      v is num ? v != 0 : v?.toString() == '1';

  void _rebuildMarkers() {
    final markers = <Marker>[];

    if (_currentPosition != null) {
      markers.add(Marker(
        point: _currentPosition!,
        width: 40,
        height: 40,
        child: Tooltip(
          message: 'You are here',
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppConstants.primaryColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
        ),
      ));
    }

    for (final group in _groups) {
      final lat = _d(group['latitude']);
      final lng = _d(group['longitude']);
      if (lat == null || lng == null) continue;
      final course = group['course_name'] as String? ?? '';
      final memberCount = _i(group['member_count'], 1);
      final maxSize = _i(group['max_size'], 0);
      markers.add(Marker(
        point: LatLng(lat, lng),
        width: 44,
        height: 44,
        child: _PinMarker(
          color: AppConstants.secondaryColor,
          icon: Icons.location_on,
          tooltip: '$course · $memberCount/$maxSize',
        ),
      ));
    }

    _markers = markers;
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  void _applyFilter() {
    final List<Map<String, dynamic>> result;
    if (_selectedFilter == 'All' && _searchQuery.isEmpty) {
      result = List.of(_groups);
    } else {
      result = _groups.where((g) {
        final course = (g['course_name'] as String? ?? '').toLowerCase();
        final category = (g['category'] as String? ?? '');
        final matchesSearch =
            _searchQuery.isEmpty || course.contains(_searchQuery.toLowerCase());
        final matchesChip =
            _selectedFilter == 'All' || _chipMatches(course, category, _selectedFilter);
        return matchesSearch && matchesChip;
      }).toList();
    }
    _filteredGroupsNotifier.value = result;
  }

  bool _chipMatches(String course, String category, String filter) {
    // Prefer the explicit category field set at group creation time.
    if (category.isNotEmpty) return category == filter;
    // Fallback: guess from course name for older groups without a category.
    return switch (filter) {
      'CS'          => course.contains('cs') || course.contains('computer'),
      'Business'    => course.contains('bus') || course.contains('ba') || course.contains('business'),
      'MIS'         => course.contains('mis'),
      'Engineering' => course.contains('eng'),
      _             => true,
    };
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _joinGroup(String groupId) async {
    final groupService = ref.read(groupServiceProvider);
    final success = await groupService.joinGroup(groupId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Joined!' : 'Could not join group.'),
        backgroundColor:
            success ? AppConstants.secondaryColor : Colors.redAccent,
      ),
    );
    if (success) _fetchGroups();
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by course e.g. CS 341...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.black38),
              prefixIcon:
                  Icon(Icons.search, color: AppConstants.primaryColor),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            children: [
              const Icon(Icons.radar, size: 16, color: AppConstants.primaryColor),
              const SizedBox(width: 6),
              Text(
                'Within ${_radiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppConstants.darkTextColor),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: _radiusKm,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    activeColor: AppConstants.primaryColor,
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (v) => setState(() => _radiusKm = v),
                    onChangeEnd: (_) => _fetchGroups(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final selected = _selectedFilter == f;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedFilter = f;
                    _applyFilter();
                  }),
                  selectedColor: AppConstants.primaryColor,
                  labelStyle: TextStyle(
                    color: selected
                        ? Colors.white
                        : AppConstants.darkTextColor,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? AppConstants.primaryColor
                        : Colors.grey.shade300,
                  ),
                  showCheckmark: false,
                  elevation: selected ? 2 : 0,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupList(List<Map<String, dynamic>> groups, ScrollController scrollController) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${groups.length} group${groups.length == 1 ? '' : 's'} nearby',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh,
                      color: AppConstants.primaryColor, size: 20),
                  onPressed: _fetchGroups,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: groups.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No groups nearby.\nCreate one with the + button!',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      MediaQuery.of(context).padding.bottom + 8,
                    ),
                    itemCount: groups.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _buildGroupCard(groups[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final groupId = group['group_id'] as String? ?? '';
    final course = group['course_name'] as String? ?? '';
    final locationName = group['location_name'] as String? ?? '';
    final memberCount = _i(group['member_count'], 1);
    final maxSize = _i(group['max_size'], 0);
    final distance = _d(group['distance_km']);
    final isMember = _isMember(group['is_member']);

    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: groupId.isEmpty
            ? null
            : () => context.push('/map/group/$groupId'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: AppConstants.primaryColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppConstants.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              course,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.people_outline,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 3),
                          Text(
                            '$memberCount / $maxSize',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.black45),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              locationName,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '${distance.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.black38),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: ElevatedButton(
                    onPressed: isMember || groupId.isEmpty
                        ? null
                        : () => _joinGroup(groupId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isMember
                          ? Colors.grey.shade200
                          : AppConstants.secondaryColor,
                      foregroundColor: isMember
                          ? Colors.black45
                          : Colors.white,
                      disabledBackgroundColor: Colors.grey.shade200,
                      disabledForegroundColor: Colors.black45,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      elevation: 0,
                    ),
                    child: Text(isMember ? 'Joined' : 'Join',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      color: AppConstants.primaryColor),
                  SizedBox(height: 16),
                  Text('Getting your location…',
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
            )
          : _locationError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off,
                            size: 64, color: Colors.black26),
                        const SizedBox(height: 16),
                        Text(_locationError!,
                            textAlign: TextAlign.center,
                            style:
                                const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _locationError = null;
                            });
                            _fetchGroups();
                            _initGps();
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    // ── OpenStreetMap via flutter_map ────────────────────
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentPosition ??
                            const LatLng(5.7602, -0.2168),
                        initialZoom: 16,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ashesi.studysync',
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),

                    // ── Search bar + filter chips ────────────────────────
                    Positioned(
                      top: topPadding + 8,
                      left: 12,
                      right: 12,
                      child: _buildSearchBar(),
                    ),

                    // ── Draggable bottom sheet ───────────────────────────
                    DraggableScrollableSheet(
                      initialChildSize: 0.35,
                      minChildSize: 0.1,
                      maxChildSize: 0.7,
                      builder: (_, scrollController) =>
                          ValueListenableBuilder<List<Map<String, dynamic>>>(
                        valueListenable: _filteredGroupsNotifier,
                        builder: (context, groups, _) => ClipRect(
                          child: _buildGroupList(groups, scrollController),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push('/map/create-group');
          _fetchGroups();
        },
        tooltip: 'Create group',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Reusable map pin widget — avoids BitmapDescriptor entirely.
class _PinMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String tooltip;

  const _PinMarker({
    required this.color,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 36,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4)]),
    );
  }
}
