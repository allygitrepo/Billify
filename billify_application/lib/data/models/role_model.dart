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

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    final Map<PermissionModule, List<PermissionAction>> permissionsMap = {};
    if (json['permissions'] != null) {
      json['permissions'].forEach((key, value) {
        final module = PermissionModule.values.firstWhere((e) => e.name == key);
        final actions = (value as List).map((e) => PermissionAction.values.firstWhere((a) => a.name == e)).toList();
        permissionsMap[module] = actions;
      });
    }
    return RoleModel(
      id: json['id'],
      name: json['name'],
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
