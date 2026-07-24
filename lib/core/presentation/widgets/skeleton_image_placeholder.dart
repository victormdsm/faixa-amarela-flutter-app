import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Placeholder skeleton pulsante para ser usado enquanto imagens de rede são
/// carregadas pelo [CachedNetworkImage].
class SkeletonImagePlaceholder extends StatefulWidget {
  const SkeletonImagePlaceholder({super.key});

  @override
  State<SkeletonImagePlaceholder> createState() =>
      _SkeletonImagePlaceholderState();
}

class _SkeletonImagePlaceholderState extends State<SkeletonImagePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Container(color: AppColors.yellowLight),
      ),
    );
  }
}
