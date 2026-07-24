import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/faixa_image_picker.dart';

/// Seção de dados do veículo nas configurações do motorista.
class DriverVehicleSection extends StatelessWidget {
  const DriverVehicleSection({
    super.key,
    required this.brandController,
    required this.colorController,
    required this.yearController,
    required this.plateController,
    required this.isSaving,
    required this.editMode,
    this.imageUrl,
    this.localPath,
    this.onPickImage,
    this.onToggleEdit,
    this.onUndoImage,
  });

  final TextEditingController brandController;
  final TextEditingController colorController;
  final TextEditingController yearController;
  final TextEditingController plateController;
  final bool isSaving;
  final bool editMode;
  final String? imageUrl;
  final String? localPath;
  final VoidCallback? onPickImage;
  final VoidCallback? onToggleEdit;
  final VoidCallback? onUndoImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Edit toggle row
        Row(
          children: [
            const Spacer(),
            if (!editMode)
              TextButton.icon(
                onPressed: isSaving ? null : onToggleEdit,
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Editar dados do veículo'),
              )
            else
              TextButton.icon(
                onPressed: isSaving ? null : onToggleEdit,
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                label: const Text('Cancelar edição'),
                style: TextButton.styleFrom(foregroundColor: AppColors.slate),
              ),
          ],
        ),
        const SizedBox(height: 4),
        FaixaImagePicker.vehicle(
          imageUrl: imageUrl,
          localPath: localPath,
          onTap: (isSaving || !editMode) ? null : onPickImage,
        ),
        if (!editMode) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text(
                'Toque em "Editar dados" para alterar',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ],
        if (localPath != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: isSaving ? null : onUndoImage,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Desfazer foto do veículo'),
          ),
        ],
        const SizedBox(height: 12),
        TextFormField(
          controller: brandController,
          enabled: !isSaving && editMode,
          readOnly: !editMode,
          decoration: const InputDecoration(
            labelText: 'Marca / Modelo',
            prefixIcon: Icon(Icons.directions_bus_outlined),
          ),
          validator: (v) =>
              (v ?? '').trim().isEmpty ? 'Informe a marca/modelo.' : null,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: colorController,
                enabled: !isSaving && editMode,
                readOnly: !editMode,
                decoration: const InputDecoration(
                  labelText: 'Cor',
                  prefixIcon: Icon(Icons.palette_outlined),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: yearController,
                enabled: !isSaving && editMode,
                readOnly: !editMode,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: (v) {
                  final year = int.tryParse(v ?? '');
                  final currentYear = DateTime.now().year + 1;
                  if (year == null || year < 1900 || year > currentYear) {
                    return 'Ano invalido.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: plateController,
          enabled: !isSaving && editMode,
          readOnly: !editMode,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Placa',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          validator: (v) {
            final plate = (v ?? '').trim().toUpperCase();
            if (plate.isEmpty) return 'Placa e obrigatoria.';
            // Aceita placa antiga (ABC1234) ou Mercosul (ABC1D23).
            final regex = RegExp(r'^[A-Z]{3}[0-9][A-Z0-9][0-9]{2}$');
            if (!regex.hasMatch(plate)) return 'Placa invalida.';
            return null;
          },
        ),
      ],
    );
  }
}
