import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/auth/domain/entities/customer.dart';
import 'package:modern_go/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:modern_go/main_navigation.dart';

class VerificationPhotoPage extends StatefulWidget {
  final Customer customer;

  const VerificationPhotoPage({super.key, required this.customer});

  @override
  State<VerificationPhotoPage> createState() => _VerificationPhotoPageState();
}

class _VerificationPhotoPageState extends State<VerificationPhotoPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _submitPhoto() {
    if (_imageFile == null) return;
    context.read<AuthBloc>().add(
          VerifyPhotoRequested(
            customerId: widget.customer.id,
            photoPath: _imageFile!.path,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Prevent backing out of this mandatory step
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is VerifyPhotoFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is VerifyPhotoMismatch) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.reason),
                  backgroundColor: Colors.deepOrange,
                  duration: const Duration(seconds: 5),
                  action: SnackBarAction(
                    label: 'Retake',
                    textColor: Colors.white,
                    onPressed: _takePhoto,
                  ),
                ),
              );
            } else if (state is AuthSuccess) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const MainNavigation()),
              );
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const Text(
                    'Live Photo',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Please take a live photo of yourself for AI-based identity verification. This is required before proceeding.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: GestureDetector(
                      onTap: _takePhoto,
                      child: Container(
                        width: 250,
                        height: 300,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(40),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: _imageFile == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    size: 80,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tap to open camera',
                                    style: TextStyle(
                                      color: AppColors.darkGreen.withOpacity(0.7),
                                      fontWeight: FontWeight.w600,
                                   ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (_imageFile != null) ...[
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(Icons.refresh, color: AppColors.darkGreen),
                      label: const Text(
                        'Retake Photo',
                        style: TextStyle(color: AppColors.darkGreen),
                      ),
                    ),
                  ],
                  const Spacer(),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is VerifyPhotoLoading;
                      return ElevatedButton(
                        onPressed: (_imageFile == null || isLoading)
                            ? null
                            : _submitPhoto,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          disabledBackgroundColor: AppColors.surface,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Verify Now',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
