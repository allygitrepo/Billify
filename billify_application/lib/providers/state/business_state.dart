import 'package:billify/data/models/business_model.dart';

class BusinessState {
  final List<BusinessModel> businesses;
  final String? currentBusinessId;
  final String? error;
  final dynamic errorObject;

  BusinessState({
    this.businesses = const [],
    this.currentBusinessId,
    this.error,
    this.errorObject,
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
    String? error,
    dynamic errorObject,
  }) {
    return BusinessState(
      businesses: businesses ?? this.businesses,
      currentBusinessId: currentBusinessId ?? this.currentBusinessId,
      error: error,
      errorObject: errorObject ?? this.errorObject,
    );
  }
}
