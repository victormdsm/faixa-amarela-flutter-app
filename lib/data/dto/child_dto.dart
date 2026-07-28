import '../../domain/models/child.dart';

class ChildDto {
  const ChildDto({
    required this.id,
    required this.name,
    required this.cpf,
    this.documentType = ChildDocumentType.cpf,
    this.documentState,
    this.uuid,
    this.schoolId,
    this.shiftId,
    this.isInDebt = false,
    this.createdAt,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String cpf;
  final String documentType;
  final String? documentState;
  final String? uuid;
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
      // Contrato novo manda `document`; respostas antigas mandam `cpf`.
      cpf: (json['document'] ?? json['cpf'] ?? '').toString(),
      documentType: ChildDocumentType.parse(json['documentType']),
      documentState: json['documentState']?.toString(),
      uuid: json['uuid']?.toString(),
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
      'documentType': documentType,
      if (documentState != null) 'documentState': documentState,
      if (uuid != null) 'uuid': uuid,
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
      documentType: documentType,
      documentState: documentState,
      uuid: uuid,
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
      documentType: child.documentType,
      documentState: child.documentState,
      uuid: child.uuid,
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

