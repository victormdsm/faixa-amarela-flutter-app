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
}
