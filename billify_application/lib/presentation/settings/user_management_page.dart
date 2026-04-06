import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/presentation/settings/widgets/permission_matrix_widget.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/user_management_provider.dart';
import 'package:billify_application/data/models/user_permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

class UserManagementPage extends ConsumerStatefulWidget {
  const UserManagementPage({super.key});

  @override
  ConsumerState<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends ConsumerState<UserManagementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RoleModel? _selectedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey[400],
          indicatorColor: AppTheme.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Users List'),
            Tab(text: 'Roles & Permissions'),
          ],
        ),
      ),
      body: state.isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(state.users, state.roles),
                _buildRolesAndPermissions(state.roles),
              ],
            ),
      floatingActionButton: ref.watch(authProvider).hasPermission(PermissionModule.userManagement, PermissionAction.add)
          ? FloatingActionButton.extended(
              onPressed: () {
                if (_tabController.index == 0) {
                  _showUserBottomSheet(null);
                } else {
                  _showRoleBottomSheet();
                }
              },
              backgroundColor: AppTheme.primaryTeal,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(_tabController.index == 0 ? 'Add User' : 'Create Role', style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _buildUsersList(List<UserModel> users, List<RoleModel> roles) {
    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]),
            const SizedBox(height: 16),
            Text('No staff members added yet', style: TextStyle(color: Theme.of(context).hintColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final role = roles.firstWhere((r) => r.id == user.roleId, orElse: () => roles.first);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
              backgroundImage: user.photo != null 
                ? (user.photo!.startsWith('data:image') || user.photo!.length > 100 
                    ? MemoryImage(base64Decode(user.photo!.split(',').last)) 
                    : FileImage(File(user.photo!)) as ImageProvider)
                : null,
              child: user.photo == null ? const Icon(Icons.person, color: AppTheme.primaryTeal) : null,
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.email, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role.name, style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ref.watch(authProvider).hasPermission(PermissionModule.userManagement, PermissionAction.update))
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showUserBottomSheet(user),
                  ),
                if (ref.watch(authProvider).hasPermission(PermissionModule.userManagement, PermissionAction.update))
                  Switch(
                    value: user.status,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (val) {
                      ref.read(userManagementProvider.notifier).updateUser(user.copyWith(status: val));
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRolesAndPermissions(List<RoleModel> roles) {
    if (roles.isEmpty) return const SizedBox.shrink();
    
    // Always sync _selectedRole with the latest version from the provider state
    if (_selectedRole != null) {
      _selectedRole = roles.firstWhere((r) => r.id == _selectedRole!.id, orElse: () => roles.first);
    } else {
      _selectedRole = roles.firstWhere((r) => r.id == 'admin', orElse: () => roles.first);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Role to Manage', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RoleModel>(
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    value: _selectedRole,
                    isExpanded: true,
                    items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                    onChanged: (val) => setState(() => _selectedRole = val),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PermissionMatrixWidget(
            key: ValueKey(_selectedRole?.id),
            initialPermissions: _selectedRole?.permissions ?? {},
            onPermissionsChanged: (newPermissions) {
              if (_selectedRole != null && ref.read(authProvider).hasPermission(PermissionModule.userManagement, PermissionAction.update)) {
                ref.read(userManagementProvider.notifier).updateRole(_selectedRole!.copyWith(permissions: newPermissions));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('You do not have permission to update roles')),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showUserBottomSheet(UserModel? user) {
    final isEditing = user != null;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user?.name);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.mobile);
    final passwordController = TextEditingController();
    String? base64Image = user?.photo;
    RoleModel? userRole = user != null 
        ? ref.read(userManagementProvider).roles.firstWhere((r) => r.id == user.roleId, orElse: () => ref.read(userManagementProvider).roles.first)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isEditing ? 'Edit Staff Member' : 'Add New Staff Member',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 70);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setSheetState(() => base64Image = base64Encode(bytes));
                      }
                    },
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                          backgroundImage: base64Image != null 
                              ? MemoryImage(base64Decode(base64Image!.split(',').last)) 
                              : null,
                          child: base64Image == null 
                              ? const Icon(Icons.person_outline, color: AppTheme.primaryTeal, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppTheme.primaryTeal, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: emailController, 
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    enabled: !isEditing,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Email is required';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: phoneController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Mobile is required';
                      if (val.length < 10) return 'Enter a valid 10-digit number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: isEditing ? 'New Password (Optional)' : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: isEditing ? 'Leave blank to keep current' : null,
                    ),
                    obscureText: true,
                    validator: (val) {
                      if (!isEditing && (val == null || val.isEmpty)) return 'Password is required';
                      if (val != null && val.isNotEmpty && val.length < 6) return 'Password must be at least 6 chars';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<RoleModel>(
                    value: userRole,
                    decoration: InputDecoration(
                      labelText: 'Assign Role',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ref.read(userManagementProvider).roles.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                    onChanged: (val) => setSheetState(() => userRole = val),
                    validator: (val) => val == null ? 'Role is required' : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate() || userRole == null) return;
                        
                        final updatedUser = UserModel(
                          id: user?.id,
                          name: nameController.text.trim(),
                          email: emailController.text.trim(),
                          mobile: phoneController.text.trim(),
                          password: passwordController.text.isNotEmpty ? passwordController.text : null,
                          roleId: userRole!.id,
                          photo: base64Image,
                          businessOwnerId: ref.read(authProvider).user?.businessOwnerId ?? ref.read(authProvider).user?.email,
                          status: user?.status ?? true,
                        );
                        
                        if (isEditing) {
                          ref.read(userManagementProvider.notifier).updateUser(updatedUser);
                        } else {
                          ref.read(userManagementProvider.notifier).addUser(updatedUser);
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        isEditing ? 'UPDATE STAFF' : 'CREATE STAFF',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleBottomSheet() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Create New Role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Role Name',
                  hintText: 'e.g. Sales Executive',
                  prefixIcon: const Icon(Icons.work_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Role name is required' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final newRole = RoleModel(
                      id: const Uuid().v4(),
                      name: nameController.text.trim(),
                      permissions: {},
                    );
                    ref.read(userManagementProvider.notifier).addRole(newRole);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('CREATE ROLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
