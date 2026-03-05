class ClubInfo {
  final String id;
  final String name;
  final String? street;
  final String? postalCode;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? email;
  final DateTime updatedAt;
  final String? updatedBy;

  const ClubInfo({
    required this.id,
    required this.name,
    this.street,
    this.postalCode,
    this.city,
    this.latitude,
    this.longitude,
    this.phone,
    this.email,
    required this.updatedAt,
    this.updatedBy,
  });

  ClubInfo copyWith({
    String? id,
    String? name,
    String? street,
    String? postalCode,
    String? city,
    double? latitude,
    double? longitude,
    String? phone,
    String? email,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return ClubInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      street: street ?? this.street,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
        other.street == street &&
        other.postalCode == postalCode &&
        other.city == city &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.phone == phone &&
        other.email == email &&
        other.updatedAt == updatedAt &&
        other.updatedBy == updatedBy;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        street.hashCode ^
        postalCode.hashCode ^
        city.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        phone.hashCode ^
        email.hashCode ^
        updatedAt.hashCode ^
        updatedBy.hashCode;
  }
}
