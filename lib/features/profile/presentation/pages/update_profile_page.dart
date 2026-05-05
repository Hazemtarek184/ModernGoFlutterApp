import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/auth/domain/entities/customer.dart';
import 'package:modern_go/features/auth/presentation/bloc/auth_bloc.dart';

class UpdateProfilePage extends StatefulWidget {
  final Customer customer;
  const UpdateProfilePage({super.key, required this.customer});

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneCtrl;
  late TextEditingController _streetCtrl;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController(text: widget.customer.phone);
    _firstNameCtrl = TextEditingController(text: widget.customer.firstName);
    _lastNameCtrl = TextEditingController(text: widget.customer.lastName);
    _streetCtrl =
        TextEditingController(text: widget.customer.address?.street ?? '');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final updateData = <String, dynamic>{};
      if (_phoneCtrl.text != widget.customer.phone)
        updateData['phone'] = _phoneCtrl.text;
      if (_firstNameCtrl.text != widget.customer.firstName)
        updateData['firstName'] = _firstNameCtrl.text;
      if (_lastNameCtrl.text != widget.customer.lastName)
        updateData['lastName'] = _lastNameCtrl.text;

      // Address update nesting
      if (_streetCtrl.text != (widget.customer.address?.street ?? '')) {
        updateData['address'] = {'street': _streetCtrl.text};
      }

      if (updateData.isNotEmpty) {
        context.read<AuthBloc>().add(
              UpdateProfileRequested(
                customerId: widget.customer.id,
                updateData: updateData,
              ),
            );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes to save')),
        );
      }
    }
  }

  Widget _buildFieldWrapper(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFE8F8E5), // Light green filling inside
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.green),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile updated successfully!')),
            );
            Navigator.pop(context);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8E5), // Outer light green card
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFieldWrapper(
                          'Add phone',
                          TextFormField(
                            controller: _phoneCtrl,
                            decoration: _inputDecoration('+20'),
                            enabled: !isLoading,
                          ),
                        ),
                        _buildFieldWrapper(
                          'Address',
                          TextFormField(
                            controller: _streetCtrl,
                            decoration: _inputDecoration('street no. ,'),
                            enabled: !isLoading,
                          ),
                        ),
                        _buildFieldWrapper(
                          'Change first name',
                          TextFormField(
                            controller: _firstNameCtrl,
                            decoration: _inputDecoration('name'),
                            enabled: !isLoading,
                          ),
                        ),
                        _buildFieldWrapper(
                          'Change last name',
                          TextFormField(
                            controller: _lastNameCtrl,
                            decoration: _inputDecoration('name'),
                            enabled: !isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF5AAB5E), // Match button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save changes',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
