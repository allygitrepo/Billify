import 'package:billify_application/data/models/business_model.dart';

class BusinessState {
  final List<BusinessModel> businesses;
  final String? currentBusinessId;

  BusinessState({
    this.businesses = const [],
    this.currentBusinessId,
  });

  BusinessModel? get currentBusiness {
    if (currentBusinessId == null) return null;
    return businesses.firstWhere(
      (b) => b.id == currentBusinessId,
      orElse: () => businesses.isNotEmpty ? businesses.first : throw Exception('Business not found'),
    );
  }

  BusinessState copyWith({
    List<BusinessModel>? businesses,
    String? currentBusinessId,
  }) {
    return BusinessState(
      businesses: businesses ?? this.businesses,
      currentBusinessId: currentBusinessId ?? this.currentBusinessId,
    );
  }
}
