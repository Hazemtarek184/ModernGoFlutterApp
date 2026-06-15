import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modern_go/core/constants/api_constants.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/auth/presentation/pages/splash_page.dart';
import 'package:modern_go/core/api/api_client.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiController = TextEditingController(text: 'http://10.0.2.2:8000/api');
  final _socketController = TextEditingController(text: 'http://10.0.2.2:3001');

  bool _isLoading = false;

  @override
  void dispose() {
    _apiController.dispose();
    _socketController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final storage = GetIt.instance<FlutterSecureStorage>();
      final apiUrl = _apiController.text.trim();
      final socketUrl = _socketController.text.trim();

      await storage.write(key: 'server_url', value: apiUrl);
      await storage.write(key: 'socket_url', value: socketUrl);

      ApiConstants.baseUrl = apiUrl;
      ApiConstants.socketUrl = socketUrl;

      // In case ApiClient was already instantiated, update it directly too
      if (GetIt.instance.isRegistered<ApiClient>()) {
        try {
          GetIt.instance<ApiClient>().dio.options.baseUrl = apiUrl;
        } catch (e) {
          // Ignore if it wasn't instantiated yet
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SplashPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.dns_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Server Configuration',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please enter your server addresses to continue.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _apiController,
                  decoration: InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'e.g., http://10.0.2.2:8000/api',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.link, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the API URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _socketController,
                  decoration: InputDecoration(
                    labelText: 'Socket URL',
                    hintText: 'e.g., http://10.0.2.2:3001',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    prefixIcon: const Icon(Icons.sensors, color: AppColors.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Socket URL';
                    }
                    if (!value.startsWith('http://') && !value.startsWith('https://')) {
                      return 'Must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveConfig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
