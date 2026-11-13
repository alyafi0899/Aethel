import 'dart:typed_data';

import 'package:clinic_operations_platform/core/utils/image_crop_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('resizes landscape and portrait images to a maximum side of 1600 px',
      () {
    final landscape = Uint8List.fromList(
      img.encodePng(img.Image(width: 2400, height: 1200)),
    );
    final portrait = Uint8List.fromList(
      img.encodePng(img.Image(width: 1200, height: 2400)),
    );

    final resizedLandscape =
        img.decodeImage(resizeImageToMaxDimension(landscape))!;
    final resizedPortrait =
        img.decodeImage(resizeImageToMaxDimension(portrait))!;

    expect(resizedLandscape.width, 1600);
    expect(resizedLandscape.height, 800);
    expect(resizedPortrait.width, 800);
    expect(resizedPortrait.height, 1600);
  });
}
