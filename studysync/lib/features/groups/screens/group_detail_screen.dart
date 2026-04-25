import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  String? _error;
  bool _isLeaving = false;
  bool _isExtending = false;
  bool _isJoining = false;
  String? _currentUserId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _initUser();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadSilent());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initUser() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (mounted) setState(() => _currentUserId = user?['user_id'] as String?);
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _load() async {
    try {
      final gs = ref.read(groupServiceProvider);
      final results = await Future.wait([
        gs.getGroupById(widget.groupId),
        gs.getGroupMembers(widget.groupId),
        gs.getNotes(widget.groupId),
      ]);
      if (!mounted) return;
      setState(() {
        _group = results[0] as Map<String, dynamic>;
        _members = (results[1] as List).cast<Map<String, dynamic>>();
        _notes = (results[2] as List).cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load group details.';
          _isLoading = false;
        });
      }
    }
  }

  // Silent refresh — updates data without showing the full loading spinner.
  Future<void> _loadSilent() async {
    try {
      final gs = ref.read(groupServiceProvider);
      final results = await Future.wait([
        gs.getGroupById(widget.groupId),
        gs.getGroupMembers(widget.groupId),
        gs.getNotes(widget.groupId),
      ]);
      if (!mounted) return;
      setState(() {
        _group = results[0] as Map<String, dynamic>;
        _members = (results[1] as List).cast<Map<String, dynamic>>();
        _notes = (results[2] as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _joinGroup() async {
    setState(() => _isJoining = true);
    final success = await ref.read(groupServiceProvider).joinGroup(widget.groupId);
    if (!mounted) return;
    setState(() => _isJoining = false);
    if (success) {
      await _loadSilent();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined!'), backgroundColor: AppConstants.secondaryColor),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not join group.')),
        );
      }
    }
  }

  Future<void> _extendGroup() async {
    setState(() => _isExtending = true);
    try {
      await ref.read(groupServiceProvider).extendGroup(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group extended by 24 hours!'), backgroundColor: AppConstants.secondaryColor),
        );
        await _loadSilent();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not extend group.')));
    } finally {
      if (mounted) setState(() => _isExtending = false);
    }
  }

  Future<void> _leaveGroup() async {
    setState(() => _isLeaving = true);
    final gs = ref.read(groupServiceProvider);
    final success = await gs.leaveGroup(widget.groupId);
    if (!mounted) return;
    setState(() => _isLeaving = false);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You left the group.')),
      );
      context.go('/map');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not leave group. Try again.')),
      );
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _timeAgo(String? raw) {
    if (raw == null) return 'recently';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return 'recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // Avatar colour cycle so each member gets a distinct hue.
  static const _avatarColors = [
    Color(0xFF534AB7),
    Color(0xFF1D9E75),
    Color(0xFFE24B4A),
    Color(0xFFFF9800),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
  ];

  // ── Derived state ─────────────────────────────────────────────────────────

  bool get _isMember => _currentUserId != null &&
      _members.any((m) => m['user_id'] == _currentUserId);

  bool get _isCreator => _currentUserId != null &&
      _group?['creator_id'] == _currentUserId;

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final course =
        _group?['course_name'] as String? ?? 'Study Group';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/map'),
        ),
        title: Text(
          course,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
      ),
      floatingActionButton: _isMember
          ? FloatingActionButton(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              tooltip: 'Share a note',
              onPressed: () => context.push('/camera?groupId=${widget.groupId}'),
              child: const Icon(Icons.camera_alt),
            )
          : null,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  color: AppConstants.primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.black26),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style:
                              const TextStyle(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildHeaderCard(),
                    const SizedBox(height: 12),
                    _buildMembersCard(),
                    const SizedBox(height: 12),
                    _buildActionButtons(),
                    const SizedBox(height: 12),
                    _buildNotesCard(),
                    const SizedBox(height: 80),
                  ],
                ),
    );
  }

  Widget _buildHeaderCard() {
    final locationName =
        _group?['location_name'] as String? ?? '—';
    final memberCount =
        _group?['member_count'] ?? (_members.isEmpty ? 1 : _members.length);
    final maxSize = _group?['max_size'] ?? '?';
    final createdAt = _group?['created_at'] as String?;
    final description = _group?['description'] as String?;

    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _group?['course_name'] as String? ?? '',
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkTextColor),
        ),
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(description,
              style:
                  const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
        const SizedBox(height: 14),
        _infoRow(Icons.location_on_outlined, locationName),
        const SizedBox(height: 8),
        _infoRow(Icons.access_time_outlined,
            'Started ${_timeAgo(createdAt)}'),
        const SizedBox(height: 8),
        _infoRow(Icons.people_outline,
            '$memberCount of $maxSize members'),
      ],
    ));
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 13, color: Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildMembersCard() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Members',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkTextColor),
        ),
        const SizedBox(height: 14),
        _members.isEmpty
            ? const Text('No members yet.',
                style: TextStyle(color: Colors.black45, fontSize: 13))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_members.length, (i) {
                    final name =
                        _members[i]['name'] as String? ?? '?';
                    final color =
                        _avatarColors[i % _avatarColors.length];
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: color,
                            child: Text(
                              _initials(name),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 56,
                            child: Text(
                              name.split(' ').first,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
      ],
    ));
  }

  Widget _buildActionButtons() {
    if (!_isMember) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isJoining ? null : _joinGroup,
          icon: _isJoining
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.group_add, size: 18),
          label: const Text('Join group'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.secondaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLeaving ? null : _leaveGroup,
                icon: _isLeaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE24B4A)))
                    : const Icon(Icons.exit_to_app, size: 18),
                label: const Text('Leave group'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE24B4A),
                  side: const BorderSide(color: Color(0xFFE24B4A)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/camera?groupId=${widget.groupId}'),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Share note'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
        if (_isCreator) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isExtending ? null : _extendGroup,
              icon: _isExtending
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.primaryColor))
                  : const Icon(Icons.timer_outlined, size: 18),
              label: const Text('Extend by 24 hours'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
                side: const BorderSide(color: AppConstants.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNotesCard() {
    return _card(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shared notes',
          style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkTextColor),
        ),
        const SizedBox(height: 16),
        if (_notes.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(Icons.note_outlined,
                    size: 40, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                const Text(
                  'No notes yet. Share one!',
                  style: TextStyle(color: Colors.black38, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _notes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _buildNoteItem(_notes[i]),
          ),
        const SizedBox(height: 4),
      ],
    ));
  }

  Widget _buildNoteItem(Map<String, dynamic> note) {
    final caption = note['caption'] as String?;
    final uploaderName = note['uploader_name'] as String? ?? 'Unknown';
    final uploadedAt = note['uploaded_at'] as String?;
    final imageData = note['image_url'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imageData != null && imageData.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              base64Decode(imageData),
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(height: 6),
        if (caption != null && caption.isNotEmpty)
          Text(caption,
              style: const TextStyle(fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(
          '$uploaderName · ${_timeAgo(uploadedAt)}',
          style: const TextStyle(fontSize: 11, color: Colors.black38),
        ),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}
