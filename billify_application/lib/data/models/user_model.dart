class UserModel {
  final String name;
  final String email;
  final String mobile;
  final String password;
  final String? roleId;
  final String? photo;
  final String? businessOwnerId;
  final bool status;

  UserModel({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    this.roleId,
    this.photo,
    this.businessOwnerId,
    this.status = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name'] ?? json['fullName'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? json['phone'] ?? '',
      password: json['password'] ?? '',
      roleId: json['roleId'],
      photo: json['photo'] ?? json['profileImage'],
      businessOwnerId: json['businessOwnerId'],
      status: json['status'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'password': password,
      'roleId': roleId,
      'photo': photo,
      'businessOwnerId': businessOwnerId,
      'status': status,
    };
  }

  UserModel copyWith({
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
      other is UserModel && runtimeType == other.runtimeType && email == other.email;

  @override
  int get hashCode => email.hashCode;
}

