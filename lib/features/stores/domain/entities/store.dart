import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String name;
  final String email;
  final String address;
  final String phone;
  final String? profilePhoto;
  final StoreLocation location;
  final List<String> categories;
  final double? distance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Store({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    this.profilePhoto,
    required this.location,
    required this.categories,
    this.distance,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [id, name, email, profilePhoto];
}

class StoreLocation extends Equatable {
  final String type;
  final List<double> coordinates;
  final String? address;

  const StoreLocation({
    required this.type,
    required this.coordinates,
    this.address,
  });

  @override
  List<Object?> get props => [type, coordinates, address];
}
