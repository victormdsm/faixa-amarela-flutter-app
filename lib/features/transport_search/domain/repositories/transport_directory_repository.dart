import '../entities/transport_driver.dart';

abstract interface class TransportDirectoryRepository {
  Future<List<TransportDriver>> listDrivers();
}
