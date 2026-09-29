import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:billify/core/services/ad_service.dart';
import 'package:billify/core/utils/app_logger.dart';

/// Reusable Google AdMob Banner Ad Widget.
/// Loads asynchronously, handles errors gracefully, and cleans up resources on dispose.
class AppBannerAd extends StatefulWidget {
  final AdSize adSize;
  final EdgeInsetsGeometry? margin;
  final bool showBorder;

  const AppBannerAd({
    super.key,
    this.adSize = AdSize.banner,
    this.margin,
    this.showBorder = false,
  });

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _bannerAd;
  Timer? _retryTimer;
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (kIsWeb || !Platform.isAndroid) {
      return;
    }

    final adUnitId = AdService.bannerAdUnitId;
    if (adUnitId.isEmpty) return;

    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _isLoaded = true;
            _hasError = false;
          });
          AppLogger.debug('Banner Ad loaded successfully', tag: 'AppBannerAd');
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.warning(
            'Banner Ad failed to load: ${error.message} (code: ${error.code})',
            tag: 'AppBannerAd',
          );
          ad.dispose();
          _bannerAd = null;
          if (mounted) {
            setState(() {
              _isLoaded = false;
              _hasError = true;
            });
            // Schedule auto-retry after 20 seconds
            _retryTimer?.cancel();
            _retryTimer = Timer(const Duration(seconds: 20), () {
              if (mounted && !_isLoaded) {
                _loadBanner();
              }
            });
          }
        },
      ),
    );

    _bannerAd?.load();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !Platform.isAndroid) {
      return const SizedBox.shrink();
    }

    if (_hasError || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      decoration: widget.showBorder
          ? BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
              ),
            )
          : null,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
