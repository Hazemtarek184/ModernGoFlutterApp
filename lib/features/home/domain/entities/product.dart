import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final List<String> images;
  final double mainPrice;
  final double discountPercent;
  final double salePrice;
  final int stock;
  final int soldItems;
  final String createdBy;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.images,
    required this.mainPrice,
    required this.discountPercent,
    required this.salePrice,
    required this.stock,
    required this.soldItems,
    required this.createdBy,
  });

  @override
  List<Object?> get props => [id, name, salePrice];
}
