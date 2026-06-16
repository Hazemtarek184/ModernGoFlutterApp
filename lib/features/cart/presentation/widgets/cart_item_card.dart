import 'package:flutter/material.dart';
import 'package:modern_go/core/widgets/custom_network_image.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/cart/domain/entities/cart_item.dart';
import 'package:modern_go/features/cart/domain/entities/cart_warning.dart';

/// A single cart item card matching the design:
/// - Product image thumbnail on the left
/// - Product name + unit price below
/// - "Detected · Updated Xs ago" status
/// - "Qty: N · $X.XX" on the right
/// - Optional "Report mismatch" link
/// - Optional health warning card beneath the item row
class CartItemCard extends StatefulWidget {
  final CartItem item;
  final bool showDivider;
  final List<CartWarning> warnings;

  const CartItemCard({
    super.key,
    required this.item,
    this.showDivider = true,
    this.warnings = const [],
  });

  @override
  State<CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<CartItemCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final warning = _findWarning();
    if (warning != null) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void didUpdateWidget(CartItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final warning = _findWarning();
    if (warning != null) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Find a warning that matches this item's product name (case-insensitive contains match)
  CartWarning? _findWarning() {
    final productName = (widget.item.productName ?? '').toLowerCase();
    if (productName.isEmpty) return null;
    try {
      return widget.warnings.firstWhere(
        (w) =>
            productName.contains(w.productName) ||
            w.productName.contains(productName) ||
            _wordsOverlap(productName, w.productName),
      );
    } catch (_) {
      return null;
    }
  }

  bool _wordsOverlap(String a, String b) {
    final aWords = a.split(RegExp(r'\s+'));
    final bWords = b.split(RegExp(r'\s+'));
    return aWords.any((w) => w.length > 3 && bWords.contains(w));
  }

  @override
  Widget build(BuildContext context) {
    final productName = widget.item.productName ?? 'Unknown Product';
    final unitPrice = widget.item.productPrice ?? 0;
    final lineTotal = widget.item.lineTotal;
    final images = widget.item.productImages;
    final warning = _findWarning();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: AppColors.surface,
                  child: images.isNotEmpty
                      ? CustomNetworkImage(
                          imageUrl: images.first,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                              size: 28),
                        )
                      : const Icon(Icons.shopping_bag_outlined,
                          color: AppColors.primary, size: 28),
                ),
              ),
              const SizedBox(width: 12),

              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$${unitPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.radar,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Detected · Updated ${widget.item.updatedAgo}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Quantity & price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Qty: ${widget.item.quantity}  ·  \$${lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      // Report mismatch action (to be implemented)
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Report mismatch',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Inline Warning Card ─────────────────────────────────
        if (warning != null)
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: _buildWarningCard(warning),
            ),
          ),

        if (widget.showDivider)
          Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.grey.shade200,
              indent: 20,
              endIndent: 20),
      ],
    );
  }

  Widget _buildWarningCard(CartWarning warning) {
    final isCritical = warning.isCritical;
    final cardColor = isCritical
        ? const Color(0xFFFF3B30)
        : const Color(0xFFFF9500);
    final bgColor = isCritical
        ? const Color(0xFFFFF1F0)
        : const Color(0xFFFFF8EE);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCritical ? Icons.dangerous_outlined : Icons.warning_amber_rounded,
            size: 16,
            color: cardColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? 'CRITICAL: ${warning.type.replaceAll('_', ' ').toUpperCase()}' : warning.type.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: cardColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  warning.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

