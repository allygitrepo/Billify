import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/user_permission.dart';
import 'package:flutter/material.dart';

class PermissionMatrixWidget extends StatefulWidget {
  final Map<PermissionModule, List<PermissionAction>> initialPermissions;
  final ValueChanged<Map<PermissionModule, List<PermissionAction>>>
  onPermissionsChanged;

  const PermissionMatrixWidget({
    super.key,
    required this.initialPermissions,
    required this.onPermissionsChanged,
  });

  @override
  State<PermissionMatrixWidget> createState() => _PermissionMatrixWidgetState();
}

class _PermissionMatrixWidgetState extends State<PermissionMatrixWidget> {
  late Map<PermissionModule, List<PermissionAction>> _permissions;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<PermissionModule> _allModules = [
    PermissionModule.dashboard,
    PermissionModule.products,
    PermissionModule.categories,
    PermissionModule.billing,
    PermissionModule.inventory,
    PermissionModule.businesses,
    PermissionModule.uom,
    PermissionModule.userManagement,
    PermissionModule.customers,
    PermissionModule.payments,
    PermissionModule.analytics,
  ];

  static const List<PermissionAction> _displayActions = [
    PermissionAction.add,
    PermissionAction.view,
    PermissionAction.update,
    PermissionAction.delete,
  ];

  @override
  void initState() {
    super.initState();
    _initPermissions();
  }

