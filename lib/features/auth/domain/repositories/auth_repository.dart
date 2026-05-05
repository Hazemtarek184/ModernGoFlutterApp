import 'package:dartz/dartz.dart';
import 'package:modern_go/core/error/failures.dart';
import '../entities/customer.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthResponse>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? street,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    required String profilePhotoPath,
  });

  /// Validates the stored JWT token and returns the customer profile.
  /// Used on app launch for auto-login.
  Future<Either<Failure, Customer>> validateToken();

  Future<Either<Failure, Customer>> updateProfile(
    String customerId,
    Map<String, dynamic> updateData,
  );

  Future<Either<Failure, String>> updatePassword(
    String customerId,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  );
}

class AuthResponse {
  final Customer customer;
  final String token;

  AuthResponse({required this.customer, required this.token});
}
