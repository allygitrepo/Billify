class UserModel {
  final String? id;
  final String name;
  final String? email;
  final String mobile;
  final String? password; // Nullable if not being sent
  final String? roleId;
  final String? photo;
  final String? businessOwnerId;
  final bool status;

  UserModel({
    this.id,
    required this.name,
    this.email,
    required this.mobile,
    this.password,
    this.roleId,
    this.photo,
    this.businessOwnerId,
    this.status = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      password: null, // Password never returned by server
      roleId: (json['role_id'] ?? json['roleId'])?.toString(),
      photo: json['photo']?.toString(),
      businessOwnerId: (json['business_owner_id'] ?? json['businessOwnerId'])?.toString(),
      status: json['status'] == true || json['status'] == 'active' || json['status'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      if (password != null) 'password': password,
      'role_id': roleId != null ? int.tryParse(roleId!) : null,
      'photo': photo,
      'status': status,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? mobile,
    String? password,
    String? roleId,
    String? photo,
    String? businessOwnerId,
    bool? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
      photo: photo ?? this.photo,
      businessOwnerId: businessOwnerId ?? this.businessOwnerId,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && mobile == other.mobile;

  @override
  int get hashCode => mobile.hashCode;
}
