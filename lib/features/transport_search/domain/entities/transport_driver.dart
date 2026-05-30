import 'package:freezed_annotation/freezed_annotation.dart';

import 'service_period.dart';

part 'transport_driver.freezed.dart';
part 'transport_driver.g.dart';

@freezed
abstract class TransportDriver with _$TransportDriver {
  const factory TransportDriver({
    required String id,
    required String driverName,
    required String vanName,
    required String whatsappNumber,
    required List<String> schools,
    required List<String> neighborhoods,
    required List<ServicePeriod> periods,
    required int availableSeats,
    required double rating,
    @Default(0) int yearsExperience,
    String? note,
  }) = _TransportDriver;

  factory TransportDriver.fromJson(Map<String, dynamic> json) =>
      _$TransportDriverFromJson(json);
}
