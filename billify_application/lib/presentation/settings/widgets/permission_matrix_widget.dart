import 'package:flutter/material.dart';
import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/data/models/user_permission.dart';

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

  void _initPermissions() {
    _permissions = {};
    widget.initialPermissions.forEach((module, actions) {
      _permissions[module] = List<PermissionAction>.from(actions);
    });
  }

  void _togglePermission(PermissionModule module, PermissionAction action) {
    setState(() {
      final modulePermissions = _permissions[module] ?? [];
      final updatedList = List<PermissionAction>.from(modulePermissions);

      if (action == PermissionAction.all) {
        if (updatedList.contains(PermissionAction.all)) {
          _permissions[module] = [];
        } else {
          _permissions[module] = [PermissionAction.all];
        }
      } else {
        if (updatedList.contains(action)) {
          updatedList.remove(action);
          updatedList.remove(PermissionAction.all);
        } else {
          updatedList.add(action);
        }
        _permissions[module] = updatedList;
      }
    });
    // Immediately notify parent with the new state for instant in-memory draft tracking
    widget.onPermissionsChanged(_permissions);
  }

  @override
  Widget build(BuildContext context) {
    final actions = PermissionAction.values;
    final modules = [
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

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: DataTable(
            columnSpacing: 24,
            headingRowHeight: 48,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 52,
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Theme.of(context).textTheme.titleSmall?.color,
            ),
            columns: [
              const DataColumn(
                label: Text(
                  'Module',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...actions.map(
                (a) => DataColumn(
                  label: Text(
                    a.label,
                    style: TextStyle(
                      fontWeight: a == PermissionAction.all
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: a == PermissionAction.all
                          ? AppTheme.primaryTeal
                          : null,
                    ),
                  ),
                ),
              ),
            ],
            rows: modules.map((module) {
              final modulePermissions = _permissions[module] ?? [];
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      module.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ...actions.map((action) {
                    final isSelected =
                        modulePermissions.contains(action) ||
                        (action != PermissionAction.all &&
                            modulePermissions.contains(PermissionAction.all));
                    return DataCell(
                      Checkbox(
                        value: isSelected,
                        activeColor: AppTheme.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: (_) => _togglePermission(module, action),
                      ),
                    );
                  }),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
