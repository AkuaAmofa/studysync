import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  bool _pushNotifications = true;
  bool _shakeToFind = false;
  bool _darkMode = false;

  StreamSubscription<AccelerometerEvent>? _shakeSub;
  DateTime _lastShake = DateTime(0);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPrefs();
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    super.dispose();
  }

  // ── Data & prefs ──────────────────────────────────────────────────────────

  Future<void> _loadUser() async {
    final user = await ref.read(authServiceProvider).getCurrentUser();
    if (mounted) setState(() { _user = user; _isLoading = false; });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
      });
    }
  }

  Future<void> _setPushNotifications(bool value) async {
    setState(() => _pushNotifications = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('push_notifications', value);
  }

  void _setShakeToFind(bool value) {
    setState(() => _shakeToFind = value);
    if (value) {
      _shakeSub = accelerometerEventStream().listen((event) {
        const threshold = 25.0;
        final magnitude = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z) - 9.8;
        final now = DateTime.now();
        if (magnitude > threshold &&
            now.difference(_lastShake).inMilliseconds > 2000) {
          _lastShake = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Finding nearest group...')),
            );
            context.go('/map');
          }
        }
      });
    } else {
      _shakeSub?.cancel();
      _shakeSub = null;
    }
  }

  Future<void> _logout() async {
    await ref.read(authServiceProvider).logout();
    if (mounted) context.go('/login');
  }

  void _snackbar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _displayProgramme() {
    final p = _user?['programme'] as String? ?? '';
    final y = _user?['year_group'];
    if (p.isEmpty) return '—';
    return y != null ? '$p · Year $y' : p;
  }

  void _showEditProfileSheet() {
    final nameController =
        TextEditingController(text: _user?['name'] as String? ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Edit profile',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _snackbar('Profile updated!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save changes',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordSheet() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Change password',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New password',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text !=
                    confirmPasswordController.text) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Passwords do not match.')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _snackbar('Password updated!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save changes',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(
                color: AppConstants.primaryColor)),
      );
    }

    final name = _user?['name'] as String? ?? 'User';
    final email = _user?['email'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(name, email),
          const SizedBox(height: 16),
          _buildStatsRow(),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Preferences',
            children: [
              _switchTile(
                icon: Icons.notifications_outlined,
                title: 'Push notifications',
                value: _pushNotifications,
                onChanged: _setPushNotifications,
              ),
              _switchTile(
                icon: Icons.vibration,
                title: 'Shake to find group',
                value: _shakeToFind,
                onChanged: _setShakeToFind,
              ),
              _switchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark mode',
                value: _darkMode,
                onChanged: (v) {
                  setState(() => _darkMode = v);
                  _snackbar('Dark mode coming soon');
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSection(
            title: 'Account',
            children: [
              _navTile(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                onTap: _showEditProfileSheet,
              ),
              _navTile(
                icon: Icons.lock_outline,
                title: 'Change password',
                onTap: _showChangePasswordSheet,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFE24B4A)),
                title: const Text(
                  'Log out',
                  style: TextStyle(
                      color: Color(0xFFE24B4A),
                      fontWeight: FontWeight.w600),
                ),
                onTap: _logout,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(String name, String email) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white24,
              child: Text(
                _initials(name),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_displayProgramme(),
                style: const TextStyle(
                    color: Color(0xFFBDB5E8), fontSize: 14)),
            const SizedBox(height: 4),
            Text(email,
                style: const TextStyle(
                    color: Color(0xFFBDB5E8), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _statCard('0', 'Groups\njoined'),
          const SizedBox(width: 10),
          _statCard('0', 'Notes\nshared'),
          const SizedBox(width: 10),
          _statCard('0', 'Sessions\nthis week'),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor)),
            const SizedBox(height: 4),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: children
                  .expand((w) => [
                        w,
                        if (w != children.last)
                          Divider(
                              height: 1,
                              color: Colors.grey.shade100),
                      ])
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor, size: 22),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, color: AppConstants.darkTextColor)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppConstants.primaryColor,
      ),
    );
  }

  Widget _navTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppConstants.primaryColor, size: 22),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, color: AppConstants.darkTextColor)),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.black26, size: 20),
      onTap: onTap,
    );
  }
}
