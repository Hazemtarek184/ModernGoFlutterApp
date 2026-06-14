import 'package:dartz/dartz.dart';
import 'package:modern_go/core/error/failures.dart';
import 'package:modern_go/features/health_profile/domain/entities/health_profile.dart';
import 'package:modern_go/features/health_profile/domain/repositories/health_profile_repository.dart';

class GetHealthProfile {
  final HealthProfileRepository repository;

  GetHealthProfile(this.repository);

  Future<Either<Failure, HealthProfile>> call() async {
    return await repository.getHealthProfile();
  }
}

class CreateHealthProfile {
  final HealthProfileRepository repository;

  CreateHealthProfile(this.repository);

  Future<Either<Failure, HealthProfile>> call(HealthProfile profile) async {
    return await repository.createHealthProfile(profile);
  }
}

class UpdateHealthProfile {
  final HealthProfileRepository repository;

  UpdateHealthProfile(this.repository);

  Future<Either<Failure, HealthProfile>> call(HealthProfile profile) async {
    return await repository.updateHealthProfile(profile);
  }
}

class DeleteHealthProfile {
  final HealthProfileRepository repository;

  DeleteHealthProfile(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.deleteHealthProfile();
  }
}
