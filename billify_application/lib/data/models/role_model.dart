import 'user_permission.dart';

class RoleModel {
  final String id;
  final String name;
  final Map<PermissionModule, List<PermissionAction>> permissions;

  RoleModel({
    required this.id,
    required this.name,
    required this.permissions,
  });

  static Map<PermissionModule, List<PermissionAction>> parsePermissions(
      Map<String, dynamic> rawPermissions) {
    final Map<PermissionModule, List<PermissionAction>> permissionsMap = {};
    rawPermissions.forEach((key, value) {
      try {
        final module = PermissionModule.fromString(key);
        if (module == null) return;

        if (value is List) {
          final List<PermissionAction> actions = [];
          for (var item in value) {
            final action = PermissionAction.fromString(item.toString());
            if (action != null && !actions.contains(action)) {
              actions.add(action);
            }
          }
          permissionsMap[module] = actions;
        } else if (value is Map) {
          final List<PermissionAction> actions = [];
          if (value['can_view'] == true || value['view'] == true) {
            actions.add(PermissionAction.view);
          }
          if (value['can_add'] == true || value['add'] == true) {
            actions.add(PermissionAction.add);
          }
          if (value['can_update'] == true || value['update'] == true) {
            actions.add(PermissionAction.update);
          }
          if (value['can_delete'] == true || value['delete'] == true) {
            actions.add(PermissionAction.delete);
          }
          if (value['can_export'] == true || value['export'] == true) {
            actions.add(PermissionAction.export);
          }
          if (value['can_bulk_upload'] == true ||
              value['bulk_upload'] == true ||
              value['import'] == true) {
            actions.add(PermissionAction.bulkUpload);
          }
          if (value['can_download'] == true || value['download'] == true) {
            actions.add(PermissionAction.download);
          }
          if (value['can_print'] == true || value['print'] == true) {
            actions.add(PermissionAction.print);
          }
          if (value['all'] == true || value['can_all'] == true) {
            actions.add(PermissionAction.all);
          }
          permissionsMap[module] = actions;
        }
      } catch (_) {}
    });
    return permissionsMap;
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawPermissions = json['permissions'];
    Map<PermissionModule, List<PermissionAction>> permissionsMap = {};

    if (rawPermissions is Map<String, dynamic>) {
      permissionsMap = parsePermissions(rawPermissions);
    } else if (rawPermissions is List) {
      final Map<String, dynamic> convertedMap = {};
      for (var item in rawPermissions) {
        if (item is Map<String, dynamic>) {
          final modName = item['module_name'] ?? item['module'] ?? item['name'];
          if (modName != null) {
            convertedMap[modName.toString()] = item;
          }
        }
      }
      permissionsMap = parsePermissions(convertedMap);
    }

    return RoleModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      permissions: permissionsMap,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, List<String>> pMap = {};
    permissions.forEach((key, value) {
      pMap[key.name] = value.map((e) => e.name).toList();
    });
    return {
      'id': id,
      'name': name,
      'permissions': pMap,
    };
  }

  /// Converts the permissions map into the backend's explicit flag format array
  List<Map<String, dynamic>> toBackendPermissions() {
    final List<Map<String, dynamic>> backendList = [];
    
    for (var module in PermissionModule.values) {
      final actions = permissions[module] ?? [];
      final hasAll = actions.contains(PermissionAction.all);
      
      backendList.add({
        'module_name': module.name,
        'can_add': hasAll || actions.contains(PermissionAction.add),
        'can_view': hasAll || actions.contains(PermissionAction.view),
        'can_update': hasAll || actions.contains(PermissionAction.update),
        'can_delete': hasAll || actions.contains(PermissionAction.delete),
        'can_export': hasAll || actions.contains(PermissionAction.export),
        'can_bulk_upload': hasAll || actions.contains(PermissionAction.bulkUpload),
        'can_download': hasAll || actions.contains(PermissionAction.download),
        'can_print': hasAll || actions.contains(PermissionAction.print),
      });
    }
    
    return backendList;
  }

  bool hasPermission(PermissionModule module, PermissionAction action) {
    if (permissions[module]?.contains(PermissionAction.all) ?? false) return true;
    return permissions[module]?.contains(action) ?? false;
  }

  RoleModel copyWith({
    String? id,
    String? name,
    Map<PermissionModule, List<PermissionAction>>? permissions,
  }) {
    return RoleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoleModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
