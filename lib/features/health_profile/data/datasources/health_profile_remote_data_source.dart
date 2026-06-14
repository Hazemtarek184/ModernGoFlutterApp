import 'package:dio/dio.dart';
import 'package:modern_go/core/api/api_client.dart';
import 'package:modern_go/core/constants/api_constants.dart';
import 'package:modern_go/features/health_profile/data/models/health_profile_model.dart';

abstract class HealthProfileRemoteDataSource {
  Future<HealthProfileModel> createHealthProfile(HealthProfileModel profile);
  Future<HealthProfileModel> getHealthProfile();
  Future<HealthProfileModel> updateHealthProfile(HealthProfileModel profile);
  Future<void> deleteHealthProfile();
}

class HealthProfileRemoteDataSourceImpl implements HealthProfileRemoteDataSource {
  final ApiClient apiClient;

  HealthProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<HealthProfileModel> createHealthProfile(HealthProfileModel profile) async {
    try {
      final response = await apiClient.post(
        ApiConstants.healthProfiles,
        data: profile.toJson(),
      );
      return HealthProfileModel.fromJson(response.data['data']['profile'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<HealthProfileModel> getHealthProfile() async {
    try {
      final response = await apiClient.get(ApiConstants.healthProfileMe);
      return HealthProfileModel.fromJson(response.data['data']['profile'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<HealthProfileModel> updateHealthProfile(HealthProfileModel profile) async {
    try {
      final response = await apiClient.patch(
        ApiConstants.healthProfileMe,
        data: profile.toJson(),
      );
      return HealthProfileModel.fromJson(response.data['data']['profile'] as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteHealthProfile() async {
    try {
      await apiClient.delete(ApiConstants.healthProfileMe);
    } catch (e) {
      rethrow;
    }
  }
}
