// Domain entities without freezed to avoid code generation issues
class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final UserAddress address;
  final UserCompany company;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
    required this.company,
    this.isActive = false,
    this.createdAt,
    this.updatedAt,
  });

  // Copy with method for immutability
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? website,
    UserAddress? address,
    UserCompany? company,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      address: address ?? this.address,
      company: company ?? this.company,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phone == phone &&
        other.website == website &&
        other.address == address &&
        other.company == company &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        website.hashCode ^
        address.hashCode ^
        company.hashCode ^
        isActive.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, phone: $phone, website: $website, address: $address, company: $company, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

class UserAddress {
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final UserGeo geo;

  const UserAddress({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geo,
  });

  UserAddress copyWith({
    String? street,
    String? suite,
    String? city,
    String? zipcode,
    UserGeo? geo,
  }) {
    return UserAddress(
      street: street ?? this.street,
      suite: suite ?? this.suite,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      geo: geo ?? this.geo,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAddress &&
        other.street == street &&
        other.suite == suite &&
        other.city == city &&
        other.zipcode == zipcode &&
        other.geo == geo;
  }

  @override
  int get hashCode {
    return street.hashCode ^
        suite.hashCode ^
        city.hashCode ^
        zipcode.hashCode ^
        geo.hashCode;
  }

  @override
  String toString() {
    return 'UserAddress(street: $street, suite: $suite, city: $city, zipcode: $zipcode, geo: $geo)';
  }
}

class UserGeo {
  final String lat;
  final String lng;

  const UserGeo({
    required this.lat,
    required this.lng,
  });

  UserGeo copyWith({
    String? lat,
    String? lng,
  }) {
    return UserGeo(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserGeo &&
        other.lat == lat &&
        other.lng == lng;
  }

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;

  @override
  String toString() => 'UserGeo(lat: $lat, lng: $lng)';
}

class UserCompany {
  final String name;
  final String catchPhrase;
  final String bs;

  const UserCompany({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  UserCompany copyWith({
    String? name,
    String? catchPhrase,
    String? bs,
  }) {
    return UserCompany(
      name: name ?? this.name,
      catchPhrase: catchPhrase ?? this.catchPhrase,
      bs: bs ?? this.bs,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCompany &&
        other.name == name &&
        other.catchPhrase == catchPhrase &&
        other.bs == bs;
  }

  @override
  int get hashCode => name.hashCode ^ catchPhrase.hashCode ^ bs.hashCode;

  @override
  String toString() => 'UserCompany(name: $name, catchPhrase: $catchPhrase, bs: $bs)';
}

// Helper extension for user operations
extension UserExtensions on User {
  String get fullAddress => '${address.street}, ${address.suite}, ${address.city}';
  String get displayName => name.isNotEmpty ? name : email;
  bool get hasValidEmail => email.contains('@') && email.contains('.');
} 