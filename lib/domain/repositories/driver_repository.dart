import '../models/driver_profile.dart';

abstract interface class DriverRepository {
  Future<DriverProfile?> getDriverProfile();

  /// Atualiza nome/telefone (`/users/me`) e CNH/informações (`/drivers/me`).
  /// E-mail NÃO entra aqui: a troca de e-mail exige verificação e segue
  /// fora do app (APP-06).
  Future<DriverProfile> updateBasicProfile({
    required String name,
    String? cellPhone,
    String? information,
    String? cnh,
  });

  /// Atualiza o contato público da van (`PUT /drivers/me/vehicle`) — exibido
  /// aos pais no lugar do telefone pessoal do motorista. Diferente dos dados
  /// estruturais da van (placa/modelo/cor/ano), não exige aprovação do admin.
  /// Valores vazios ('') limpam o campo no servidor (convenção APP-11).
  Future<void> updateVehiclePublicContact({
    String? publicContactName,
    String? publicContactPhone,
  });
}
