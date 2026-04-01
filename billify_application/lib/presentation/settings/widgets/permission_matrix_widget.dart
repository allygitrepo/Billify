import 'package:flutter/material.dart';
import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/user_permission.dart';

class PermissionMatrixWidget extends StatefulWidget {
  final Map<PermissionModule, List<PermissionAction>> initialPermissions;
  final ValueChanged<Map<PermissionModule, List<PermissionAction>>> onPermissionsChanged;

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
    _permissions = Map.from(widget.initialPermissions);
  }

  void _togglePermission(PermissionModule module, PermissionAction action) {
    setState(() {
      final modulePermissions = _permissions[module] ?? [];
      if (action == PermissionAction.all) {
        if (modulePermissions.contains(PermissionAction.all)) {
          _permissions[module] = [];
        } else {
          _permissions[module] = [PermissionAction.all];
        }
      } else {
        if (modulePermissions.contains(action)) {
          modulePermissions.remove(action);
          modulePermissions.remove(PermissionAction.all);
        } else {
          modulePermissions.add(action);
          // If all individual actions are selected, we could automatically select 'All'
          // but for simplicity we keep them separate as per typical UI
        }
        _permissions[module] = modulePermissions;
      }
    });
    widget.onPermissionsChanged(_permissions);
  }

  @override
  Widget build(BuildContext context) {
    final actions = PermissionAction.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold, 
          color: Theme.of(context).textTheme.titleSmall?.color
        ),
        columns: [
          const DataColumn(label: Text('Module')),
          ...actions.map((a) => DataColumn(label: Text(a.label))),
        ],
        rows: PermissionModule.values.map((module) {
          final modulePermissions = _permissions[module] ?? [];
          return DataRow(
            cells: [
              DataCell(Text(module.label)),
              ...actions.map((action) {
                final isSelected = modulePermissions.contains(action) || 
                                 (action != PermissionAction.all && modulePermissions.contains(PermissionAction.all));
                return DataCell(
                  Checkbox(
                    value: isSelected,
                    activeColor: AppTheme.primaryTeal,
                    onChanged: (_) => _togglePermission(module, action),
                  ),
                );
              }),
            ],
          );
        }).toList(),
      ),
    );
  }
}
