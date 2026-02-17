import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String id;
  final String customerId;
  final dynamic storeProduct; // Can be String (ID only) or Map (populated)
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CartItem({
    required this.id,
    required this.customerId,
    required this.storeProduct,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] as String,
      customerId: _extractId(json['customerId']),
      storeProduct: json['storeProductId'],
      quantity: (json['quantity'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Extract ID whether it's a plain string or a populated object with _id
  static String _extractId(dynamic value) {
    if (value is String) return value;
    if (value is Map && value.containsKey('_id')) return value['_id'] as String;
    return value.toString();
  }

  /// Get storeProductId as a string regardless of population
  String get storeProductId {
    if (storeProduct is String) return storeProduct as String;
    if (storeProduct is Map) return (storeProduct as Map)['_id'] as String;
    return storeProduct.toString();
  }

  /// Get product name if storeProduct is populated
  String? get productName {
    if (storeProduct is Map) {
      final product = (storeProduct as Map)['productId'];
      if (product is Map) return product['name'] as String?;
    }
    return null;
  }

  /// Get store-specific price if storeProduct is populated
  double? get productPrice {
    if (storeProduct is Map) {
      return ((storeProduct as Map)['price'] as num?)?.toDouble();
    }
    return null;
  }

  /// Get product main price (original price) if populated
  double? get productMainPrice {
    if (storeProduct is Map) {
      final product = (storeProduct as Map)['productId'];
      if (product is Map) {
        return (product['mainPrice'] as num?)?.toDouble();
      }
    }
    return null;
  }

  /// Get product sale price if populated
  double? get productSalePrice {
    if (storeProduct is Map) {
      final product = (storeProduct as Map)['productId'];
      if (product is Map) {
        return (product['salePrice'] as num?)?.toDouble();
      }
    }
    return null;
  }

  /// Get product description if populated
  String? get productDescription {
    if (storeProduct is Map) {
      final product = (storeProduct as Map)['productId'];
      if (product is Map) return product['description'] as String?;
    }
    return null;
  }

  /// Get product images if storeProduct is populated
  List<String> get productImages {
    if (storeProduct is Map) {
      final product = (storeProduct as Map)['productId'];
      if (product is Map && product['images'] is List) {
        return (product['images'] as List).cast<String>();
      }
    }
    return [];
  }

  /// Line total for this item
  double get lineTotal => (productPrice ?? 0) * quantity;

  /// How long ago this item was last updated
  String get updatedAgo {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  List<Object?> get props => [id, quantity, updatedAt];
}
