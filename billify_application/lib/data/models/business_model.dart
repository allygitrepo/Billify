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
    return BusinessModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gstin: json['gstin'] ?? json['gstNumber'],
      phone: json['phone'] ?? '',
      address: json['address'],
      tax_percentage: (json['tax_percentage'] as num?)?.toDouble() ?? (json['tax'] as num?)?.toDouble() ?? 0.0,
      gst_percentage: (json['gst_percentage'] as num?)?.toDouble() ?? (json['gst'] as num?)?.toDouble() ?? 0.0,
      business_logo: json['business_logo'] ?? json['logoBase64'],
      invoice_prefix: (json['invoice_prefix'] as String?) ?? (json['invoicePrefix'] as String?) ?? 'INV-',
      starting_invoice_number: (json['starting_invoice_number'] as num?)?.toInt() ?? (json['nextInvoiceNumber'] as num?)?.toInt() ?? 1,
    );
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

