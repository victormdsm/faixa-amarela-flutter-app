import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import 'full_image_viewer.dart';
import 'skeleton_image_placeholder.dart';

enum FaixaImagePickerVariant {
  /// Avatar circular de 68px com badge de câmera e label opcional ao lado.
  avatar,

  /// Quadrado 120x120 com borda 24, indicadores de loading e falha de upload.
  child,

  /// Retângulo 4:3 com overlay de "Trocar foto", usado para veículo.
  ///
  /// A altura é derivada da largura via [AspectRatio] para espelhar a
  /// exibição no detalhe público (WYSIWYG).
  vehicle,
}

/// Picker unificado de imagens para o app Faixa Amarela.
///
/// Suporta imagem remota via [CachedNetworkImage], imagem local via [File],
/// estados de loading, erro de upload e empty states.
///
/// Use os factory constructors nomeados para cada variação de UI:
/// - [FaixaImagePicker.avatar]
/// - [FaixaImagePicker.child]
/// - [FaixaImagePicker.vehicle]
class FaixaImagePicker extends StatelessWidget {
  const FaixaImagePicker._({
    required this.variant,
    this.imageUrl,
    this.localPath,
    this.onTap,
    this.fit = BoxFit.cover,
    this.loading = false,
    this.uploadFailed = false,
    this.placeholderLabel,
    this.overlayLabel,
    this.label,
    this.semanticLabel,
  });

  factory FaixaImagePicker.avatar({
    String? imageUrl,
    String? localPath,
    VoidCallback? onTap,
    BoxFit fit = BoxFit.cover,
    String? label,
    String? semanticLabel,
  }) => FaixaImagePicker._(
    variant: FaixaImagePickerVariant.avatar,
    imageUrl: imageUrl,
    localPath: localPath,
    onTap: onTap,
    fit: fit,
    label: label,
    semanticLabel: semanticLabel,
  );

  factory FaixaImagePicker.child({
    String? imageUrl,
    String? localPath,
    required VoidCallback onTap,
    BoxFit fit = BoxFit.cover,
    bool loading = false,
    bool uploadFailed = false,
    String? placeholderLabel,
    String? semanticLabel,
  }) => FaixaImagePicker._(
    variant: FaixaImagePickerVariant.child,
    imageUrl: imageUrl,
    localPath: localPath,
    onTap: onTap,
    fit: fit,
    loading: loading,
    uploadFailed: uploadFailed,
    placeholderLabel: placeholderLabel ?? 'Foto do dependente',
    semanticLabel: semanticLabel,
  );

  factory FaixaImagePicker.vehicle({
    String? imageUrl,
    String? localPath,
    VoidCallback? onTap,
    BoxFit fit = BoxFit.cover,
    String overlayLabel = 'Trocar foto',
    String? semanticLabel,
  }) => FaixaImagePicker._(
    variant: FaixaImagePickerVariant.vehicle,
    imageUrl: imageUrl,
    localPath: localPath,
    onTap: onTap,
    fit: fit,
    overlayLabel: overlayLabel,
    semanticLabel: semanticLabel,
  );

  final FaixaImagePickerVariant variant;
  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onTap;
  final BoxFit fit;
  final bool loading;
  final bool uploadFailed;
  final String? placeholderLabel;
  final String? overlayLabel;
  final String? label;
  final String? semanticLabel;

  bool get _hasLocal => localPath != null && localPath!.isNotEmpty;
  bool get _hasRemote => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? placeholderLabel ?? overlayLabel,
      button: onTap != null,
      child: switch (variant) {
        FaixaImagePickerVariant.avatar => _buildAvatar(context),
        FaixaImagePickerVariant.child => _buildChild(context),
        FaixaImagePickerVariant.vehicle => _buildVehicle(context),
      },
    );
  }

  Widget _buildChild(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: uploadFailed ? AppColors.danger : AppColors.border,
            width: uploadFailed ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            loading
                ? const Center(child: CircularProgressIndicator())
                : _imageContent(context),
            if (uploadFailed) _uploadFailedOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final avatar = Stack(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.yellowLight,
          backgroundImage: _hasLocal ? FileImage(File(localPath!)) : null,
          child: _hasLocal
              ? null
              : _hasRemote
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl!,
                    width: 68,
                    height: 68,
                    fit: fit,
                    placeholder: (context, url) =>
                        const SkeletonImagePlaceholder(),
                    errorWidget: (context, url, error) => _errorIcon(),
                  ),
                )
              : const Icon(Icons.person_outline_rounded, color: AppColors.ink),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt_rounded,
              size: 12,
              color: Colors.white,
            ),
          ),
        ),
        // Botão "olho": abre a foto completa com zoom. Botão separado do
        // GestureDetector de troca de foto (não dispara o onTap).
        Positioned(
          right: 0,
          top: 0,
          child: FullImageViewerEyeButton(
            imageUrl: imageUrl,
            localPath: localPath,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: label == null
          ? avatar
          : Row(
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        onTap != null ? 'Toque para alterar' : '',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
    );
  }

  Widget _buildVehicle(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                color: AppColors.surface,
              ),
              clipBehavior: Clip.antiAlias,
              child: _imageContent(context, vehicleEmpty: true),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.ink.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      overlayLabel ?? 'Trocar foto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Botão "olho": abre a foto completa com zoom. Botão separado do
            // GestureDetector de troca de foto (não dispara o onTap).
            Positioned(
              top: 10,
              right: 10,
              child: FullImageViewerEyeButton(
                imageUrl: imageUrl,
                localPath: localPath,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageContent(BuildContext context, {bool vehicleEmpty = false}) {
    if (_hasLocal) {
      return Image.file(File(localPath!), fit: fit);
    }
    if (_hasRemote) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: fit,
        placeholder: (context, url) => const SkeletonImagePlaceholder(),
        errorWidget: (context, url, error) => _errorIcon(),
      );
    }
    return vehicleEmpty ? _vehicleEmpty(context) : _placeholder(context);
  }

  Widget _placeholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: 32,
          color: AppColors.muted,
        ),
        const SizedBox(height: 6),
        Text(
          placeholderLabel ?? 'Selecionar foto',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _vehicleEmpty(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.surfaceSoft),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 28,
              color: AppColors.slate,
            ),
            const SizedBox(height: 6),
            Text(
              placeholderLabel ?? 'Sem foto do veículo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadFailedOverlay(BuildContext context) {
    return Container(
      color: AppColors.danger.withValues(alpha: 0.12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.refresh_rounded, color: AppColors.danger, size: 32),
          const SizedBox(height: 4),
          Text(
            'Tentar foto',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.danger,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorIcon() {
    return Container(
      color: AppColors.yellowLight,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.muted,
      ),
    );
  }
}
