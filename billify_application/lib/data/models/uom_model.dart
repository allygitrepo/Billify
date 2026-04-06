class UomModel {
  final String id;
  final String name;
  final String shortCode;

  UomModel({
    required this.id,
    required this.name,
    required this.shortCode,
  });

  factory UomModel.fromJson(Map<String, dynamic> json) {
    return UomModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      shortCode: json['shortCode'] ?? json['short_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'shortCode': shortCode,
    };
  }

  UomModel copyWith({
    String? id,
    String? name,
    String? shortCode,
  }) {
    return UomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      shortCode: shortCode ?? this.shortCode,
    );
  }
}
