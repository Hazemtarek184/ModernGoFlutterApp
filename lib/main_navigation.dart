import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/core/constants/api_constants.dart';
import 'package:modern_go/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:modern_go/features/cart/presentation/pages/cart_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('Home', style: TextStyle(fontSize: 24))),
    Center(child: Text('Stores', style: TextStyle(fontSize: 24))),
    CartPage(),
    Center(child: Text('Pay', style: TextStyle(fontSize: 24))),
    Center(child: Text('Account', style: TextStyle(fontSize: 24))),
  ];

  @override
  void initState() {
    super.initState();
    _connectSocket();
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
