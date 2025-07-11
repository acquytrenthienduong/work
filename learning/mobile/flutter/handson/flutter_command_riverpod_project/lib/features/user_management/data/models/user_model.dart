// Simple model without freezed to avoid code generation issues
class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final UserAddressModel address;
  final UserCompanyModel company;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      website: json['website'] ?? '',
      address: UserAddressModel.fromJson(json['address'] ?? {}),
      company: UserCompanyModel.fromJson(json['company'] ?? {}),
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'website': website,
      'address': address.toJson(),
      'company': company.toJson(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class UserAddressModel {
  final String street;
  final String suite;
  final String city;
  final String zipcode;
  final UserGeoModel geo;

  const UserAddressModel({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
    required this.geo,
  });

  factory UserAddressModel.fromJson(Map<String, dynamic> json) {
    return UserAddressModel(
      street: json['street'] ?? '',
      suite: json['suite'] ?? '',
      city: json['city'] ?? '',
      zipcode: json['zipcode'] ?? '',
      geo: UserGeoModel.fromJson(json['geo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'suite': suite,
      'city': city,
      'zipcode': zipcode,
      'geo': geo.toJson(),
    };
  }
}

class UserGeoModel {
  final String lat;
  final String lng;

  const UserGeoModel({
    required this.lat,
    required this.lng,
  });

  factory UserGeoModel.fromJson(Map<String, dynamic> json) {
    return UserGeoModel(
      lat: json['lat'] ?? '',
      lng: json['lng'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class UserCompanyModel {
  final String name;
  final String catchPhrase;
  final String bs;

  const UserCompanyModel({
    required this.name,
    required this.catchPhrase,
    required this.bs,
  });

  factory UserCompanyModel.fromJson(Map<String, dynamic> json) {
    return UserCompanyModel(
      name: json['name'] ?? '',
      catchPhrase: json['catchPhrase'] ?? '',
      bs: json['bs'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'catchPhrase': catchPhrase,
      'bs': bs,
    };
  }
} 