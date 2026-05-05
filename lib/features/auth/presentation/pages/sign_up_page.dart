import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:modern_go/features/auth/presentation/pages/biometric_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _pageController = PageController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Step 1 Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+20');
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _postalCodeController = TextEditingController();

  // Step 2 Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _profileImage;
  final _picker = ImagePicker();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const BiometricPage()),
                (route) => false,
              );
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStep1(),
              _buildStep2(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sign Up',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkGreen,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surface,
                  backgroundImage:
                      _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.add_a_photo,
                          size: 32, color: AppColors.primary)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Center(
                child: Text('Profile Photo *',
                    style: TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.bold))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  _buildField(
                      'First name *', 'First name', _firstNameController,
                      fieldName: 'firstName'),
                  _buildField('Last name *', 'Last name', _lastNameController,
                      fieldName: 'lastName'),
                  _buildField('Phone *', '+20', _phoneController,
                      fieldName: 'phone'),
                  _buildField(
                      'Street (optional)', 'Street No.', _streetController,
                      isRequired: false, fieldName: 'street'),
                  _buildField('City (optional)', 'Street', _cityController,
                      isRequired: false, fieldName: 'city'),
                  _buildField(
                      'State (optional)', 'Cairo, Giza etc.', _stateController,
                      isRequired: false, fieldName: 'state'),
                  _buildField('Country (optional)', 'Egypt', _countryController,
                      isRequired: false, fieldName: 'country'),
                  _buildField('Postal code (optional)', 'Postal code',
                      _postalCodeController,
                      isRequired: false, fieldName: 'postalCode'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey1.currentState!.validate()) {
                    if (_profileImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Profile photo is required')));
                      return;
                    }
                    _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut);
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(220, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28))),
                child: const Text('Next',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account?',
                    style: TextStyle(
                        color: AppColors.darkGreen,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sign Up',
                style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGreen)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  _buildField('Email *', 'email', _emailController,
                      fieldName: 'email'),
                  _buildField('Password *', '........', _passwordController,
                      isPassword: true,
                      obscure: _obscurePassword,
                      onToggle: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      fieldName: 'password'),
                  _buildField('Confirm password *', '........',
                      _confirmPasswordController,
                      isPassword: true,
                      obscure: _obscureConfirmPassword,
                      onToggle: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                      fieldName: 'confirmPassword'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : _onSignUpPressed,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(220, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28))),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Sign up',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSignUpPressed() {
    if (_formKey2.currentState!.validate()) {
      context.read<AuthBloc>().add(
            RegisterRequested({
              'firstName': _firstNameController.text,
              'lastName': _lastNameController.text,
              'email': _emailController.text,
              'phone': _phoneController.text,
              'password': _passwordController.text,
              'confirmPassword': _confirmPasswordController.text,
              'street': _streetController.text.isEmpty
                  ? null
                  : _streetController.text,
              'city':
                  _cityController.text.isEmpty ? null : _cityController.text,
              'state':
                  _stateController.text.isEmpty ? null : _stateController.text,
              'postalCode': _postalCodeController.text.isEmpty
                  ? null
                  : _postalCodeController.text,
              'country': _countryController.text.isEmpty
                  ? null
                  : _countryController.text,
              'profilePhotoPath': _profileImage!.path,
            }),
          );
    }
  }

  String? _validateField(String? value, String fieldName,
      {bool isRequired = true}) {
    if (isRequired && (value == null || value.isEmpty)) return 'Required';
    if (!isRequired && (value == null || value.isEmpty)) return null;

    switch (fieldName) {
      case 'firstName':
      case 'lastName':
        if (value!.length < 2 || value.length > 50)
          return '2-50 characters required';
        break;
      case 'email':
        final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
        if (!emailRegex.hasMatch(value!)) return 'Enter a valid email';
        if (value.length > 255) return 'Email is too long';
        break;
      case 'phone':
        final phoneRegex = RegExp(r'^(\+20|0)(10|11|12|15)\d{8}$');
        if (!phoneRegex.hasMatch(value!))
          return 'Egyptian phone: 01X... or +201X...';
        break;
      case 'password':
        if (value!.length < 8 || value.length > 128)
          return '8-128 characters required';
        if (!RegExp(r'[A-Z]').hasMatch(value))
          return 'Must have an uppercase letter';
        if (!RegExp(r'[a-z]').hasMatch(value))
          return 'Must have a lowercase letter';
        if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must have a number';
        break;
      case 'confirmPassword':
        if (value != _passwordController.text) return 'Passwords do not match';
        break;
      case 'street':
      case 'city':
      case 'state':
      case 'country':
        if (value!.length < 2 || value.length > 100)
          return '2-100 characters required';
        break;
      case 'postalCode':
        if (value!.length < 2 || value.length > 20)
          return '2-20 characters required';
        break;
    }
    return null;
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    bool isRequired = true,
    String? fieldName,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkGreen, width: 0.5),
                borderRadius: BorderRadius.circular(12)),
            child: TextFormField(
              controller: controller,
              obscureText: obscure,
              validator: (v) =>
                  _validateField(v, fieldName ?? '', isRequired: isRequired),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey.withOpacity(0.6)),
                filled: true,
                fillColor: AppColors.surface,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                            size: 20),
                        onPressed: onToggle)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
