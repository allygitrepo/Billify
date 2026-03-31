class FeatureSettingsModel {
  final bool isCategoryEnabled;
  final bool isVariantsEnabled;

  FeatureSettingsModel({
    this.isCategoryEnabled = true,
    this.isVariantsEnabled = true,
  });

  FeatureSettingsModel copyWith({
    bool? isCategoryEnabled,
    bool? isVariantsEnabled,
  }) {
    return FeatureSettingsModel(
      isCategoryEnabled: isCategoryEnabled ?? this.isCategoryEnabled,
      isVariantsEnabled: isVariantsEnabled ?? this.isVariantsEnabled,
    );
  }

  factory FeatureSettingsModel.fromJson(Map<String, dynamic> json) {
    return FeatureSettingsModel(
      isCategoryEnabled: json['isCategoryEnabled'] ?? true,
      isVariantsEnabled: json['isVariantsEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCategoryEnabled': isCategoryEnabled,
      'isVariantsEnabled': isVariantsEnabled,
    };
  }
}
