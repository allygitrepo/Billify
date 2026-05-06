class Customer {
  final int? id;
  final String businessId;
  final String name;
  final String phoneNumber;
  final double openingBalance;
  final double remainingBalance;
  final String? photo;
  final String? city;
  final String status;
  final DateTime? createdAt;

  Customer({
    this.id,
    required this.businessId,
    required this.name,
    required this.phoneNumber,
    this.openingBalance = 0.0,
    this.remainingBalance = 0.0,
    this.photo,
    this.city,
    this.status = 'active',
    this.createdAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      businessId: json['business_id']?.toString() ?? json['businessId']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '') ?? 0.0,
      remainingBalance: double.tryParse(json['remaining_balance']?.toString() ?? '') ?? 0.0,
      photo: json['photo'],
      city: json['city'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone_number': phoneNumber,
      'opening_balance': openingBalance,
      'remaining_balance': remainingBalance,
      'photo': photo,
      'city': city,
      'status': status,
    };
  }
}
