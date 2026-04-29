class RegistrationModel {
  final String name;
  final String email;
  final String password;
  final String? phone;
  final String? userPhoto;
  
  final String businessName;
  final String? businessPhone;
  final String? gstin;
  final String? address;
  final String? businessPhoto;
  
  final double? taxPercentage;
  final double? gstPercentage;
  final String? currency;
  final String? invoicePrefix;
  final int? startingNumber;
  final String? invoiceFormat;
  final String? footerNote;
  final String? otp;

  RegistrationModel({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
    this.userPhoto,
    required this.businessName,
    this.businessPhone,
    this.gstin,
    this.address,
    this.businessPhoto,
    this.taxPercentage,
    this.gstPercentage,
    this.currency,
    this.invoicePrefix,
    this.startingNumber,
    this.invoiceFormat,
    this.footerNote,
    this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'userMobile': phone,
      'userPhoto': userPhoto,
      'business_name': businessName,
      'phone': businessPhone,
      'gstin': gstin,
      'address': address,
      'businessPhoto': businessPhoto,
      'taxPercentage': taxPercentage,
      'gstPercentage': gstPercentage,
      'currency': currency,
      'invoicePrefix': invoicePrefix,
      'startingNumber': startingNumber,
      'invoiceFormat': invoiceFormat,
      'footerNote': footerNote,
      'otp': otp,
    };
  }

  RegistrationModel copyWith({
    String? name,
    String? email,
    String? password,
    String? phone,
    String? userPhoto,
    String? businessName,
    String? businessPhone,
    String? gstin,
    String? address,
    String? businessPhoto,
    double? taxPercentage,
    double? gstPercentage,
    String? currency,
    String? invoicePrefix,
    int? startingNumber,
    String? invoiceFormat,
    String? footerNote,
    String? otp,
  }) {
    return RegistrationModel(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      userPhoto: userPhoto ?? this.userPhoto,
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      gstin: gstin ?? this.gstin,
      address: address ?? this.address,
      businessPhoto: businessPhoto ?? this.businessPhoto,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      gstPercentage: gstPercentage ?? this.gstPercentage,
      currency: currency ?? this.currency,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      startingNumber: startingNumber ?? this.startingNumber,
      invoiceFormat: invoiceFormat ?? this.invoiceFormat,
      footerNote: footerNote ?? this.footerNote,
      otp: otp ?? this.otp,
    );
  }
}
