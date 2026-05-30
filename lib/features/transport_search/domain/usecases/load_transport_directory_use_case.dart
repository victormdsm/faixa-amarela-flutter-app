import '../entities/transport_driver.dart';
import '../repositories/transport_directory_repository.dart';

class LoadTransportDirectoryUseCase {
  const LoadTransportDirectoryUseCase(this._repository);

  final TransportDirectoryRepository _repository;

  Future<List<TransportDriver>> call() {
    return _repository.listDrivers();
  }
}
