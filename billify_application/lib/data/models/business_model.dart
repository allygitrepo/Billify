class BusinessModel {
  final String id;
  final String name;
  final String? gstin;
  final String phone;
  final String? address;
  final double tax_percentage;
  final double gst_percentage;
  final String? business_logo;
  final String invoice_prefix;
  final int starting_invoice_number;

  BusinessModel({
    required this.id,
    required this.name,
    this.gstin,
    required this.phone,
    this.address,
    required this.tax_percentage,
    required this.gst_percentage,
    this.business_logo,
    this.invoice_prefix = 'INV-',
    this.starting_invoice_number = 1,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    final settingsMap = json['settings'] is Map<String, dynamic>
        ? json['settings'] as Map<String, dynamic>
        : (json['settings'] is Map ? Map<String, dynamic>.from(json['settings']) : null);

    return BusinessModel(
      id: json['id']?.toString() ?? '',
      name: _firstNonEmpty([
            json['name'],
            json['business_name'],
            json['businessName'],
            settingsMap?['business_name'],
            settingsMap?['name'],
          ]) ??
          '',
      gstin: _firstNonEmpty([
        json['gstin'],
        json['gstNumber'],
        json['gst_number'],
        settingsMap?['gst_number'],
        settingsMap?['gstin'],
      ]),
      phone: _firstNonEmpty([
            json['phone'],
            json['business_phone'],
            json['businessPhone'],
            json['phoneNumber'],
            json['phone_number'],
            settingsMap?['business_phone'],
            settingsMap?['phone'],
          ]) ??
          '',
      address: _firstNonEmpty([
        json['address'],
        json['business_address'],
        json['businessAddress'],
        settingsMap?['business_address'],
        settingsMap?['address'],
      ]),
      tax_percentage: _toDouble(json['tax_percentage']) ?? 
                      _toDouble(json['taxPercentage']) ?? 
                      _toDouble(json['tax']) ?? 
                      _toDouble(settingsMap?['tax_percentage']) ?? 0.0,
      gst_percentage: _toDouble(json['gst_percentage']) ?? 
                      _toDouble(json['gstPercentage']) ?? 
                      _toDouble(settingsMap?['gst_percentage']) ?? 0.0,
      business_logo: _firstNonEmpty([
        json['business_logo'],
        json['logoBase64'],
        json['photo'],
        json['businessPhoto'],
        settingsMap?['business_logo'],
        settingsMap?['photo'],
      ]),
      invoice_prefix: _firstNonEmpty([
            json['invoice_prefix'],
            json['invoicePrefix'],
            settingsMap?['invoice_prefix'],
          ]) ??
          'INV-',
      starting_invoice_number: (json['starting_invoice_number'] as num?)?.toInt() ?? 
                               (json['startingNumber'] as num?)?.toInt() ?? 
                               (json['nextInvoiceNumber'] as num?)?.toInt() ?? 
                               (settingsMap?['starting_invoice_number'] as num?)?.toInt() ?? 1,
    );
  }

  static String? _firstNonEmpty(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c != null && c.toString().trim().isNotEmpty) {
        return c.toString().trim();
      }
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'gstin': gstin,
      'phone': phone,
      'address': address,
      'tax_percentage': tax_percentage,
      'gst_percentage': gst_percentage,
      'business_logo': business_logo,
      'invoice_prefix': invoice_prefix,
      'starting_invoice_number': starting_invoice_number,
    };
  }

  BusinessModel copyWith({
    String? id,
    String? name,
    String? gstin,
    String? phone,
    String? address,
    double? tax_percentage,
    double? gst_percentage,
    String? business_logo,
    String? invoice_prefix,
    int? starting_invoice_number,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gstin: gstin ?? this.gstin,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      tax_percentage: tax_percentage ?? this.tax_percentage,
      gst_percentage: gst_percentage ?? this.gst_percentage,
      business_logo: business_logo ?? this.business_logo,
      invoice_prefix: invoice_prefix ?? this.invoice_prefix,
      starting_invoice_number: starting_invoice_number ?? this.starting_invoice_number,
    );
  }
}

