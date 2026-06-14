import 'package:dartz/dartz.dart';
import 'package:modern_go/core/error/failures.dart';
import 'package:modern_go/features/health_profile/domain/entities/health_profile.dart';

abstract class HealthProfileRepository {
  Future<Either<Failure, HealthProfile>> createHealthProfile(HealthProfile profile);
  Future<Either<Failure, HealthProfile>> getHealthProfile();
  Future<Either<Failure, HealthProfile>> updateHealthProfile(HealthProfile profile);
  Future<Either<Failure, void>> deleteHealthProfile();
}
