import 'package:modern_go/features/stores/domain/entities/store.dart';

class StoreModel extends Store {
  const StoreModel({
    required super.id,
    required super.name,
    required super.email,
    required super.address,
    required super.phone,
    super.profilePhoto,
    required super.location,
    required super.categories,
    super.distance,
    super.createdAt,
    super.updatedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String?,
      location: StoreLocationModel.fromJson(
        json['location'] as Map<String, dynamic>? ??
            {
              'type': 'Point',
              'coordinates': [0, 0]
            },
      ),
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      distance: (json['distance'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class StoreLocationModel extends StoreLocation {
  const StoreLocationModel({
    required super.type,
    required super.coordinates,
    super.address,
  });

  factory StoreLocationModel.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>? ?? [0, 0];
    return StoreLocationModel(
      type: json['type'] as String? ?? 'Point',
      coordinates: coords.map((e) => (e as num).toDouble()).toList(),
      address: json['address'] as String?,
    );
  }
}
