// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transport_driver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TransportDriver _$TransportDriverFromJson(Map<String, dynamic> json) =>
    _TransportDriver(
      id: json['id'] as String,
      driverName: json['driverName'] as String,
      vanName: json['vanName'] as String,
      whatsappNumber: json['whatsappNumber'] as String,
      schools: (json['schools'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      neighborhoods: (json['neighborhoods'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      periods: (json['periods'] as List<dynamic>)
          .map((e) => $enumDecode(_$ServicePeriodEnumMap, e))
          .toList(),
      availableSeats: (json['availableSeats'] as num).toInt(),
      rating: (json['rating'] as num).toDouble(),
      yearsExperience: (json['yearsExperience'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$TransportDriverToJson(
  _TransportDriver instance,
) => <String, dynamic>{
  'id': instance.id,
  'driverName': instance.driverName,
  'vanName': instance.vanName,
  'whatsappNumber': instance.whatsappNumber,
  'schools': instance.schools,
  'neighborhoods': instance.neighborhoods,
  'periods': instance.periods.map((e) => _$ServicePeriodEnumMap[e]!).toList(),
  'availableSeats': instance.availableSeats,
  'rating': instance.rating,
  'yearsExperience': instance.yearsExperience,
  'note': instance.note,
};

const _$ServicePeriodEnumMap = {
  ServicePeriod.morning: 'morning',
  ServicePeriod.afternoon: 'afternoon',
  ServicePeriod.night: 'night',
  ServicePeriod.fullTime: 'fullTime',
};
