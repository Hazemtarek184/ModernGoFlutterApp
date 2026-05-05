import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:modern_go/core/error/failures.dart';
import 'package:modern_go/features/auth/data/models/customer_model.dart';
import 'package:modern_go/features/auth/domain/repositories/auth_repository.dart';
import 'package:modern_go/features/auth/domain/entities/customer.dart';
import 'package:modern_go/core/api/api_client.dart';
import 'package:modern_go/core/constants/api_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient apiClient;

  AuthRepositoryImpl(this.apiClient);

  @override
  Future<Either<Failure, AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });

      final responseData = response.data['data'];
      late final CustomerModel customer;
      late final String token;

      if (responseData['customer'] is Map &&
          responseData['customer']['customer'] != null) {
        final wrapper = responseData['customer'];
        customer = CustomerModel.fromJson(
            Map<String, dynamic>.from(wrapper['customer'] as Map));
        token = wrapper['token'] as String;
      } else {
        customer = CustomerModel.fromJson(
            Map<String, dynamic>.from(responseData['customer'] as Map));
        token = responseData['token'] as String;
      }

      return Right(AuthResponse(customer: customer, token: token));
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      return Left(const ServerFailure('An unexpected error occurred'));
    }
  }

  @override
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
  }) async {
    try {
      final Map<String, dynamic> data = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'password': password,
        'confirmPassword': confirmPassword,
        if (profilePhotoPath.isNotEmpty)
          'profilePhoto': await MultipartFile.fromFile(
            profilePhotoPath,
            filename: profilePhotoPath.split('/').last,
          ),
      };

      if (street != null) data['address[street]'] = street;
      if (city != null) data['address[city]'] = city;
      if (state != null) data['address[state]'] = state;
      if (postalCode != null) data['address[postalCode]'] = postalCode;
      if (country != null) data['address[country]'] = country;

      final formData = FormData.fromMap(data);
      final response =
          await apiClient.post(ApiConstants.register, data: formData);

      debugPrint('[Register] Raw response: ${response.data}');

      final responseData = response.data['data'];
      debugPrint('[Register] Parsed data: $responseData');

      // Handle both possible response structures:
      // Structure A: { data: { customer: { customer: {...}, token } } }
      // Structure B: { data: { customer: {...}, token } }
      late final CustomerModel customer;
      late final String token;

      if (responseData['customer'] is Map &&
          responseData['customer']['customer'] != null) {
        // Structure A: nested customer wrapper
        final wrapper = responseData['customer'];
        customer = CustomerModel.fromJson(
            Map<String, dynamic>.from(wrapper['customer'] as Map));
        token = wrapper['token'] as String;
      } else {
        // Structure B: flat response
        customer = CustomerModel.fromJson(
            Map<String, dynamic>.from(responseData['customer'] as Map));
        token = responseData['token'] as String;
      }

      debugPrint(
          '[Register] ✅ Parsed customer: ${customer.fullName}, token: ${token.substring(0, 20)}...');

      return Right(AuthResponse(customer: customer, token: token));
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      debugPrint('[Register] ❌ Unexpected error: $e');
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, Customer>> validateToken() async {
    try {
      final response = await apiClient.get(ApiConstants.customerMe);
      final data = response.data['data']['customer'];
      final customer = CustomerModel.fromJson(data);
      return Right(customer);
    } on DioException catch (e) {
      // Any 401 means the token is invalid — redirect to login
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      return Left(const ServerFailure('An unexpected error occurred'));
    }
  }

  String _handleDioError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      final data = e.response!.data;

      // Handle the specific "Validation Error" structure provided by the user
      if (data['message'] == "Validation Error" && data['cause'] != null) {
        final validationErrors = data['cause']['validationErrors'] as List?;
        if (validationErrors != null && validationErrors.isNotEmpty) {
          final issues = validationErrors[0]['issues'] as List?;
          if (issues != null && issues.isNotEmpty) {
            return issues[0]['message'] ?? 'Validation failed';
          }
        }
      }

      // Fallback to general message field
      return data['message'] ?? 'An error occurred';
    }

    // Connection/Timeout errors
    if (e.type == DioExceptionType.connectionTimeout)
      return 'Connection timeout';
    if (e.type == DioExceptionType.receiveTimeout)
      return 'Server is not responding';
    if (e.type == DioExceptionType.connectionError)
      return 'No internet connection';

    return 'Network error: ${e.message}';
  }

  @override
  Future<Either<Failure, Customer>> updateProfile(
    String customerId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final response = await apiClient.patch(
        ApiConstants.customerProfile(customerId),
        data: updateData,
      );
      final data = response.data['data']['customer'] ?? response.data['data'];
      final customer = CustomerModel.fromJson(data);
      return Right(customer);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> updatePassword(
    String customerId,
    String currentPassword,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await apiClient.patch(
        ApiConstants.customerPassword(customerId),
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
      final message =
          response.data['data']['message'] ?? 'Password updated successfully';
      return Right(message);
    } on DioException catch (e) {
      return Left(ServerFailure(_handleDioError(e)));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred: $e'));
    }
  }
}
