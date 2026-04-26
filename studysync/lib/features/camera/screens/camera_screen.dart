import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class CameraScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const CameraScreen({super.key, this.groupId});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  XFile? _selectedImage;
  final _captionController = TextEditingController();
  bool _isUploading = false;

  // Group selector state (used when no groupId passed via route)
  List<Map<String, dynamic>> _myGroups = [];
  String? _selectedGroupId;
  bool _loadingGroups = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupId == null) _loadMyGroups();
    _retrieveLostData();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadMyGroups() async {
    setState(() => _loadingGroups = true);
    try {
      final groups = await ref.read(groupServiceProvider).getMyGroups();
      if (mounted) setState(() { _myGroups = groups; _loadingGroups = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  // Recovers the image if Android killed the activity while the camera was open.
  Future<void> _retrieveLostData() async {
    final picker = ImagePicker();
    final response = await picker.retrieveLostData();
    if (response.isEmpty || !mounted) return;
    if (response.file != null) {
      setState(() => _selectedImage = response.file);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (image != null) setState(() => _selectedImage = image);
  }

  Future<void> _shareNote() async {
    if (_selectedImage == null) {
      _snack('Take a photo first');
      return;
    }
    final targetGroupId = widget.groupId ?? _selectedGroupId;
    if (targetGroupId == null) {
      _snack('Select a group first');
      return;
    }

    debugPrint('[CameraScreen] Sharing note to group: $targetGroupId');
    setState(() => _isUploading = true);
    try {
      final bytes = await File(_selectedImage!.path).readAsBytes();
      final base64Image = base64Encode(bytes);
      debugPrint('[CameraScreen] Base64 size: ${base64Image.length} chars');

      final groupService = ref.read(groupServiceProvider);
      await groupService.addNote(
        groupId: targetGroupId,
        imageBase64: base64Image,
        caption: _captionController.text.trim(),
      );

      if (!mounted) return;
      _snack('Note shared!');
      context.pop();
    } on DioException catch (e) {
      debugPrint('[CameraScreen] DioException: ${e.response?.statusCode} — ${e.response?.data}');
      if (mounted) {
        final msg = e.response?.data?['error'] as String? ?? 'Upload failed. Try again.';
        _snack(msg);
      }
    } catch (e) {
      debugPrint('[CameraScreen] Unexpected error: $e');
      if (mounted) _snack('Failed to share note. Try again.');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.canPop() ? context.pop() : context.go('/camera'),
        ),
        title: const Text(
          'Share a note',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Image preview / placeholder ──────────────────────────────────
          Expanded(
            child: _selectedImage == null
                ? Container(
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 72, color: Colors.white24),
                          SizedBox(height: 16),
                          Text(
                            'Tap camera to take a photo\nor choose from gallery',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white38, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox.expand(
                    child: Image.file(
                      File(_selectedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),
          ),

          // ── Bottom panel ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Shutter + gallery row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gallery button
                    _CircleButton(
                      size: 48,
                      color: Colors.grey.shade100,
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Icon(Icons.image_outlined,
                          color: AppConstants.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 24),
                    // Shutter button
                    _CircleButton(
                      size: 70,
                      color: AppConstants.primaryColor,
                      onTap: () => _pickImage(ImageSource.camera),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 32),
                    ),
                    // Spacer to balance the layout
                    const SizedBox(width: 72),
                  ],
                ),
                const SizedBox(height: 16),

                // Group selector (only when not launched from a specific group)
                if (widget.groupId == null) ...[
                  if (_loadingGroups)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppConstants.primaryColor),
                      ),
                    )
                  else if (_myGroups.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "You're not in any active groups yet.",
                              style: TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/map'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppConstants.primaryColor,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Find one', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGroupId,
                      decoration: InputDecoration(
                        labelText: 'Select group',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F7),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      hint: const Text('Choose a group'),
                      items: _myGroups.map((g) {
                        return DropdownMenuItem<String>(
                          value: g['group_id'] as String,
                          child: Text(
                            g['course_name'] as String? ?? 'Group',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedGroupId = v),
                    ),
                  const SizedBox(height: 12),
                ],

                // Caption field
                TextField(
                  controller: _captionController,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 14),

                // Share button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _shareNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.secondaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Share to group',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final double size;
  final Color color;
  final VoidCallback onTap;
  final Widget child;

  const _CircleButton({
    required this.size,
    required this.color,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: child),
      ),
    );
  }
}
