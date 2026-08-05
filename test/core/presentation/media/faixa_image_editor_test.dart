import 'package:app_faixa_amarela/core/presentation/media/faixa_image_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// A UI do cropper é nativa (uCrop/TOCropViewController) e não é exercitável
/// em widget tests — estes testes cobrem o pipeline do helper com fakes do
/// [ImagePicker] e do [ImageCropper].
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker(this.result);

  final XFile? result;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async => result;
}

class _FakeImageCropper extends ImageCropper {
  _FakeImageCropper({this.resultPath});

  final String? resultPath;

  CropAspectRatio? capturedAspectRatio;
  int? capturedCompressQuality;
  int? capturedMaxWidth;
  int? capturedMaxHeight;

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) async {
    capturedAspectRatio = aspectRatio;
    capturedCompressQuality = compressQuality;
    capturedMaxWidth = maxWidth;
    capturedMaxHeight = maxHeight;
    final path = resultPath;
    return path == null ? null : CroppedFile(path);
  }
}

void main() {
  group('pickCropCompressImage', () {
    test('retorna null quando o usuário cancela a seleção', () async {
      final file = await pickCropCompressImage(
        source: ImageSource.gallery,
        profile: FaixaCropProfile.avatar,
        picker: _FakeImagePicker(null),
        cropper: _FakeImageCropper(),
      );

      expect(file, isNull);
    });

    test('retorna null quando o usuário cancela o corte', () async {
      final file = await pickCropCompressImage(
        source: ImageSource.gallery,
        profile: FaixaCropProfile.avatar,
        picker: _FakeImagePicker(XFile('/tmp/original.jpg')),
        cropper: _FakeImageCropper(resultPath: null),
      );

      expect(file, isNull);
    });

    test('retorna o File cortado/comprimido no caminho feliz', () async {
      final file = await pickCropCompressImage(
        source: ImageSource.gallery,
        profile: FaixaCropProfile.avatar,
        picker: _FakeImagePicker(XFile('/tmp/original.jpg')),
        cropper: _FakeImageCropper(resultPath: '/tmp/cropped.jpg'),
      );

      expect(file, isNotNull);
      expect(file!.path, '/tmp/cropped.jpg');
    });

    test('trava o crop em 1:1 para avatar e criança', () async {
      for (final profile in [FaixaCropProfile.avatar, FaixaCropProfile.child]) {
        final cropper = _FakeImageCropper(resultPath: '/tmp/cropped.jpg');
        await pickCropCompressImage(
          source: ImageSource.gallery,
          profile: profile,
          picker: _FakeImagePicker(XFile('/tmp/original.jpg')),
          cropper: cropper,
        );

        expect(cropper.capturedAspectRatio?.ratioX, 1);
        expect(cropper.capturedAspectRatio?.ratioY, 1);
      }
    });

    test('trava o crop em ~2.8:1 para a foto da van (banner público)',
        () async {
      final cropper = _FakeImageCropper(resultPath: '/tmp/cropped.jpg');
      await pickCropCompressImage(
        source: ImageSource.gallery,
        profile: FaixaCropProfile.vehicle,
        picker: _FakeImagePicker(XFile('/tmp/original.jpg')),
        cropper: cropper,
      );

      expect(cropper.capturedAspectRatio?.ratioX, closeTo(2.8, 0.001));
      expect(cropper.capturedAspectRatio?.ratioY, 1);
    });

    test('sempre aplica compressão quality 85 e limite 1600px', () async {
      final cropper = _FakeImageCropper(resultPath: '/tmp/cropped.jpg');
      await pickCropCompressImage(
        source: ImageSource.gallery,
        profile: FaixaCropProfile.vehicle,
        picker: _FakeImagePicker(XFile('/tmp/original.jpg')),
        cropper: cropper,
      );

      expect(cropper.capturedCompressQuality, 85);
      expect(cropper.capturedMaxWidth, 1600);
      expect(cropper.capturedMaxHeight, 1600);
    });
  });

  group('FaixaCropProfile', () {
    test('proporções configuradas', () {
      expect(FaixaCropProfile.avatar.ratioX / FaixaCropProfile.avatar.ratioY, 1);
      expect(FaixaCropProfile.child.ratioX / FaixaCropProfile.child.ratioY, 1);
      expect(
        FaixaCropProfile.vehicle.ratioX / FaixaCropProfile.vehicle.ratioY,
        closeTo(2.8, 0.001),
      );
    });
  });
}
