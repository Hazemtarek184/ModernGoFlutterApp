import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:modern_go/features/cart/presentation/widgets/live_scan_indicator.dart';
import 'package:modern_go/features/cart/presentation/widgets/empty_cart_view.dart';
import 'package:modern_go/features/cart/presentation/widgets/cart_item_card.dart';
import 'package:modern_go/features/cart/presentation/widgets/checkout_success_view.dart';
import 'package:modern_go/main_navigation.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ── Green Header ───────────────────────────────────────
          _buildHeader(context),

          // ── Body ───────────────────────────────────────────────
          Expanded(
            child: BlocListener<CartBloc, CartState>(
              listenWhen: (previous, current) =>
                  previous.errorMessage != current.errorMessage,
              listener: (context, state) {
                if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.errorMessage!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: BlocBuilder<CartBloc, CartState>(
                builder: (context, state) {
                  final isConnected = state.status == CartStatus.connected;
                  return Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Live Scan indicator
                          LiveScanIndicator(isConnected: isConnected),

                          // Content
                          Expanded(
                            child: state.items.isEmpty
                                ? const EmptyCartView()
                                : _buildCartContent(context, state),
                          ),
                        ],
                      ),
                      if (state.checkoutCompleted)
                        CheckoutSuccessView(
                          onDismiss: () {
                            context.read<CartBloc>().add(CartCheckoutReset());
                            final navState = context.findAncestorStateOfType<MainNavigationState>();
                            navState?.setIndex(0); // Switch tab to Home
                          },
                        ),
                    ],
                  );
                },
            ),
          ),
        ),
      ],
    ),
  );
  }

  /// Green gradient header matching the design
  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child:
                const Icon(Icons.chevron_left, color: Colors.white, size: 28),
          ),
          const Expanded(
            child: Text(
              'Shopping cart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Icon(Icons.shopping_cart_outlined,
              color: Colors.white, size: 26),
        ],
      ),
    );
  }

  /// Cart with items, total, and checkout button
  Widget _buildCartContent(BuildContext context, CartState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Subtitle
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Tracking detected product in cart:',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),

        // ── Health Alert Banner ─────────────────────────────────
        if (state.hasWarnings) _buildHealthAlertBanner(context, state),

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              return CartItemCard(
                item: state.items[index],
                warnings: state.warnings,
                showDivider: index < state.items.length - 1,
              );
            },
          ),
        ),

        // Total + Checkout
        _buildTotalSection(context, state),
      ],
    );
  }

  /// Sticky health alert banner at the top of the cart
  Widget _buildHealthAlertBanner(BuildContext context, CartState state) {
    final isCritical = state.hasCriticalWarnings;
    final bannerColor = isCritical
        ? const Color(0xFFFF3B30)  // vivid red for critical
        : const Color(0xFFFF9500); // vivid orange for severe/moderate
    final bgColor = isCritical
        ? const Color(0xFFFFF1F0)
        : const Color(0xFFFFF8EE);
    final borderColor = isCritical
        ? const Color(0xFFFF3B30).withOpacity(0.4)
        : const Color(0xFFFF9500).withOpacity(0.4);

    final criticalCount = state.warnings.where((w) => w.isCritical).length;
    final totalCount = state.warnings.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bannerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isCritical
                        ? '⚠️ Critical Health Alert'
                        : '⚠️ Health Warning',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalCount issue${totalCount > 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Warning list
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isCritical)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '$criticalCount item${criticalCount > 1 ? 's' : ''} in your cart may be DANGEROUS given your health conditions.',
                      style: TextStyle(
                        color: bannerColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ...state.warnings.take(3).map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        w.isCritical ? Icons.dangerous : Icons.warning_amber,
                        size: 14,
                        color: bannerColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${w.productName}: ${w.message}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
                if (state.warnings.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '+ ${state.warnings.length - 3} more warning${state.warnings.length - 3 > 1 ? 's' : ''}. See items below.',
                      style: TextStyle(
                        fontSize: 11,
                        color: bannerColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Total price row + "Confirm & Checkout" button + footer text
  Widget _buildTotalSection(BuildContext context, CartState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),
              Text(
                '\$${state.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Footer text
          const Text(
            'Cart updates automatically from camera scan.',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 12),

          // Checkout button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                context.read<CartBloc>().add(CartCheckoutRequested());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Confirm & Checkout',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

