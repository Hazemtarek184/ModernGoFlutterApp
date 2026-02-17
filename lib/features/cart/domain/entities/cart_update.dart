import 'cart_item.dart';

class CartUpdate {
  final String action; // "pick" or "release"
  final CartItem? item;
  final List<CartItem> cart;

  CartUpdate({
    required this.action,
    required this.item,
    required this.cart,
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
    );
  }

  bool get isPick => action == 'pick';
  bool get isRelease => action == 'release';
  bool get isItemRemoved => item == null && isRelease;
}
