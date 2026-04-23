import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() =>
      _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _courseController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();

  int _maxSize = 6;
  String _duration = '2 hrs';
  String? _selectedCategory;
  bool _isLoading = false;
  double? _lat;
  double? _lng;

  static const _durations = ['1 hr', '2 hrs', '3 hrs', 'Open-ended'];
  static const _categories = ['CS', 'Business', 'MIS', 'Engineering', 'Other'];

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _detectGps();
  }

  @override
  void dispose() {
    _courseController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  // Silently grab GPS in background for lat/lng — user names the spot manually.
  Future<void> _detectGps() async {
    final position =
        await ref.read(locationServiceProvider).getCurrentPosition();
    if (!mounted) return;
    _lat = position?.latitude ?? 5.7602;
    _lng = position?.longitude ?? -0.2168;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final groupService = ref.read(groupServiceProvider);
      await groupService.createGroup({
        'course_name': _courseController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': _lat ?? 5.7602,
        'longitude': _lng ?? -0.2168,
        'location_name': _locationController.text.trim(),
        'max_size': _maxSize,
        'category': _selectedCategory,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Group created!'),
          backgroundColor: AppConstants.secondaryColor,
        ),
      );
      context.go('/map');
    } on DioException catch (e) {
      final msg =
          e.response?.data['error'] as String? ?? 'Failed to create group.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  static InputDecoration _fieldDecoration({
    required String label,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
    );
  }

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppConstants.darkTextColor,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.darkTextColor,
        elevation: 0,
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/map'),
        ),
        title: const Text(
          'New study group',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Course name ──────────────────────────────────────────────
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Course'),
                  TextFormField(
                    controller: _courseController,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      label: 'Course name',
                      hint: 'e.g. CS 341 — Algorithms',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a course name'
                        : null,
                  ),
                ],
              )),
              const SizedBox(height: 12),

              // ── Description ──────────────────────────────────────────────
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Description'),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                    decoration: _fieldDecoration(
                      label: 'What are you studying?',
                      hint: 'Describe what your group will cover...',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Add a description'
                        : null,
                  ),
                ],
              )),
              const SizedBox(height: 12),

              // ── Location ─────────────────────────────────────────────────
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Location on campus'),
                  TextFormField(
                    controller: _locationController,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      label: 'Where are you studying?',
                      hint: 'e.g. Big Ben, Library Room 2, The Grill',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a campus location'
                        : null,
                  ),
                ],
              )),
              const SizedBox(height: 12),

              // ── Major / category ─────────────────────────────────────────
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Major'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: _fieldDecoration(label: 'Select your major'),
                    hint: const Text('e.g. CS, Business…'),
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) =>
                        v == null ? 'Please select a major' : null,
                  ),
                ],
              )),
              const SizedBox(height: 12),

              // ── Max group size ────────────────────────────────────────────
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Max group size'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepperButton(
                        icon: Icons.remove,
                        onPressed: _maxSize > 2
                            ? () => setState(() => _maxSize--)
                            : null,
                      ),
                      const SizedBox(width: 24),
                      Text(
                        '$_maxSize',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 24),
                      _StepperButton(
                        icon: Icons.add,
                        onPressed: _maxSize < 20
                            ? () => setState(() => _maxSize++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'Min 2 · Max 20',
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ),
                ],
              )),
              const SizedBox(height: 12),

              // ── Session duration ──────────────────────────────────────────
              _card(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Session duration'),
                  Wrap(
                    spacing: 8,
                    children: _durations.map((d) {
                      final selected = _duration == d;
                      return ChoiceChip(
                        label: Text(d),
                        selected: selected,
                        onSelected: (_) => setState(() => _duration = d),
                        selectedColor: AppConstants.primaryColor,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppConstants.darkTextColor,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: selected
                              ? AppConstants.primaryColor
                              : Colors.grey.shade300,
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                ],
              )),
              const SizedBox(height: 28),

              // ── Submit button ─────────────────────────────────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Create group',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed != null
          ? AppConstants.primaryColor.withValues(alpha: 0.1)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: onPressed != null
                ? AppConstants.primaryColor
                : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}
