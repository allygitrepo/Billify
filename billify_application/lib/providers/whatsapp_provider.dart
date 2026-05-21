import 'dart:async';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/providers/business_provider.dart';
import 'package:billify/providers/state/whatsapp_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final whatsappProvider = NotifierProvider<WhatsappNotifier, WhatsappState>(() {
  return WhatsappNotifier();
});

class WhatsappNotifier extends Notifier<WhatsappState> {
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  @override
  WhatsappState build() {
    ref.onDispose(() {
      _stopTimers();
    });

    // Auto-check status when active business changes
    ref.listen(businessProvider, (previous, next) {
      if (next.currentBusinessId != previous?.currentBusinessId) {
        checkStatus();
      }
    });

    // Check status initially
    Future.delayed(Duration.zero, () => checkStatus());

    return WhatsappState();
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _countdownTimer = null;
    _pollingTimer = null;
  }

  Future<void> checkStatus() async {
    final businessId = ref.read(businessProvider).currentBusinessId;
    if (businessId == null) {
      state = WhatsappState();
      return;
    }

    try {
      state = state.copyWith(isLoading: true);
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/businesses/$businessId/whatsapp/status');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true) {
          final status = data['status']?.toString() ?? 'disconnected';
          state = state.copyWith(
            isLoading: false,
            status: status,
            qrCode: data['qr']?.toString(),
            phone: data['phone']?.toString(),
            name: data['name']?.toString(),
            profileImage: data['profileImage']?.toString(),
            error: null,
          );
        } else {
          state = WhatsappState(isLoading: false);
        }
      } else {
        state = WhatsappState(isLoading: false, error: 'Failed to fetch status');
      }
    } catch (e) {
      state = WhatsappState(isLoading: false, error: e.toString());
    }
  }

  Future<void> startLinking() async {
    final businessId = ref.read(businessProvider).currentBusinessId;
    if (businessId == null) return;

    _stopTimers();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.post('/businesses/$businessId/whatsapp/initiate');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('[WhatsApp Provider] initiate response: $data');
        if (data['success'] == true) {
          final status = data['status']?.toString() ?? 'disconnected';
          final qr = data['qr']?.toString();
          final validSec = (data['validinsecond'] as num?)?.toInt() ?? 40;
          print('[WhatsApp Provider] parsed validSec: $validSec');

          state = state.copyWith(
            isLoading: false,
            status: status,
            qrCode: qr,
            validInSeconds: validSec,
            phone: data['phone']?.toString(),
            name: data['name']?.toString(),
            profileImage: data['profileImage']?.toString(),
            error: null,
          );

          if (status == 'connected') {
            await ref.read(businessProvider.notifier).sync();
            return;
          }

          // Start timers if not already connected
          _startCountdown(businessId);
          _startPolling(businessId);
        } else {
          state = state.copyWith(isLoading: false, error: 'Initialization failed');
        }
      } else {
        state = state.copyWith(isLoading: false, error: 'HTTP error during initiation');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _startCountdown(String businessId) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (state.validInSeconds > 0) {
        state = state.copyWith(validInSeconds: state.validInSeconds - 1);
      } else {
        // Expired! Fetch a new QR code
        _stopTimers();
        await startLinking();
      }
    });
  }

  void _startPolling(String businessId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.get('/businesses/$businessId/whatsapp/status');
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data['success'] == true) {
            final status = data['status']?.toString() ?? 'disconnected';
            
            if (status == 'connected') {
              _stopTimers();
              state = state.copyWith(
                status: 'connected',
                qrCode: null,
                phone: data['phone']?.toString(),
                name: data['name']?.toString(),
                profileImage: data['profileImage']?.toString(),
                error: null,
              );
              // Sync the local business details to update UI elsewhere
              await ref.read(businessProvider.notifier).sync();
            }
          }
        }
      } catch (e) {
        // Silently catch polling issues
      }
    });
  }

  Future<void> disconnect() async {
    final businessId = ref.read(businessProvider).currentBusinessId;
    if (businessId == null) return;

    _stopTimers();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.delete('/businesses/$businessId/whatsapp/delete');
      
      if (response.statusCode == 200) {
        state = WhatsappState();
        await ref.read(businessProvider.notifier).sync();
      } else {
        state = state.copyWith(isLoading: false, error: 'Disconnection failed');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void cancelLinkingFlow() {
    _stopTimers();
    // Return to status check
    checkStatus();
  }
}
