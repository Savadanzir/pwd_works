import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img_lib;

class ImageHashService {
  /// Computes SHA-256 hex string of the image bytes for exact duplicate match.
  static String computeSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Computes 64-bit perceptual difference hash (dHash) as a 16-char hex string.
  /// Robust to slight compression, resizing, and format changes.
  static String? computeDHash(Uint8List bytes) {
    try {
      final img = img_lib.decodeImage(bytes);
      if (img == null) return null;

      // Convert to grayscale and resize to 9 width x 8 height
      final gray = img_lib.grayscale(img);
      final resized = img_lib.copyResize(gray, width: 9, height: 8);

      BigInt hash = BigInt.zero;
      int bitIndex = 0;
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left = resized.getPixel(x, y).luminance;
          final right = resized.getPixel(x + 1, y).luminance;
          if (left > right) {
            hash |= (BigInt.one << bitIndex);
          }
          bitIndex++;
        }
      }
      return hash.toRadixString(16).padLeft(16, '0');
    } catch (_) {
      return null;
    }
  }

  /// Calculates Hamming distance (number of differing bits) between two 64-bit hex dHashes.
  static int hammingDistance(String hash1, String hash2) {
    try {
      final val1 = BigInt.parse(hash1, radix: 16);
      final val2 = BigInt.parse(hash2, radix: 16);
      BigInt xor = val1 ^ val2;
      int count = 0;
      while (xor > BigInt.zero) {
        if ((xor & BigInt.one) == BigInt.one) count++;
        xor = xor >> 1;
      }
      return count;
    } catch (_) {
      return 64;
    }
  }

  /// Returns true if two images are considered duplicates
  /// (either exact byte match or perceptual Hamming distance <= 6 bits out of 64).
  static bool isDuplicate({
    required String? sha1,
    required String? sha2,
    required String? dHash1,
    required String? dHash2,
  }) {
    // 1. Exact SHA-256 byte match
    if (sha1 != null && sha2 != null && sha1.isNotEmpty && sha1 == sha2) {
      return true;
    }
    // 2. Perceptual dHash match (Hamming distance <= 6 bits ≈ 90%+ visual similarity)
    if (dHash1 != null &&
        dHash2 != null &&
        dHash1.isNotEmpty &&
        dHash2.isNotEmpty) {
      final dist = hammingDistance(dHash1, dHash2);
      if (dist <= 6) {
        return true;
      }
    }
    return false;
  }
}
