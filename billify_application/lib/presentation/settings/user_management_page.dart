import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/role_model.dart';
import 'package:billify_application/data/models/user_model.dart';
import 'package:billify_application/presentation/settings/widgets/permission_matrix_widget.dart';
import 'package:billify_application/providers/auth_provider.dart';
import 'package:billify_application/providers/user_management_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _showUserDialog(null);
          } else {
            _showAddRoleDialog();
          }
        },
        backgroundColor: AppTheme.primaryTeal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Add User' : 'Create Role', style: const TextStyle(color: Colors.white)),
      ),
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
              backgroundImage: user.profileImage != null ? FileImage(File(user.profileImage!)) : null,
              child: user.profileImage == null ? const Icon(Icons.person, color: AppTheme.primaryTeal) : null,
            ),
            title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showUserDialog(user),
                ),
                Switch(
                  value: user.isActive,
                  activeColor: AppTheme.primaryTeal,
                  onChanged: (val) {
                    ref.read(userManagementProvider.notifier).updateUser(user.copyWith(isActive: val));
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
              if (_selectedRole != null) {
                ref.read(userManagementProvider.notifier).updateRole(_selectedRole!.copyWith(permissions: newPermissions));
              }
            },
          ),
        ),
      ],
    );
  }

  void _showUserDialog(UserModel? user) {
    final isEditing = user != null;
    final nameController = TextEditingController(text: user?.fullName);
    final emailController = TextEditingController(text: user?.email);
    final phoneController = TextEditingController(text: user?.phone);
    final passwordController = TextEditingController(text: user?.password);
    String? selectedImagePath = user?.profileImage;
    RoleModel? userRole = user != null 
        ? ref.read(userManagementProvider).roles.firstWhere((r) => r.id == user.roleId, orElse: () => ref.read(userManagementProvider).roles.first)
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit User' : 'Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() => selectedImagePath = image.path);
                    }
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
                    backgroundImage: selectedImagePath != null ? FileImage(File(selectedImagePath!)) : null,
                    child: selectedImagePath == null 
                        ? const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryTeal, size: 30)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                TextField(
                  controller: emailController, 
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  enabled: !isEditing,
                ),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Mobile Number')),
                TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<RoleModel>(
                  value: userRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ref.read(userManagementProvider).roles.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                  onChanged: (val) => userRole = val,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            TextButton(
              onPressed: () {
                if (userRole == null) return;
                final updatedUser = UserModel(
                  fullName: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  password: passwordController.text,
                  roleId: userRole!.id,
                  profileImage: selectedImagePath,
                  businessOwnerId: ref.read(authProvider).user?.businessOwnerId ?? ref.read(authProvider).user?.email,
                  isActive: user?.isActive ?? true,
                );
                
                if (isEditing) {
                  ref.read(userManagementProvider.notifier).updateUser(updatedUser);
                } else {
                  ref.read(userManagementProvider.notifier).addUser(updatedUser);
                }
                Navigator.pop(context);
              },
              child: Text(isEditing ? 'UPDATE' : 'CREATE', style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRoleDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Role'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Role Name', hintText: 'e.g. Sales Executive')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              if (nameController.text.isEmpty) return;
              final newRole = RoleModel(
                id: const Uuid().v4(),
                name: nameController.text,
                permissions: {},
              );
              ref.read(userManagementProvider.notifier).addRole(newRole);
              Navigator.pop(context);
            },
            child: const Text('CREATE', style: TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
