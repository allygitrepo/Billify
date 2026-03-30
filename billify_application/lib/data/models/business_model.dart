class BusinessModel {
  final String id;
  final String name;
  final String? gstNumber;
  final String phone;
  final String? address;
  final double tax;
  final double gst;
  final String? logoBase64;

  BusinessModel({
    required this.id,
    required this.name,
    this.gstNumber,
    required this.phone,
    this.address,
    required this.tax,
    required this.gst,
    this.logoBase64,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gstNumber: json['gstNumber'],
      phone: json['phone'] ?? '',
      address: json['address'],
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      gst: (json['gst'] as num?)?.toDouble() ?? 0.0,
      logoBase64: json['logoBase64'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gstNumber': gstNumber,
      'phone': phone,
      'address': address,
      'tax': tax,
      'gst': gst,
      'logoBase64': logoBase64,
    };
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    String? gstNumber,
    String? phone,
    String? address,
    double? tax,
    double? gst,
    String? logoBase64,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gstNumber: gstNumber ?? this.gstNumber,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      tax: tax ?? this.tax,
      gst: gst ?? this.gst,
      logoBase64: logoBase64 ?? this.logoBase64,
    );
  }
}
