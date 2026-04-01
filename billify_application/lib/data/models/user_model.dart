class UserModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String? roleId;
  final String? profileImage;
  final String? businessOwnerId;
  final bool isActive;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    this.roleId,
    this.profileImage,
    this.businessOwnerId,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      roleId: json['roleId'],
      profileImage: json['profileImage'],
      businessOwnerId: json['businessOwnerId'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'roleId': roleId,
      'profileImage': profileImage,
      'businessOwnerId': businessOwnerId,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? roleId,
    String? profileImage,
    String? businessOwnerId,
    bool? isActive,
  }) {
    return UserModel(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
      profileImage: profileImage ?? this.profileImage,
      businessOwnerId: businessOwnerId ?? this.businessOwnerId,
      isActive: isActive ?? this.isActive,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && email == other.email;

  @override
  int get hashCode => email.hashCode;
}
