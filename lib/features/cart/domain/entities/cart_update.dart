import 'cart_item.dart';
import 'cart_warning.dart';

class CartUpdate {
  final String action; // "pick" or "release"
  final CartItem? item;
  final List<CartItem> cart;
  final List<CartWarning> warnings;

  CartUpdate({
    required this.action,
    required this.item,
    required this.cart,
    this.warnings = const [],
  });

  factory CartUpdate.fromJson(Map<String, dynamic> json) {
    return CartUpdate(
      action: json['action'] as String,
      item: json['item'] != null
          ? CartItem.fromJson(Map<String, dynamic>.from(json['item'] as Map))
          : null,
      cart: (json['cart'] as List)
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      warnings: json['warnings'] != null
          ? (json['warnings'] as List)
              .map((e) => CartWarning.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : const [],
    );
  }

  bool get isPick => action == 'pick';
  bool get isRelease => action == 'release';
  bool get isItemRemoved => item == null && isRelease;
}
