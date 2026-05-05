import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/auth/domain/entities/customer.dart';
import 'package:modern_go/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:modern_go/features/profile/presentation/pages/update_profile_page.dart';
import 'package:modern_go/features/profile/presentation/pages/change_password_page.dart';
import 'package:modern_go/features/auth/presentation/pages/login_page.dart'
    as modern_go_login;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthInitial || state is AuthUnauthenticated) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(
                  builder: (_) => const modern_go_login.LoginPage()),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is AuthSuccess) {
            final customer = state.customer;
            return _buildSettingsBody(context, customer);
          }
          return const Center(child: Text('Authentication required.'));
        },
      ),
    );
  }

  Widget _buildSettingsBody(BuildContext context, Customer customer) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildProfilePhoto(customer.profilePhoto),
          const SizedBox(height: 40),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8E5), // Light green card background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.lock_outline, color: Colors.black87),
                  title: const Text('Change Password',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage()),
                    );
                  },
                ),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFD4EAD1)),
                ListTile(
                  leading:
                      const Icon(Icons.edit_document, color: Colors.black87),
                  title: const Text('Update',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              UpdateProfilePage(customer: customer)),
                    );
                  },
                ),
                const Divider(
                    height: 1, thickness: 1, color: Color(0xFFD4EAD1)),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.black87),
                  title: const Text('Log Out',
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  onTap: () {
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto(String? base64Photo) {
    debugPrint(
        "=== Profile Photo: ${base64Photo != null ? 'EXISTS (length: ${base64Photo.length})' : 'NULL'} ===");
    if (base64Photo != null && base64Photo.isNotEmpty) {
      try {
        // Remove data uri prefix if present
        String cleanBase64 = base64Photo;
        if (cleanBase64.contains(',')) {
          cleanBase64 = cleanBase64.split(',').last;
        }
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
        while (cleanBase64.length % 4 != 0) {
          cleanBase64 += '=';
        }
        debugPrint(
            "=== Base64 parsed successfully, passing to Image.memory ===");
        return ClipOval(
          child: Image.memory(
            base64Decode(cleanBase64),
            width: 140,
            height: 140,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint("=== Image.memory ERROR: $error ===");
              return _buildPlaceholder();
            },
          ),
        );
      } catch (e) {
        debugPrint("=== Base64 parsing exception: $e ===");
        return _buildPlaceholder();
      }
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 140,
      height: 140,
      decoration: const BoxDecoration(
        color: Color(0xFF3B2E4D), // Dark suit color from illustration
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        size: 80,
        color: Colors.white,
      ),
    );
  }
}
