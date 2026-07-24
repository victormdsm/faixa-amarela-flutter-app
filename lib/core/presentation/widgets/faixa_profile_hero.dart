import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import 'skeleton_image_placeholder.dart';

/// Hero de perfil unificado.
///
/// Exibe avatar, nome e subtítulo em um container com gradiente amarelo.
/// Suporta toque no avatar para alterar foto e variação de formato
/// (quadrado arredondado ou circular).
class FaixaProfileHero extends StatelessWidget {
  const FaixaProfileHero({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    this.avatarLocalPath,
    this.onAvatarTap,
    this.avatarShape = BoxShape.rectangle,
    this.tag,
  });

  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final String? avatarLocalPath;
  final VoidCallback? onAvatarTap;
  final BoxShape avatarShape;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.yellow, AppColors.yellowLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Avatar(
            imageUrl: avatarUrl,
            localPath: avatarLocalPath,
            onTap: onAvatarTap,
            shape: avatarShape,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name.isNotEmpty ? name : 'Usuario',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if ((subtitle ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.ink.withValues(alpha: 0.72),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (tag != null && tag!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                tag!,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    this.imageUrl,
    this.localPath,
    this.onTap,
    required this.shape,
  });

  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onTap;
  final BoxShape shape;

  bool get _hasLocal => localPath != null && localPath!.isNotEmpty;
  bool get _hasRemote => imageUrl != null && imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    const size = 96.0;

    Widget imageContent;
    if (_hasLocal) {
      imageContent = Image.file(
        File(localPath!),
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (_hasRemote) {
      imageContent = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SkeletonImagePlaceholder(),
        errorWidget: (context, url, error) => _fallbackIcon(size),
      );
    } else {
      imageContent = _fallbackIcon(size);
    }

    Widget avatar;
    if (shape == BoxShape.rectangle) {
      avatar = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageContent,
      );
    } else {
      avatar = CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.surface,
        child: ClipOval(child: imageContent),
      );
    }

    if (onTap == null) return avatar;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        GestureDetector(onTap: onTap, child: avatar),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.yellow, width: 2),
          ),
          child: const Icon(
            Icons.camera_alt_outlined,
            size: 16,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.yellowLight,
      child: const Icon(
        Icons.person_outline_rounded,
        size: 40,
        color: AppColors.ink,
      ),
    );
  }
}
