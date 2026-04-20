import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final groups = await ref.read(groupServiceProvider).getMyGroups();
      if (mounted) setState(() { _groups = groups; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Could not load groups.'; _isLoading = false; });
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('My groups',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppConstants.primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _load,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppConstants.primaryColor,
                  child: _groups.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 120),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.group_outlined,
                                      size: 64, color: Colors.black12),
                                  SizedBox(height: 16),
                                  Text(
                                    "You haven't joined any groups yet.\nFind one on the map!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.black45, fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _groups.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) => _buildCard(_groups[i]),
                        ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> group) {
    final groupId = group['group_id'] as String? ?? '';
    final course = group['course_name'] as String? ?? '';
    final locationName = group['location_name'] as String? ?? '';
    final memberCount = group['member_count'] ?? 1;
    final maxSize = group['max_size'] ?? '?';
    final createdAt = group['created_at'] as String?;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: groupId.isEmpty ? null : () => context.push('/map/group/$groupId'),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: AppConstants.primaryColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
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
                            child: Text(course,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600)),
                          ),
                          const Spacer(),
                          const Icon(Icons.people_outline,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 3),
                          Text('$memberCount / $maxSize',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Colors.black45),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(locationName,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (createdAt != null) ...[
                            const SizedBox(width: 6),
                            Text(_timeAgo(createdAt),
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black38)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.chevron_right,
                      color: Colors.black26, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
