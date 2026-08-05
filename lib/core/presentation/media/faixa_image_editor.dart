import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_theme.dart';

/// Perfil de corte/compressão aplicado no pipeline de seleção de imagens.
///
/// A proporção é travada na razão em que a imagem será EXIBIDA no app, para
/// que o preview do editor de corte seja fiel ao resultado final:
/// - [avatar] e [child]: 1:1 (avatar circular / quadrado da criança).
/// - [vehicle]: ~2.8:1 (banner da van exibido com largura de tela x 140px de
///   altura no detalhe público — ver public_transport_driver_detail_sheet).
enum FaixaCropProfile {
  avatar(ratioX: 1, ratioY: 1),
  child(ratioX: 1, ratioY: 1),
  vehicle(ratioX: 2.8, ratioY: 1);

  const FaixaCropProfile({required this.ratioX, required this.ratioY});

  final double ratioX;
  final double ratioY;
}

/// Pipeline compartilhado de seleção de imagem:
/// galeria/câmera → editor de corte travado na proporção de exibição →
/// compressão → [File] pronto para o upload existente (multipart inalterado).
///
/// Retorna `null` quando o usuário cancela em qualquer etapa.
///
/// A UI do cropper é nativa (uCrop no Android, TOCropViewController no iOS),
/// portanto não é exercitável em widget tests — testes cobrem apenas os
/// pontos de integração deste helper.
Future<File?> pickCropCompressImage({
  required ImageSource source,
  required FaixaCropProfile profile,
  ImagePicker? picker,
  ImageCropper? cropper,
}) async {
  final picked = await (picker ?? ImagePicker()).pickImage(source: source);
  if (picked == null) return null;

  final cropped = await (cropper ?? ImageCropper()).cropImage(
    sourcePath: picked.path,
    aspectRatio: CropAspectRatio(ratioX: profile.ratioX, ratioY: profile.ratioY),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: 85,
    maxWidth: 1600,
    maxHeight: 1600,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Ajustar foto',
        toolbarColor: AppColors.ink,
        toolbarWidgetColor: AppColors.yellow,
        statusBarLight: false,
        navBarLight: true,
        backgroundColor: AppColors.ink,
        activeControlsWidgetColor: AppColors.yellow,
        dimmedLayerColor: Colors.black.withValues(alpha: 0.7),
        cropFrameColor: AppColors.yellow,
        cropGridColor: AppColors.yellow.withValues(alpha: 0.5),
        lockAspectRatio: true,
        hideBottomControls: true,
      ),
      IOSUiSettings(
        title: 'Ajustar foto',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPickerButtonHidden: true,
      ),
    ],
  );
  if (cropped == null) return null;

  return File(cropped.path);
}
