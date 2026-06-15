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

        // Cart items list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: state.items.length,
            itemBuilder: (context, index) {
              return CartItemCard(
                item: state.items[index],
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
