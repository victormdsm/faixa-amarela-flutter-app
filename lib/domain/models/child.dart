class Child {
  const Child({
    required this.id,
    required this.name,
    required this.cpf,
    required this.schoolId,
    required this.shiftId,
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

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      cpf: (json['cpf'] ?? '').toString(),
      schoolId: (json['schoolId'] as num?)?.toInt(),
      shiftId: (json['shiftId'] as num?)?.toInt(),
      isInDebt: json['isInDebt'] == true || json['isInDebt'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      photoUrl: json['photoUrl']?.toString(),
    );
  }
}

class ChildAddress {
  const ChildAddress({
    required this.street,
    required this.number,
    this.complement,
    this.zipCode,
  });

  final String street;
  final String number;
  final String? complement;
  final String? zipCode;

  factory ChildAddress.fromJson(Map<String, dynamic> json) {
    return ChildAddress(
      street: (json['street'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      complement: json['complement']?.toString(),
      zipCode: (json['zipCode'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'number': number,
      if (complement != null && complement!.trim().isNotEmpty)
        'complement': complement,
      if (zipCode != null && zipCode!.trim().isNotEmpty) 'zipCode': zipCode,
    };
  }
}
