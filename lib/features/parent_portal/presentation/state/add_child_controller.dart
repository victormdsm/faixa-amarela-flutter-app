import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../domain/models/child.dart';
import '../../../../features/auth/presentation/state/app_session_controller.dart';
import '../providers/parent_portal_providers.dart';

class AddChildFormData {
  const AddChildFormData({
    required this.name,
    required this.cpf,
    required this.birthDate,
    required this.schoolName,
    required this.shiftId,
    required this.shiftName,
    required this.address,
    this.photoUrl,
  });

  final String name;
  final String cpf;
  final DateTime birthDate;
  final String schoolName;
  final int shiftId;
  final String shiftName;
  final ChildAddress address;
  final String? photoUrl;
}

class AddChildController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return Future.value();
  }

  Future<void> submit(AddChildFormData formData) async {
    final repo = ref.read(childrenRepositoryProvider);
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      throw const AuthFailure(
        message: 'Sessao expirada. Faca login novamente.',
      );
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.createChild(
        name: formData.name,
        cpf: formData.cpf,
        birthDate: formData.birthDate,
        schoolName: formData.schoolName,
        shiftId: formData.shiftId,
        shiftName: formData.shiftName,
        parentId: session.user.id,
        parentName: session.user.name,
        address: formData.address,
        photoUrl: formData.photoUrl,
      );
    });
  }

  Future<void> updateChild(int id, AddChildFormData formData) async {
    final repo = ref.read(childrenRepositoryProvider);
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      throw const AuthFailure(
        message: 'Sessao expirada. Faca login novamente.',
      );
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repo.updateChild(
        id: id,
        name: formData.name,
        cpf: formData.cpf,
        birthDate: formData.birthDate,
        schoolName: formData.schoolName,
        shiftId: formData.shiftId,
        shiftName: formData.shiftName,
        parentId: session.user.id,
        parentName: session.user.name,
        address: formData.address,
        photoUrl: formData.photoUrl,
      );
    });
  }
}
