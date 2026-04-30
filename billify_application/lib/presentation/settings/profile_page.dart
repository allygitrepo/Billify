import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/presentation/widgets/full_screen_image_viewer.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/presentation/widgets/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _roleController;
  String? _selectedImagePath;
  bool _isObscured = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    debugPrint(
      'Initializing ProfilePage with user: ${user?.name}, mobile: ${user?.mobile}',
    );
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.mobile ?? '');
    _passwordController = TextEditingController(
      text: '',
    ); // Leave empty for change
    _roleController = TextEditingController(
      text: ref.read(authProvider).currentRole?.name ?? 'Admin / Owner',
    );
    _selectedImagePath = user?.photo;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      setState(
        () => _selectedImagePath = 'data:image/jpeg;base64,$base64String',
      );
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(authProvider).user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      name: _nameController.text,
      mobile: _phoneController.text,
      photo: _selectedImagePath,
    );

    try {
      String? oldPassword;
      String? newPassword;

      if (_passwordController.text.isNotEmpty) {
        // Simple password change flow
        final result = await _showPasswordConfirmDialog();
        if (result == null) return;
        oldPassword = result;
        newPassword = _passwordController.text;
      }

      await ref
          .read(authProvider.notifier)
          .updateProfile(
            updatedUser,
            oldPassword: oldPassword,
            newPassword: newPassword,
          );

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(
          context,
          'Profile updated successfully!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<String?> _showPasswordConfirmDialog() async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please enter your CURRENT password to confirm changes.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullScreenImageViewer(
                                  imagePath: _selectedImagePath,
                                  tag: 'profile_photo_page',
                                ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'profile_photo_page',
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryTeal,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: Theme.of(context).cardColor,
                                backgroundImage:
                                    _selectedImagePath != null &&
                                        _selectedImagePath!.isNotEmpty
                                    ? (_selectedImagePath!.startsWith('http')
                                          ? NetworkImage(_selectedImagePath!)
                                          : (_selectedImagePath!.startsWith(
                                                      'data:image',
                                                    ) ||
                                                    _selectedImagePath!.length >
                                                        100
                                                ? MemoryImage(
                                                    ImageUtils.decodeBase64(
                                                      _selectedImagePath!,
                                                    ),
                                                  )
                                                : FileImage(
                                                        File(
                                                          _selectedImagePath!,
                                                        ),
                                                      )
                                                      as ImageProvider))
                                    : null,
                                child:
                                    _selectedImagePath == null ||
                                        _selectedImagePath!.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[400],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: user?.email ?? 'Not Set',
                      enabled: false,
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Email Address (Cannot be changed)',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _roleController,
                      enabled: false,

                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black54,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Assigned Role',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[900]
                            : Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Mobile Number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please enter your phone number'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscured,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        hintText: 'Leave blank to keep current',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isObscured
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _isObscured = !_isObscured),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'Update Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
