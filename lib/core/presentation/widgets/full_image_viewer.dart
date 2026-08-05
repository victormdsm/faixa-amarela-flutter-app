import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Abre um viewer full-screen com a imagem COMPLETA (sem crop) e zoom via
/// pinch/pan ([InteractiveViewer]). Toque no fundo escuro ou no botão fechar
/// para sair.
///
/// Aceita imagem remota ([imageUrl]) ou arquivo local ([localPath]).
Future<void> showFullImageViewer(
  BuildContext context, {
  String? imageUrl,
  String? localPath,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => FullImageViewer(imageUrl: imageUrl, localPath: localPath),
  );
}

/// Dialog full-screen de visualização de imagem com zoom.
class FullImageViewer extends StatelessWidget {
  const FullImageViewer({super.key, this.imageUrl, this.localPath});

  final String? imageUrl;
  final String? localPath;

  bool get _hasLocal => localPath != null && localPath!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(color: Colors.transparent),
          ),
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: _buildImage(),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).maybePop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Fechar',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_hasLocal) {
      return Image.file(File(localPath!), fit: BoxFit.contain);
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.contain,
        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(
          Icons.image_not_supported_outlined,
          color: Colors.white54,
          size: 48,
        ),
      );
    }
    return const Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white54,
      size: 48,
    );
  }
}

/// Botão "olho" discreto (overlay circular) que abre o [FullImageViewer].
///
/// Pensado para ser empilhado (Stack/Positioned) sobre pickers e banners de
/// imagem. Renderiza `SizedBox.shrink` quando não há imagem a exibir.
class FullImageViewerEyeButton extends StatelessWidget {
  const FullImageViewerEyeButton({
    super.key,
    this.imageUrl,
    this.localPath,
    this.tooltip = 'Ver foto completa',
  });

  final String? imageUrl;
  final String? localPath;
  final String tooltip;

  bool get _hasImage =>
      (localPath != null && localPath!.isNotEmpty) ||
      (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    if (!_hasImage) return const SizedBox.shrink();
    return IconButton(
      onPressed: () =>
          showFullImageViewer(context, imageUrl: imageUrl, localPath: localPath),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        minimumSize: const Size(32, 32),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
    );
  }
}
