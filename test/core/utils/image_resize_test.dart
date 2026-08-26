import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:sakani/core/utils/image_resize.dart';

void main() {
  group('compressImageBytes', () {
    test('downscales an oversized image to the max dimension', () async {
      final original = img.Image(width: 3000, height: 2000);
      img.fill(original, color: img.ColorRgb8(200, 30, 30));
      final originalBytes = img.encodeJpg(original);

      final compressed = await compressImageBytes(
        originalBytes,
        maxDimension: 1600,
      );

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, lessThanOrEqualTo(1600));
      expect(decoded.height, lessThanOrEqualTo(1600));
      // النسبة يجب أن تبقى محفوظة (3:2 أصلاً).
      expect(decoded.width, 1600);
      expect(decoded.height, closeTo(1067, 1));
    });

    test('leaves an already-small image at its own dimensions', () async {
      final original = img.Image(width: 400, height: 300);
      img.fill(original, color: img.ColorRgb8(30, 120, 200));
      final originalBytes = img.encodeJpg(original);

      final compressed = await compressImageBytes(
        originalBytes,
        maxDimension: 1600,
      );

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, 400);
      expect(decoded.height, 300);
    });

    test('returns the original bytes unchanged when decoding fails', () async {
      final garbage = Uint8List.fromList(List.generate(16, (i) => i));

      final result = await compressImageBytes(garbage);

      expect(result, garbage);
    });
  });
}
