import '../../domain/models/child.dart';

class ChildDto {
  const ChildDto({
    required this.id,
    required this.name,
    required this.cpf,
    this.schoolId,
    this.shiftId,
    this.isInDebt = false,
    this.createdAt,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String cpf;
  final int? schoolId;
  final int? shiftId;
  final bool isInDebt;
  final DateTime? createdAt;
  final String? photoUrl;

  factory ChildDto.fromJson(Map<String, dynamic> json) {
    final isInDebtRaw =
        json['isInadimplent'] ?? json['isInDebt'] ?? json['inadimplencyAlert'];

    return ChildDto(
      id: _toInt(json['id']) ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      schoolId: _toInt(json['schoolId']),
      shiftId: _toInt(json['shiftId']),
      isInDebt: isInDebtRaw == true || isInDebtRaw == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cpf': cpf,
      if (schoolId != null) 'schoolId': schoolId,
      if (shiftId != null) 'shiftId': shiftId,
      'isInDebt': isInDebt,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  Child toDomain() {
    return Child(
      id: id,
      name: name,
      cpf: cpf,
      schoolId: schoolId,
      shiftId: shiftId,
      isInDebt: isInDebt,
      createdAt: createdAt,
      photoUrl: photoUrl,
    );
  }

  factory ChildDto.fromDomain(Child child) {
    return ChildDto(
      id: child.id,
      name: child.name,
      cpf: child.cpf,
      schoolId: child.schoolId,
      shiftId: child.shiftId,
      isInDebt: child.isInDebt,
      createdAt: child.createdAt,
      photoUrl: child.photoUrl,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

