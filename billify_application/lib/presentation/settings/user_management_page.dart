import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/app_feedback.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/data/models/role_model.dart';
import 'package:billify/data/models/user_model.dart';
import 'package:billify/presentation/settings/widgets/permission_matrix_widget.dart';
import 'package:billify/presentation/widgets/app_banner_ad.dart';
import 'package:billify/providers/auth_provider.dart';
import 'package:billify/providers/user_management_provider.dart';
import 'package:billify/data/models/user_permission.dart';
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

class _UserManagementPageState extends ConsumerState<UserManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RoleModel? _selectedRole;
  Map<PermissionModule, List<PermissionAction>> _draftPermissions = {};
  bool _isSavingRole = false;
  bool _hasUnsavedRoleChanges = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _onRoleChanged(RoleModel? role) {
    if (role == null) return;
    setState(() {
      _selectedRole = role;
      _draftPermissions = {
        for (var entry in role.permissions.entries)
          entry.key: List<PermissionAction>.from(entry.value),
      };
      _hasUnsavedRoleChanges = false;
    });
  }

  Future<void> _saveRolePermissions() async {
    if (_selectedRole == null) return;

    if (!ref.read(authProvider).hasPermission(
          PermissionModule.userManagement,
          PermissionAction.update,
        )) {
      AppFeedback.showError(
        context,
        'You do not have permission to update roles',
      );
      return;
    }

    setState(() => _isSavingRole = true);

    try {
      final updatedRole = _selectedRole!.copyWith(
        permissions: _draftPermissions,
      );
      final success = await ref
          .read(userManagementProvider.notifier)
          .updateRole(updatedRole);

      if (mounted) {
        if (success) {
          setState(() {
            _selectedRole = updatedRole;
            _hasUnsavedRoleChanges = false;
          });
          AppFeedback.showSuccess(
            context,
            'Permissions for "${updatedRole.name}" updated successfully',
          );
        } else {
          AppFeedback.showError(
            context,
            'Failed to update permissions. Please try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingRole = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);
    final canAddUser = ref.watch(authProvider).hasPermission(
          PermissionModule.userManagement,
          PermissionAction.add,
        );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[600]
              : Colors.grey[400],
          indicatorColor: AppTheme.primaryTeal,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Users List'),
            Tab(text: 'Roles & Permissions'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(state.users, state.roles),
                _buildRolesAndPermissions(state.roles),
              ],
            ),
      bottomNavigationBar: const SafeArea(
        child: AppBannerAd(),
      ),
      floatingActionButton: _tabController.index == 0 && canAddUser
          ? FloatingActionButton.extended(
              onPressed: () => _showUserBottomSheet(null),
              backgroundColor: AppTheme.primaryTeal,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text(
                'Add Staff',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
            Icon(
              Icons.people_outline,
              size: 64,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
            ),
            const SizedBox(height: 16),
            Text(
              'No staff members added yet',
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final role = roles.firstWhere(
          (r) => r.id == user.roleId,
          orElse: () => roles.first,
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTeal.withOpacity(0.1),
              backgroundImage: user.photo != null
                  ? (user.photo!.startsWith('http')
                        ? NetworkImage(user.photo!)
                        : (user.photo!.startsWith('data:image') ||
                                  user.photo!.length > 100
                              ? MemoryImage(
                                  ImageUtils.decodeBase64(user.photo!),
                                )
                              : FileImage(File(user.photo!)) as ImageProvider))
                  : null,
              child: user.photo == null
                  ? const Icon(Icons.person, color: AppTheme.primaryTeal)
                  : null,
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.mobile, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    role.name,
                    style: const TextStyle(
                      color: AppTheme.primaryTeal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ref.watch(authProvider).hasPermission(
                      PermissionModule.userManagement,
                      PermissionAction.update,
                    ))
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () => _showUserBottomSheet(user),
                  ),
                if (ref.watch(authProvider).hasPermission(
                      PermissionModule.userManagement,
                      PermissionAction.update,
                    ))
                  Switch(
                    value: user.status,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (val) {
                      ref
                          .read(userManagementProvider.notifier)
                          .updateUser(user.copyWith(status: val));
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
    if (roles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No roles found'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showRoleBottomSheet,
              icon: const Icon(Icons.add),
              label: const Text('Create Role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
              ),
            ),
          ],
        ),
      );
    }

    // Sync _selectedRole with latest available roles list if not set or invalid
    if (_selectedRole == null || !roles.any((r) => r.id == _selectedRole!.id)) {
      _selectedRole = roles.firstWhere(
        (r) => r.id == 'admin',
        orElse: () => roles.first,
      );
      _draftPermissions = {
        for (var entry in _selectedRole!.permissions.entries)
          entry.key: List<PermissionAction>.from(entry.value),
      };
      _hasUnsavedRoleChanges = false;
    }

    final canManageRoles = ref.watch(authProvider).hasPermission(
          PermissionModule.userManagement,
          PermissionAction.update,
        );

    final canCreateRole = ref.watch(authProvider).hasPermission(
          PermissionModule.userManagement,
          PermissionAction.add,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Role to Manage',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  if (canCreateRole)
                    InkWell(
                      onTap: _showRoleBottomSheet,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 16,
                              color: AppTheme.primaryTeal,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'New Role',
                              style: TextStyle(
                                color: AppTheme.primaryTeal,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
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
                    items: roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _onRoleChanged,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PermissionMatrixWidget(
            key: ValueKey('${_selectedRole?.id}'),
            initialPermissions: _selectedRole?.permissions ?? {},
            onPermissionsChanged: (newPermissions) {
              setState(() {
                _draftPermissions = newPermissions;
                _hasUnsavedRoleChanges = true;
              });
            },
          ),
        ),
        // Action Bar for saving permissions to DB
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (canCreateRole) ...[
                  Expanded(
                    flex: 2,
                    child: OutlinedButton.icon(
                      onPressed: _showRoleBottomSheet,
                      icon: const Icon(Icons.add, color: AppTheme.primaryTeal),
                      label: const Text(
                        'Create Role',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryTeal),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: canManageRoles && !_isSavingRole
                        ? _saveRolePermissions
                        : null,
                    icon: _isSavingRole
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _hasUnsavedRoleChanges
                                ? Icons.save
                                : Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                    label: Text(
                      _isSavingRole
                          ? 'Updating...'
                          : (_hasUnsavedRoleChanges
                              ? 'Update Permissions'
                              : 'Update Permissions'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      disabledBackgroundColor:
                          AppTheme.primaryTeal.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
        ? ref
              .read(userManagementProvider)
              .roles
              .firstWhere(
                (r) => r.id == user.roleId,
                orElse: () => ref.read(userManagementProvider).roles.first,
              )
        : null;
    bool isSubmitting = false;
    bool isPasswordObscured = true;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                bottom: true,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.85,
                  child: Padding(
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
                        isEditing
                            ? 'Edit Staff Member'
                            : 'Add New Staff Member',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                            maxWidth: 512,
                            maxHeight: 512,
                            imageQuality: 70,
                          );
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            setSheetState(
                              () => base64Image = base64Encode(bytes),
                            );
                          }
                        },
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppTheme.primaryTeal.withOpacity(
                                0.1,
                              ),
                              backgroundImage: base64Image != null
                                  ? MemoryImage(
                                      ImageUtils.decodeBase64(base64Image!),
                                    )
                                  : null,
                              child: base64Image == null
                                  ? const Icon(
                                      Icons.person_outline,
                                      color: AppTheme.primaryTeal,
                                      size: 40,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryTeal,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
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
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        enabled: !isEditing,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(val)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          prefixIcon: const Icon(Icons.phone_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Mobile is required';
                          }
                          if (val.length < 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: passwordController,
                        obscureText: isPasswordObscured,
                        decoration: InputDecoration(
                          labelText: isEditing
                              ? 'New Password (Optional)'
                              : 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordObscured
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onPressed: () {
                              setSheetState(() {
                                isPasswordObscured = !isPasswordObscured;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: isEditing
                              ? 'Leave blank to keep current'
                              : null,
                        ),
                        validator: (val) {
                          if (!isEditing && (val == null || val.isEmpty)) {
                            return 'Password is required';
                          }
                          if (val != null &&
                              val.isNotEmpty &&
                              val.length < 6) {
                            return 'Password must be at least 6 chars';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<RoleModel>(
                        value: userRole,
                        decoration: InputDecoration(
                          labelText: 'Assign Role',
                          prefixIcon: const Icon(Icons.badge_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ref
                            .read(userManagementProvider)
                            .roles
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) =>
                            setSheetState(() => userRole = val),
                        validator: (val) =>
                            val == null ? 'Role is required' : null,
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate() ||
                                      userRole == null) {
                                    return;
                                  }

                                  final inputPhone = phoneController.text.trim();
                                  final inputEmail = emailController.text.trim();
                                  final currentAuthUser =
                                      ref.read(authProvider).user;

                                  // Check if phone or email is already registered as owner
                                  if (!isEditing && currentAuthUser != null) {
                                    final isOwnerPhone =
                                        currentAuthUser.mobile.isNotEmpty &&
                                            currentAuthUser.mobile ==
                                                inputPhone;
                                    final isOwnerEmail =
                                        currentAuthUser.email != null &&
                                            currentAuthUser.email!.isNotEmpty &&
                                            currentAuthUser.email ==
                                                inputEmail;

                                    if (isOwnerPhone || isOwnerEmail) {
                                      AppFeedback.showError(
                                        context,
                                        'This phone number is already registered as a business owner and cannot be added as a staff member.',
                                      );
                                      return;
                                    }
                                  }

                                  setSheetState(() => isSubmitting = true);

                                  try {
                                    final updatedUser = UserModel(
                                      id: user?.id,
                                      name: nameController.text.trim(),
                                      email: inputEmail,
                                      mobile: inputPhone,
                                      password:
                                          passwordController.text.isNotEmpty
                                              ? passwordController.text
                                              : null,
                                      roleId: userRole!.id,
                                      photo: base64Image,
                                      businessOwnerId:
                                          ref
                                              .read(authProvider)
                                              .user
                                              ?.businessOwnerId ??
                                          ref
                                              .read(authProvider)
                                              .user
                                              ?.email,
                                      status: user?.status ?? true,
                                    );

                                    if (isEditing) {
                                      await ref
                                          .read(
                                            userManagementProvider.notifier,
                                          )
                                          .updateUser(updatedUser);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        AppFeedback.showSuccess(
                                          context,
                                          'Staff updated successfully',
                                        );
                                      }
                                    } else {
                                      await ref
                                          .read(
                                            userManagementProvider.notifier,
                                          )
                                          .addUser(updatedUser);
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        AppFeedback.showSuccess(
                                          context,
                                          'Staff created successfully',
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      AppFeedback.showError(context, e);
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setSheetState(
                                        () => isSubmitting = false,
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'UPDATE STAFF' : 'CREATE STAFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                top: false,
                bottom: true,
                child: Padding(
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
                  const Text(
                    'Create New Role',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Role Name',
                      hintText: 'e.g. Sales Executive',
                      prefixIcon: const Icon(Icons.work_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (val) => val == null || val.isEmpty
                        ? 'Role name is required'
                        : null,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSubmitting = true);
                              try {
                                final newRole = RoleModel(
                                  id: const Uuid().v4(),
                                  name: nameController.text.trim(),
                                  permissions: {},
                                );
                                final success = await ref
                                    .read(userManagementProvider.notifier)
                                    .addRole(newRole);
                                if (context.mounted && success) {
                                  Navigator.pop(context);
                                  final latestRoles = ref.read(userManagementProvider).roles;
                                  final createdRole = latestRoles.isNotEmpty ? latestRoles.last : newRole;
                                  setState(() {
                                    _selectedRole = createdRole;
                                    _draftPermissions = {};
                                    _hasUnsavedRoleChanges = false;
                                  });
                                  AppFeedback.showSuccess(
                                    context,
                                    'Role created successfully',
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  AppFeedback.showError(context, e);
                                }
                              } finally {
                                if (context.mounted) {
                                  setSheetState(
                                    () => isSubmitting = false,
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'CREATE ROLE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
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
