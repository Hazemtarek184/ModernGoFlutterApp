import 'package:flutter/material.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/home/domain/entities/store_product.dart';
import 'package:modern_go/core/widgets/custom_network_image.dart';

/// Product card for the horizontal "Available Products" list.
class ProductCard extends StatelessWidget {
  final StoreProduct storeProduct;
  final VoidCallback onTap;

  const ProductCard(
      {super.key, required this.storeProduct, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final product = storeProduct.product;
    final hasDiscount = product.discountPercent > 0;
    final images = product.images;

    final originalPrice = storeProduct.price;
    final salePrice = hasDiscount
        ? originalPrice - (originalPrice * (product.discountPercent / 100))
        : originalPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image + discount badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    color: AppColors.surface,
                    child: images.isNotEmpty
                        ? CustomNetworkImage(
                            imageUrl: images.first,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          )
                        : const Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.primary,
                            size: 40,
                          ),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.discountPercent.toInt()}% Off',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasDiscount
                              ? '\$${originalPrice.toStringAsFixed(2)}'
                              : ' ', // Empty space to preserve height
                          style: TextStyle(
                            fontSize: 11,
                            color: hasDiscount
                                ? Colors.grey.shade500
                                : Colors.transparent,
                            decoration: hasDiscount
                                ? TextDecoration.lineThrough
                                : null,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${salePrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 12, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          storeProduct.stock > 0 ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 10,
                            color: storeProduct.stock > 0
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
