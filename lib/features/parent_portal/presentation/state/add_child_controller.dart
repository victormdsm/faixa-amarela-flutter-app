import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/app_failure.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../domain/models/child.dart';
import '../../../../features/auth/presentation/state/app_session_controller.dart';
import '../providers/parent_portal_providers.dart';

class AddChildFormData {
  const AddChildFormData({
    required this.name,
    required this.cpf,
    required this.schoolId,
    required this.shiftId,
    required this.address,
    this.photoLocalPath,
  });

  final String name;
  final String cpf;
  final int? schoolId;
  final int? shiftId;
  final ChildAddress address;
  final String? photoLocalPath;
}

class AddChildController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return Future.value();
  }

  AppFailure _mapError(Object error, String contextMessage) {
    if (error is AppFailure) return error;
    if (error is ApiException) {
      return ServerFailure(message: error.message);
    }
    debugPrint('[AddChildController] $contextMessage: $error');
    return ServerFailure(message: '$contextMessage. Tente novamente.');
  }

  Future<Child> submit(AddChildFormData formData) async {
    final repo = ref.read(childrenRepositoryProvider);
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      throw const AuthFailure(
        message: 'Sessao expirada. Faca login novamente.',
      );
    }

    state = const AsyncValue.loading();
    Child? child;
    state = await AsyncValue.guard(() async {
      child = await repo.createChild(
        name: formData.name,
        cpf: formData.cpf,
        schoolId: formData.schoolId,
        shiftId: formData.shiftId,
        address: formData.address,
      );

      final localPath = formData.photoLocalPath;
      if (localPath != null && localPath.isNotEmpty) {
        child = await repo.uploadChildPhoto(
          childId: child!.id,
          filePath: localPath,
        );
      }
    });

    if (state.hasError || child == null) {
      throw _mapError(
        state.error ?? 'Erro desconhecido',
        'Erro ao cadastrar dependente',
      );
    }
    return child!;
  }

  Future<Child> updateChild(int id, AddChildFormData formData) async {
    final repo = ref.read(childrenRepositoryProvider);
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      throw const AuthFailure(
        message: 'Sessao expirada. Faca login novamente.',
      );
    }

    state = const AsyncValue.loading();
    Child? child;
    state = await AsyncValue.guard(() async {
      child = await repo.updateChild(
        id: id,
        name: formData.name,
        cpf: formData.cpf,
        schoolId: formData.schoolId,
        shiftId: formData.shiftId,
      );

      final addresses = await repo.getChildAddresses(id);
      if (addresses.isNotEmpty) {
        final addressId = (addresses.first['id'] as num).toInt();
        await repo.updateChildAddress(
          childId: id,
          addressId: addressId,
          address: formData.address,
        );
      } else {
        await repo.createChildAddress(childId: id, address: formData.address);
      }

      final localPath = formData.photoLocalPath;
      if (localPath != null && localPath.isNotEmpty) {
        child = await repo.uploadChildPhoto(childId: id, filePath: localPath);
      }
    });

    if (state.hasError || child == null) {
      throw _mapError(
        state.error ?? 'Erro desconhecido',
        'Erro ao atualizar dependente',
      );
    }
    return child!;
  }
}
