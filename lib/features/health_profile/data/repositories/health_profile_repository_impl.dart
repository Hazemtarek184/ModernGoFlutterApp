import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:modern_go/core/error/failures.dart';
import 'package:modern_go/features/health_profile/data/datasources/health_profile_remote_data_source.dart';
import 'package:modern_go/features/health_profile/data/models/health_profile_model.dart';
import 'package:modern_go/features/health_profile/domain/entities/health_profile.dart';
import 'package:modern_go/features/health_profile/domain/repositories/health_profile_repository.dart';

class HealthProfileRepositoryImpl implements HealthProfileRepository {
  final HealthProfileRemoteDataSource remoteDataSource;

  HealthProfileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, HealthProfile>> createHealthProfile(HealthProfile profile) async {
    try {
      final model = _convertToModel(profile);
      final result = await remoteDataSource.createHealthProfile(model);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? e.message ?? 'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HealthProfile>> getHealthProfile() async {
    try {
      final result = await remoteDataSource.getHealthProfile();
      return Right(result);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Left(ServerFailure('Profile not found'));
      }
      return Left(ServerFailure(e.response?.data['message'] ?? e.message ?? 'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, HealthProfile>> updateHealthProfile(HealthProfile profile) async {
    try {
      final model = _convertToModel(profile);
      final result = await remoteDataSource.updateHealthProfile(model);
      return Right(result);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? e.message ?? 'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHealthProfile() async {
    try {
      await remoteDataSource.deleteHealthProfile();
      return const Right(null);
    } on DioException catch (e) {
      return Left(ServerFailure(e.response?.data['message'] ?? e.message ?? 'Server error'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  HealthProfileModel _convertToModel(HealthProfile profile) {
    if (profile is HealthProfileModel) {
      return profile;
    }
    return HealthProfileModel(
      age: profile.age,
      sex: profile.sex,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      pregnant: profile.pregnant,
      allergies: profile.allergies?.map((e) => AllergyModel(allergen: e.allergen, severity: e.severity)).toList(),
      conditions: profile.conditions?.map((e) => ConditionModel(name: e.name, icd10: e.icd10, severity: e.severity)).toList(),
      medications: profile.medications?.map((e) => MedicationModel(name: e.name, doseMg: e.doseMg, frequencyPerDay: e.frequencyPerDay)).toList(),
      dietaryRestrictions: profile.dietaryRestrictions,
      riskFactors: profile.riskFactors != null ? RiskFactorsModel(
        hypertension: profile.riskFactors!.hypertension,
        kidneyDisease: profile.riskFactors!.kidneyDisease,
        liverDisease: profile.riskFactors!.liverDisease,
      ) : null,
    );
  }
}
