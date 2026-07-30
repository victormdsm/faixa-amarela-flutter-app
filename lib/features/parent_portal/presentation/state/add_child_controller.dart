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
    required this.document,
    required this.schoolId,
    required this.shiftId,
    required this.address,
    this.documentType = ChildDocumentType.cpf,
    this.documentState,
    this.originalAddress,
    this.photoLocalPath,
  });

  final String name;

  /// Número do documento (CPF ou RG, conforme [documentType]).
  final String document;

  /// Tipo do documento ('cpf' default | 'rg').
  final String documentType;

  /// UF emissora — obrigatória quando RG, sempre null quando CPF.
  final String? documentState;

  final int? schoolId;
  final int? shiftId;
  final ChildAddress address;

  /// Endereço default carregado na edição (antes das alterações do pai).
  /// Usado para decidir se o endereço precisa ser regravado.
  final ChildAddress? originalAddress;
  final String? photoLocalPath;
}

class AddChildController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return Future.value();
  }

  /// Compara o endereço editado com o original para decidir se regrava.
  ///
  /// Sem original (endereço não carregado / criança sem endereço) considera
  /// que mudou — o fluxo de salvar segue o comportamento anterior
  /// (create-or-update). Coordenadas usam epsilon para absorver ruído de
  /// ponto flutuante do parse JSON.
  static bool addressChanged(ChildAddress? before, ChildAddress after) {
    if (before == null) return true;

    String norm(String? s) => (s ?? '').trim();
    if (norm(before.street) != norm(after.street)) return true;
    if (norm(before.number) != norm(after.number)) return true;
    if (norm(before.complement) != norm(after.complement)) return true;
    if (norm(before.zipCode) != norm(after.zipCode)) return true;
    if (norm(before.district) != norm(after.district)) return true;
    if (norm(before.city) != norm(after.city)) return true;
    if (norm(before.state) != norm(after.state)) return true;

    bool coordChanged(double? a, double? b) {
      if (a == null && b == null) return false;
      if (a == null || b == null) return true;
      return (a - b).abs() > 1e-6;
    }

    return coordChanged(before.latitude, after.latitude) ||
        coordChanged(before.longitude, after.longitude);
  }

  /// Detecta se o campo complemento foi editado (APP-01). Só nesse caso a
  /// chave `reference` vai no payload do update — reenviá-la sem edição
  /// apagaria o complemento gravado quando o backend não a devolveu no GET
  /// (campo do form viria vazio e o null seria persistido por cima).
  static bool complementChanged(ChildAddress? before, ChildAddress after) {
    String norm(String? s) => (s ?? '').trim();
    return norm(before?.complement) != norm(after.complement);
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
        document: formData.document,
        documentType: formData.documentType,
        documentState: formData.documentState,
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
        document: formData.document,
        documentType: formData.documentType,
        documentState: formData.documentState,
        schoolId: formData.schoolId,
        shiftId: formData.shiftId,
      );

      // Só regrava o endereço default quando algo mudou — antes toda
      // edição de dados pessoais reescrevia o endereço (e re-geocodificava).
      if (addressChanged(formData.originalAddress, formData.address)) {
        final addresses = await repo.getChildAddresses(id);
        if (addresses.isNotEmpty) {
          bool isDefault(Map<String, dynamic> a) {
            final raw = a['isDefault'] ?? a['is_default'];
            return raw == true || raw == 1;
          }

          final defaultAddress = addresses.firstWhere(
            isDefault,
            orElse: () => addresses.first,
          );
          final addressId = (defaultAddress['id'] as num?)?.toInt();
          if (addressId == null) {
            // Resposta sem id não deve derrubar o fluxo: loga e segue sem
            // regravar o endereço (os dados pessoais já foram salvos).
            debugPrint(
              '[AddChildController] endereco default sem id; '
              'atualizacao de endereco ignorada (child $id).',
            );
          } else {
            await repo.updateChildAddress(
              childId: id,
              addressId: addressId,
              address: formData.address,
              // APP-01: `reference` só é enviada quando o pai editou o
              // complemento; caso contrário a chave é omitida e o backend
              // preserva o valor gravado.
              includeReference: complementChanged(
                formData.originalAddress,
                formData.address,
              ),
            );
          }
        } else {
          await repo.createChildAddress(
            childId: id,
            address: formData.address,
            isDefault: true,
          );
        }
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
