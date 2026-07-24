import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Banner fallback exibido quando o motorista não possui imagem do veículo.
class VehicleBannerFallback extends StatelessWidget {
  const VehicleBannerFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: AppColors.yellow.withValues(alpha: 0.15),
      child: const Center(
        child: Icon(
          Icons.directions_bus_rounded,
          size: 42,
          color: AppColors.yellowDark,
        ),
      ),
    );
  }
}
