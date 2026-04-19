import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:studysync/core/constants/app_constants.dart';
import 'package:studysync/core/providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _programme;
  int? _yearGroup;

  static const _programmes = [
    'Computer Science',
    'Business Administration',
    'Management Information Systems',
    'Engineering',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Returns 0=weak, 1=medium, 2=strong based on password length.
  int _passwordStrength(String pw) {
    if (pw.length > 10) return 2;
    if (pw.length >= 6) return 1;
    return 0;
  }

  Color _strengthColor(int index, int strength) {
    if (index > strength) return Colors.grey.shade300;
    return switch (strength) {
      0 => Colors.red,
      1 => Colors.orange,
      _ => Colors.green,
    };
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_yearGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your year group')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        programme: _programme!,
        yearGroup: _yearGroup!,
      );
      if (mounted) context.go('/map');
    } on DioException catch (e) {
      final message = e.response?.data['error'] as String? ??
          'Registration failed. Try again.';
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
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

  @override
  Widget build(BuildContext context) {
    final password = _passwordController.text;
    final strength = _passwordStrength(password);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Heading
                const Text(
                  'Create your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ashesi University · Berekuso',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.secondaryColor,
                  ),
                ),
                const SizedBox(height: 32),

                // Full name
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Ashesi email',
                    hintText: 'yourname@ashesi.edu.gh',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),

                // Password strength dots
                if (password.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 28,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _strengthColor(i, strength),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ],
                const SizedBox(height: 14),

                // Programme dropdown
                DropdownButtonFormField<String>(
                  initialValue: _programme,
                  decoration: InputDecoration(
                    labelText: 'Programme',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _programmes
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (v) => setState(() => _programme = v),
                  validator: (v) =>
                      v == null ? 'Select your programme' : null,
                ),
                const SizedBox(height: 14),

                // Year group chips
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Year group',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(4, (i) {
                    final year = i + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text('Year $year'),
                        selected: _yearGroup == year,
                        selectedColor: AppConstants.primaryColor,
                        labelStyle: TextStyle(
                          color: _yearGroup == year
                              ? Colors.white
                              : AppConstants.darkTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        onSelected: (_) =>
                            setState(() => _yearGroup = year),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Submit button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Create account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Login link
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Already have an account? Log in',
                    style: TextStyle(color: AppConstants.primaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
