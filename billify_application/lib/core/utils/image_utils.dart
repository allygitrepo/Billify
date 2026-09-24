import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';

/// High-performance Image utility with in-memory byte caching and raster optimization.
class ImageUtils {
  ImageUtils._();

  // In-memory cache for base64 decoded bytes to eliminate redundant decoding CPU spikes
  static final Map<String, Uint8List> _byteCache = {};
  static const int _maxCacheEntries = 150;

  /// Safely decodes a base64 string with in-memory LRU caching and Data URI prefix handling.
  static Uint8List decodeBase64(String base64String) {
    if (base64String.isEmpty) return Uint8List(0);

    // Check fast cache
    if (_byteCache.containsKey(base64String)) {
      return _byteCache[base64String]!;
    }

    try {
      // If it's a data URI, take the part after the comma
      final String payload = base64String.contains(',')
          ? base64String.split(',').last
          : base64String;

      // Remove any whitespace or newlines that might be present
      final String cleanPayload =
          payload.trim().replaceAll(RegExp(r'[\r\n\t ]+'), '');

      final bytes = base64Decode(cleanPayload);

      // Manage cache size
      if (_byteCache.length >= _maxCacheEntries) {
        _byteCache.remove(_byteCache.keys.first);
      }
      _byteCache[base64String] = bytes;

      return bytes;
    } catch (_) {
      // Return empty list on failure to avoid crashing the build method
      return Uint8List(0);
    }
  }

  /// Returns an optimized [ImageProvider] configured with optional raster cache dimensions
  static ImageProvider? providerFromBase64(
    String? base64String, {
    int? cacheWidth,
    int? cacheHeight,
  }) {
    if (base64String == null || base64String.trim().isEmpty) return null;

    final bytes = decodeBase64(base64String);
    if (bytes.isEmpty) return null;

    final memoryImage = MemoryImage(bytes);
    if (cacheWidth != null || cacheHeight != null) {
      return ResizeImage(
        memoryImage,
        width: cacheWidth,
        height: cacheHeight,
        policy: ResizeImagePolicy.exact,
      );
    }
    return memoryImage;
  }

  /// Clears the decoded image byte cache
  static void clearCache() {
    _byteCache.clear();
  }
}

