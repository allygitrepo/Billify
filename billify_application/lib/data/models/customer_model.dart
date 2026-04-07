class Customer {
  final int? id;
  final int businessId;
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
      id: json['id'],
      businessId: json['business_id'],
      name: json['name'],
      phoneNumber: json['phone_number'],
      openingBalance: double.parse(json['opening_balance'].toString()),
      remainingBalance: double.parse(json['remaining_balance'].toString()),
      photo: json['photo'],
      city: json['city'],
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
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