  @override
  void didUpdateWidget(covariant PermissionMatrixWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPermissions != oldWidget.initialPermissions) {
      _initPermissions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initPermissions() {
    _permissions = {};
    widget.initialPermissions.forEach((module, actions) {
      _permissions[module] = List<PermissionAction>.from(actions);
    });
  }

  bool _isActionSelected(PermissionModule module, PermissionAction action) {
    final modulePermissions = _permissions[module] ?? [];
    if (action == PermissionAction.all) {
      return _isAllSelected(module);
    }
    return modulePermissions.contains(action) ||
        modulePermissions.contains(PermissionAction.all);
  }

  bool _isAllSelected(PermissionModule module) {
    final modulePermissions = _permissions[module] ?? [];
    if (modulePermissions.contains(PermissionAction.all)) return true;
    return _displayActions.every((a) => modulePermissions.contains(a));
  }

  int _selectedCount(PermissionModule module) {
    if (_isAllSelected(module)) return _displayActions.length;
    final modulePermissions = _permissions[module] ?? [];
    return _displayActions.where((a) => modulePermissions.contains(a)).length;
  }

  void _togglePermission(PermissionModule module, PermissionAction action) {
    setState(() {
      final modulePermissions = _permissions[module] ?? [];
      final updatedList = List<PermissionAction>.from(modulePermissions);

      if (action == PermissionAction.all) {
        if (_isAllSelected(module)) {
          // Deselect all for this module
          _permissions[module] = [];
        } else {
          // Select all actions for this module
          _permissions[module] = [
            ..._displayActions,
            PermissionAction.all,
          ];
        }
      } else {
        final currentlySelected = _isActionSelected(module, action);
        if (currentlySelected) {
          // If "all" was previously granted, expand into individual actions first
          if (updatedList.contains(PermissionAction.all)) {
            updatedList.clear();
            updatedList.addAll(_displayActions);
          }
          updatedList.remove(action);
          updatedList.remove(PermissionAction.all);
        } else {
          updatedList.add(action);
          if (_displayActions.every((a) => updatedList.contains(a))) {
            if (!updatedList.contains(PermissionAction.all)) {
              updatedList.add(PermissionAction.all);
            }
          }
        }
        _permissions[module] = updatedList;
      }
    });

    widget.onPermissionsChanged(_permissions);
  }

  void _toggleAllModules(bool selectAll) {
    setState(() {
      for (final module in _allModules) {
        if (selectAll) {
          _permissions[module] = [
            ..._displayActions,
            PermissionAction.all,
          ];
        } else {
          _permissions[module] = [];
        }
      }
    });
    widget.onPermissionsChanged(_permissions);
  }

  String _getModuleTitle(PermissionModule module) {
    switch (module) {
      case PermissionModule.dashboard:
        return 'Dashboard';
      case PermissionModule.products:
        return 'Products';
      case PermissionModule.categories:
        return 'Categories';
      case PermissionModule.billing:
        return 'Billing (POS)';
      case PermissionModule.inventory:
        return 'Inventory & Stock';
      case PermissionModule.businesses:
        return 'Businesses';
      case PermissionModule.uom:
        return 'Units of Measurement (UOM)';
      case PermissionModule.userManagement:
        return 'Staff & User Management';
      case PermissionModule.customers:
        return 'Customer Management';
      case PermissionModule.payments:
        return 'Khata & Payments';
      case PermissionModule.analytics:
        return 'Analytics & Reports';
      default:
        return module.label;
    }
  }

  IconData _getModuleIcon(PermissionModule module) {
    switch (module) {
      case PermissionModule.dashboard:
        return Icons.dashboard_outlined;
      case PermissionModule.products:
        return Icons.inventory_2_outlined;
      case PermissionModule.categories:
        return Icons.category_outlined;
      case PermissionModule.billing:
        return Icons.receipt_long_outlined;
      case PermissionModule.inventory:
        return Icons.warehouse_outlined;
      case PermissionModule.businesses:
        return Icons.business_outlined;
      case PermissionModule.uom:
        return Icons.straighten_outlined;
      case PermissionModule.userManagement:
        return Icons.people_outline;
      case PermissionModule.customers:
        return Icons.person_outline;
      case PermissionModule.payments:
        return Icons.account_balance_wallet_outlined;
      case PermissionModule.analytics:
      case PermissionModule.reports:
        return Icons.insights_outlined;
      case PermissionModule.transactionLogs:
        return Icons.history_outlined;
      case PermissionModule.systemSettings:
        return Icons.settings_outlined;
    }
  }

  String _getActionLabel(PermissionAction action) {
    switch (action) {
      case PermissionAction.add:
        return 'Create';
      case PermissionAction.view:
        return 'View';
      case PermissionAction.update:
        return 'Update';
      case PermissionAction.delete:
        return 'Delete';
      default:
        return action.label;
    }
  }

  IconData _getActionIcon(PermissionAction action) {
    switch (action) {
      case PermissionAction.add:
        return Icons.add_circle_outline;
      case PermissionAction.view:
        return Icons.visibility_outlined;
      case PermissionAction.update:
        return Icons.edit_outlined;
      case PermissionAction.delete:
        return Icons.delete_outline;
      default:
        return Icons.done_all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredModules = _allModules.where((module) {
      if (_searchQuery.isEmpty) return true;
      final title = _getModuleTitle(module).toLowerCase();
      final label = module.label.toLowerCase();
      return title.contains(_searchQuery) || label.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        // Search & Quick Bulk Action Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search modules...',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Bulk Actions',
                icon: Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.tune,
                    color: AppTheme.primaryTeal,
                    size: 20,
                  ),
                ),
                onSelected: (val) {
                  if (val == 'select_all') {
                    _toggleAllModules(true);
                  } else if (val == 'clear_all') {
                    _toggleAllModules(false);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'select_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.done_all,
                          color: AppTheme.primaryTeal,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text('Grant All Permissions'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, color: Colors.redAccent, size: 18),
                        SizedBox(width: 10),
                        Text('Clear All Permissions'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Modules List
        Expanded(
          child: filteredModules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: isDark
                            ? Colors.grey.shade700
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No matching modules found',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  itemCount: filteredModules.length,
                  itemBuilder: (context, index) {
                    final module = filteredModules[index];
                    return _buildModuleCard(context, module, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    PermissionModule module,
    bool isDark,
  ) {
    final title = _getModuleTitle(module);
    final icon = _getModuleIcon(module);
    final isAllSelected = _isAllSelected(module);
    final count = _selectedCount(module);
    final total = _displayActions.length;

    final String countLabel;
    final Color countColor;
    if (isAllSelected) {
      countLabel = 'All permissions granted';
      countColor = AppTheme.primaryTeal;
    } else if (count == 0) {
      countLabel = 'No permissions active';
      countColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    } else {
      countLabel = '$count of $total permissions active';
      countColor = isDark ? AppTheme.secondaryAqua : AppTheme.secondaryTeal;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        countLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: countColor,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _togglePermission(module, PermissionAction.all),
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isAllSelected
                          ? AppTheme.primaryTeal
                          : AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAllSelected
                            ? AppTheme.primaryTeal
                            : AppTheme.primaryTeal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAllSelected ? Icons.check : Icons.done_all,
                          size: 13,
                          color: isAllSelected
                              ? Colors.white
                              : AppTheme.primaryTeal,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAllSelected ? 'All Granted' : 'Select All',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAllSelected
                                ? Colors.white
                                : AppTheme.primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),

            // Action Chips Wrap
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _displayActions.map((action) {
                final isSelected = _isActionSelected(module, action);
                final actionIcon = _getActionIcon(action);

                return InkWell(
                  onTap: () => _togglePermission(module, action),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryTeal.withValues(alpha: 0.12)
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.grey.shade300),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : actionIcon,
                          size: 15,
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getActionLabel(action),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? (isDark
                                    ? AppTheme.primaryTeal
                                    : const Color(0xFF00796B))
                                : (isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
