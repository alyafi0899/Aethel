import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';

const int maxUploadedImageDimension = 1600;

String resolveImageCropSourcePath({
  required String? filePath,
  required Uri fileUri,
}) {
  if (filePath != null && filePath.isNotEmpty) return filePath;
  if (kIsWeb && (fileUri.scheme == 'blob' || fileUri.scheme == 'data')) {
    return fileUri.toString();
  }
  throw StateError('Berkas gambar tidak dapat dibuka untuk dipangkas.');
}

Uint8List resizeImageToMaxDimension(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('Gambar hasil crop tidak dapat diproses.');
  }

  final resized = decoded.width <= maxUploadedImageDimension &&
          decoded.height <= maxUploadedImageDimension
      ? decoded
      : img.copyResize(
          decoded,
          width: decoded.width >= decoded.height
              ? maxUploadedImageDimension
              : null,
          height:
              decoded.height > decoded.width ? maxUploadedImageDimension : null,
        );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
}

Future<Uint8List?> cropAndResizeImage({
  required BuildContext context,
  required String sourcePath,
  required double ratioX,
  required double ratioY,
  required String title,
}) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: sourcePath,
    maxWidth: maxUploadedImageDimension,
    maxHeight: maxUploadedImageDimension,
    aspectRatio: CropAspectRatio(ratioX: ratioX, ratioY: ratioY),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 85,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: title,
        lockAspectRatio: true,
        showCropGrid: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: title,
        doneButtonTitle: 'Gunakan',
        cancelButtonTitle: 'Batal',
        aspectRatioLockEnabled: true,
        aspectRatioPickerButtonHidden: true,
        resetAspectRatioEnabled: false,
      ),
      WebUiSettings(
        context: context,
        size: const CropperSize(width: 720, height: 560),
        viewwMode: WebViewMode.mode_1,
        translations: WebTranslations(
          title: title,
          rotateLeftTooltip: 'Putar 90 derajat ke kiri',
          rotateRightTooltip: 'Putar 90 derajat ke kanan',
          cancelButton: 'Batal',
          cropButton: 'Gunakan',
        ),
      ),
    ],
  );

  if (cropped == null) return null;
  return compute(resizeImageToMaxDimension, await cropped.readAsBytes());
}
