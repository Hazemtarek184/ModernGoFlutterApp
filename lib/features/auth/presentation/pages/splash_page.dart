import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:modern_go/features/auth/presentation/pages/login_page.dart';
import 'package:modern_go/features/auth/presentation/pages/biometric_page.dart';

/// Splash screen shown on app launch.
/// Dispatches [CheckTokenRequested] to validate the stored JWT.
/// - Valid token → navigates to BiometricPage (then MainNavigation)
/// - Invalid/missing token → navigates to LoginPage
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Trigger token validation
    context.read<AuthBloc>().add(CheckTokenRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // Token valid — go to biometric then main app
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const BiometricPage()),
          );
        } else if (state is AuthUnauthenticated || state is AuthFailure) {
          // Token invalid or missing — go to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App icon / logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Modern Go',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 40),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Extension to replace the current route entirely (no back button).
extension NavigatorExtension on NavigatorState {
  Future<T?> pushReplacement<T extends Object?>(Route<T> newRoute) {
    return pushAndRemoveUntil(newRoute, (_) => false);
  }
}
