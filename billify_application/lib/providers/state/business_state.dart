import 'package:billify_application/data/models/business_model.dart';

class BusinessState {
  final List<BusinessModel> businesses;
  final String? currentBusinessId;

  BusinessState({
    this.businesses = const [],
    this.currentBusinessId,
  });

  BusinessModel? get currentBusiness {
    if (currentBusinessId == null || businesses.isEmpty) return null;
    return businesses.firstWhere(
      (b) => b.id == currentBusinessId,
      orElse: () => businesses.first,
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
