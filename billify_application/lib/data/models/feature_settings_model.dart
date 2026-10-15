class FeatureSettingsModel {
  final bool isCategoryEnabled;
  final bool isVariantsEnabled;
  final String invoicePrintFormat; // 'thermal' or 'a4'

  FeatureSettingsModel({
    this.isCategoryEnabled = true,
    this.isVariantsEnabled = true,
    this.invoicePrintFormat = 'thermal',
  });

  FeatureSettingsModel copyWith({
    bool? isCategoryEnabled,
    bool? isVariantsEnabled,
    String? invoicePrintFormat,
  }) {
    return FeatureSettingsModel(
      isCategoryEnabled: isCategoryEnabled ?? this.isCategoryEnabled,
      isVariantsEnabled: isVariantsEnabled ?? this.isVariantsEnabled,
      invoicePrintFormat: invoicePrintFormat ?? this.invoicePrintFormat,
    );
  }

  factory FeatureSettingsModel.fromJson(Map<String, dynamic> json) {
    return FeatureSettingsModel(
      isCategoryEnabled: json['isCategoryEnabled'] ?? true,
      isVariantsEnabled: json['isVariantsEnabled'] ?? true,
      invoicePrintFormat: json['invoicePrintFormat'] as String? ?? 'thermal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCategoryEnabled': isCategoryEnabled,
      'isVariantsEnabled': isVariantsEnabled,
      'invoicePrintFormat': invoicePrintFormat,
    };
  }
}
