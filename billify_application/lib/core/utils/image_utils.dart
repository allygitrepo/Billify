import 'dart:convert';
import 'dart:typed_data';

class ImageUtils {
  /// Safely decodes a base64 string, handling Data URI prefixes if present.
  static Uint8List decodeBase64(String base64String) {
    try {
      // If it's a data URI, take the part after the comma
      final String payload = base64String.contains(',') 
          ? base64String.split(',').last 
          : base64String;
      
      // Remove any whitespace or newlines that might be present
      final String cleanPayload = payload.trim().replaceAll(RegExp(r'[\r\n\t ]+'), '');
      
      return base64Decode(cleanPayload);
    } catch (e) {
      // Return empty list on failure to avoid crashing the build method
      return Uint8List(0);
    }
  }
}
