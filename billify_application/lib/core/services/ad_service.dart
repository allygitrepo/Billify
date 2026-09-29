import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:billify/core/utils/app_logger.dart';

/// Centralized service managing Google AdMob lifecycle, ad unit IDs,
/// banner loading, interstitial preloading, and smart frequency capping.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Interstitial Ad Management
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  DateTime? _lastInterstitialShownAt;

  /// Cooldown between full-screen interstitial ads (in seconds) to protect UX
  int interstitialCooldownSeconds = 45;

  // ==================== Ad Unit Identifiers ====================
  // Official Google AdMob Test Ad Units for Android and iOS
  static const String _testAndroidBanner =
      'ca-app-pub-7112895949117873/6359712520';
  static const String _testIosBanner = 'ca-app-pub-3940256099942544/2934735716';

  static const String _testAndroidInterstitial =
      'ca-app-pub-7112895949117873/5321963020';
  static const String _testIosInterstitial =
      'ca-app-pub-3940256099942544/4411468910';

  // Optional custom production IDs (replace with your AdMob IDs in release)
  static String? customAndroidBannerId;
  static String? customAndroidInterstitialId;

  // List of registered test devices to ensure 100% ad fill during development/testing
  static List<String> testDeviceIds = [
    '379DE2F07211B28B75751DED8D654F7A', // User device ID from AdMob log
  ];

  /// Returns the appropriate Banner Ad Unit ID (Android only)
  static String get bannerAdUnitId {
    if (kIsWeb || !Platform.isAndroid) return '';
    return kReleaseMode && customAndroidBannerId != null
        ? customAndroidBannerId!
        : _testAndroidBanner;
  }

  /// Returns the appropriate Interstitial Ad Unit ID (Android only)
  static String get interstitialAdUnitId {
    if (kIsWeb || !Platform.isAndroid) return '';
    return kReleaseMode && customAndroidInterstitialId != null
        ? customAndroidInterstitialId!
        : _testAndroidInterstitial;
  }

  // ==================== Initialization ====================

  /// Initializes the Google Mobile Ads SDK asynchronously (Android only)
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb || !Platform.isAndroid) {
      AppLogger.info(
        'AdMob disabled: active only for Android users',
        tag: 'AdService',
      );
      return;
    }

    try {
      // Register test devices for development fill
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: testDeviceIds,
        ),
      );

      final status = await MobileAds.instance.initialize();
      _isInitialized = true;
      AppLogger.info(
        'Google Mobile Ads SDK initialized successfully on Android (${status.adapterStatuses.length} adapters)',
        tag: 'AdService',
      );

      // Preload the first interstitial ad in background
      loadInterstitialAd();
    } catch (e, stack) {
      AppLogger.error(
        'Failed to initialize Google Mobile Ads',
        error: e,
        stackTrace: stack,
        tag: 'AdService',
      );
    }
  }

  // ==================== Interstitial Ads ====================

  /// Preloads an Interstitial Ad in memory for instant display (Android only)
  void loadInterstitialAd() {
    if (kIsWeb || !Platform.isAndroid) return;
    if (_interstitialAd != null || _isInterstitialLoading) return;

    final adUnitId = interstitialAdUnitId;
    if (adUnitId.isEmpty) return;

    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          AppLogger.debug(
            'Interstitial Ad preloaded and ready',
            tag: 'AdService',
          );

          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _interstitialAd = null;
                  // Preload next interstitial ad
                  loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  AppLogger.warning(
                    'Failed to show interstitial: ${error.message}',
                    tag: 'AdService',
                  );
                  ad.dispose();
                  _interstitialAd = null;
                  loadInterstitialAd();
                },
              );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
          AppLogger.warning(
            'Failed to load Interstitial Ad: ${error.message} (code: ${error.code})',
            tag: 'AdService',
          );
          // Retry preloading after 30 seconds if failed
          Future.delayed(const Duration(seconds: 30), () {
            if (_interstitialAd == null && !_isInterstitialLoading) {
              loadInterstitialAd();
            }
          });
        },
      ),
    );
  }

  /// Shows the preloaded interstitial ad if available and not on cooldown.
  /// [onDismissed] callback is always guaranteed to execute regardless of whether the ad was shown.
  Future<void> showInterstitialAd({
    VoidCallback? onDismissed,
    String? placement,
    bool bypassCooldown = false,
  }) async {
    void proceed() {
      if (onDismissed != null) {
        onDismissed();
      }
    }

    if (kIsWeb || !Platform.isAndroid) {
      proceed();
      return;
    }

    // Frequency Capping / Cooldown Check
    if (!bypassCooldown && _lastInterstitialShownAt != null) {
      final secondsSinceLastAd = DateTime.now()
          .difference(_lastInterstitialShownAt!)
          .inSeconds;
      if (secondsSinceLastAd < interstitialCooldownSeconds) {
        AppLogger.debug(
          'Skipping interstitial (cooldown active: ${interstitialCooldownSeconds - secondsSinceLastAd}s remaining)',
          tag: 'AdService',
        );
        proceed();
        return;
      }
    }

    if (_interstitialAd == null) {
      AppLogger.debug(
        'No interstitial preloaded. Triggering background load.',
        tag: 'AdService',
      );
      loadInterstitialAd();
      proceed();
      return;
    }

    // Set callback specifically for this display instance
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastInterstitialShownAt = DateTime.now();
        AppLogger.info(
          'Interstitial Ad shown for placement: ${placement ?? "general"}',
          tag: 'AdService',
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        proceed();
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AppLogger.warning(
          'Failed to present interstitial ad: ${error.message}',
          tag: 'AdService',
        );
        ad.dispose();
        _interstitialAd = null;
        proceed();
        loadInterstitialAd();
      },
    );

    try {
      await _interstitialAd!.show();
    } catch (e) {
      AppLogger.warning(
        'Error during interstitial display: $e',
        tag: 'AdService',
      );
      proceed();
    }
  }

  /// Clean up all held ad resources
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
