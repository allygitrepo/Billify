class WhatsappState {
  final bool isLoading;
  final String? qrCode;
  final String? status;
  final int validInSeconds;
  final String? profileImage;
  final String? name;
  final String? phone;
  final String? error;

  WhatsappState({
    this.isLoading = false,
    this.qrCode,
    this.status = 'disconnected',
    this.validInSeconds = 0,
    this.profileImage,
    this.name,
    this.phone,
    this.error,
  });

  WhatsappState copyWith({
    bool? isLoading,
    String? qrCode,
    String? status,
    int? validInSeconds,
    String? profileImage,
    String? name,
    String? phone,
    String? error,
  }) {
    return WhatsappState(
      isLoading: isLoading ?? this.isLoading,
      qrCode: qrCode ?? this.qrCode,
      status: status ?? this.status,
      validInSeconds: validInSeconds ?? this.validInSeconds,
      profileImage: profileImage ?? this.profileImage,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      error: error,
    );
  }
}
