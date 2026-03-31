class UomModel {
  final String id;
  final String name;

  UomModel({
    required this.id,
    required this.name,
  });

  factory UomModel.fromJson(Map<String, dynamic> json) {
    return UomModel(
      id: json['id'],
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  UomModel copyWith({
    String? id,
    String? name,
  }) {
    return UomModel(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }
}
