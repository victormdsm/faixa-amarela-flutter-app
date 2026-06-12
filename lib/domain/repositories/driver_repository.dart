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
}
