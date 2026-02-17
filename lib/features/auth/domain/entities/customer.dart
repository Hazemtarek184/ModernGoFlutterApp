import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? profilePhoto;
  final Address? address;
  final String fullName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.profilePhoto,
    this.address,
    required this.fullName,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, email, fullName];
}

class Address extends Equatable {
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const Address({
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  @override
  List<Object?> get props => [street, city, state, postalCode, country];
}
