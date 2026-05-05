import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/core/constants/api_constants.dart';
import 'package:modern_go/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:modern_go/features/cart/presentation/pages/cart_page.dart';
import 'package:modern_go/features/home/presentation/pages/home_page.dart';
import 'package:modern_go/features/profile/presentation/pages/settings_page.dart';
import 'package:modern_go/features/home/presentation/bloc/home_bloc.dart';
import 'package:modern_go/features/home/presentation/pages/all_stores_page.dart';
import 'package:modern_go/features/payment/presentation/pages/payment_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _connectSocket();
    
    _pages = [
      HomePage(
        onNavigateToStores: () {
          setState(() {
            _currentIndex = 1;
          });
        },
      ),
      BlocBuilder<HomeBloc, HomeState>(
        bloc: GetIt.instance<HomeBloc>(),
        builder: (context, state) {
          if (state.status == HomeStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return AllStoresPage(stores: state.stores);
        },
      ),
      const CartPage(),
      const PaymentPage(),
      const SettingsPage(),
    ];
  }

  /// Connect to the socket server using the stored JWT token.
  /// Called once the user reaches the main navigation (after login + biometric).
  Future<void> _connectSocket() async {
    final storage = GetIt.instance<FlutterSecureStorage>();
    final token = await storage.read(key: 'token');
    if (token != null && mounted) {
      context.read<CartBloc>().add(
            CartConnectRequested(
              serverUrl: ApiConstants.socketUrl,
              jwtToken: token,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.black,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: 'stores',
          ),
          BottomNavigationBarItem(
            icon: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                final count = state.totalItems;
                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.shopping_cart_outlined),
                );
              },
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            label: 'Pay',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
