class ClubInfo {
  final String id;
  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final DateTime updatedAt;
  final String? updatedBy;

  const ClubInfo({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    this.email,
    required this.updatedAt,
    this.updatedBy,
  });

  ClubInfo copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? email,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return ClubInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ClubInfo &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.phone == phone &&
        other.email == email &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }
}
