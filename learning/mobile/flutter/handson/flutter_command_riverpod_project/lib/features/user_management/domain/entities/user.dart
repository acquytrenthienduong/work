import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required String id,
    required String name,
    required String email,
    required String phone,
    required String website,
    required UserAddress address,
    required UserCompany company,
    @Default(false) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

@freezed
class UserAddress with _$UserAddress {
  const factory UserAddress({
    required String street,
    required String suite,
    required String city,
    required String zipcode,
    required UserGeo geo,
  }) = _UserAddress;

  factory UserAddress.fromJson(Map<String, dynamic> json) => _$UserAddressFromJson(json);
}

@freezed
class UserGeo with _$UserGeo {
  const factory UserGeo({
    required String lat,
    required String lng,
  }) = _UserGeo;

  factory UserGeo.fromJson(Map<String, dynamic> json) => _$UserGeoFromJson(json);
}

@freezed
class UserCompany with _$UserCompany {
  const factory UserCompany({
    required String name,
    required String catchPhrase,
    required String bs,
  }) = _UserCompany;

  factory UserCompany.fromJson(Map<String, dynamic> json) => _$UserCompanyFromJson(json);
}

// Helper extension for user operations
extension UserExtensions on User {
  String get fullAddress => '${address.street}, ${address.suite}, ${address.city}';
  String get displayName => name.isNotEmpty ? name : email;
  bool get hasValidEmail => email.contains('@') && email.contains('.');
} 