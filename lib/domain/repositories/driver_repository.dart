import '../models/driver_profile.dart';

abstract interface class DriverRepository {
  Future<DriverProfile?> getDriverProfile();

  Future<DriverProfile> updateBasicProfile({
    required String name,
    String? email,
    String? cellPhone,
    String? information,
    String? cnh,
  });

  /// Cria ou atualiza o veículo ativo do motorista (`PUT /drivers/me/vehicle`).
  ///
  /// [plate] é obrigatória no backend. Os demais campos devem ser enviados
  /// apenas quando editados pelo motorista (null = não alterar no servidor).
  Future<Map<String, dynamic>> updateMyVehicle({
    required String plate,
    String? brand,
    String? color,
    String? year,
  });
}
