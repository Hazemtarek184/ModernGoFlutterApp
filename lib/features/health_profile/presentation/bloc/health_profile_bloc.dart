import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/features/health_profile/domain/entities/health_profile.dart';
import 'package:modern_go/features/health_profile/domain/usecases/health_profile_usecases.dart';

// Events
abstract class HealthProfileEvent extends Equatable {
  const HealthProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadHealthProfile extends HealthProfileEvent {}

class CreateProfile extends HealthProfileEvent {
  final HealthProfile profile;

  const CreateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class UpdateProfile extends HealthProfileEvent {
  final HealthProfile profile;

  const UpdateProfile(this.profile);

  @override
  List<Object?> get props => [profile];
}

class DeleteProfile extends HealthProfileEvent {}

// States
abstract class HealthProfileState extends Equatable {
  const HealthProfileState();

  @override
  List<Object?> get props => [];
}

class HealthProfileInitial extends HealthProfileState {}

class HealthProfileLoading extends HealthProfileState {}

class HealthProfileLoaded extends HealthProfileState {
  final HealthProfile profile;

  const HealthProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class HealthProfileNotFound extends HealthProfileState {}

class HealthProfileError extends HealthProfileState {
  final String message;

  const HealthProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class HealthProfileSuccess extends HealthProfileState {
  final String message;
  final HealthProfile? profile;

  const HealthProfileSuccess(this.message, {this.profile});

  @override
  List<Object?> get props => [message, profile];
}

// Bloc
class HealthProfileBloc extends Bloc<HealthProfileEvent, HealthProfileState> {
  final GetHealthProfile getHealthProfile;
  final CreateHealthProfile createHealthProfile;
  final UpdateHealthProfile updateHealthProfile;
  final DeleteHealthProfile deleteHealthProfile;

  HealthProfileBloc({
    required this.getHealthProfile,
    required this.createHealthProfile,
    required this.updateHealthProfile,
    required this.deleteHealthProfile,
  }) : super(HealthProfileInitial()) {
    on<LoadHealthProfile>(_onLoadHealthProfile);
    on<CreateProfile>(_onCreateProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<DeleteProfile>(_onDeleteProfile);
  }

  Future<void> _onLoadHealthProfile(
      LoadHealthProfile event, Emitter<HealthProfileState> emit) async {
    emit(HealthProfileLoading());
    final result = await getHealthProfile();
    result.fold(
      (failure) {
        // We broadly treat ANY failure on initial load as NotFound 
        // to ensure the user is seamlessly sent to the creation screen.
        emit(HealthProfileNotFound());
      },
      (profile) => emit(HealthProfileLoaded(profile)),
    );
  }

  Future<void> _onCreateProfile(
      CreateProfile event, Emitter<HealthProfileState> emit) async {
    emit(HealthProfileLoading());
    final result = await createHealthProfile(event.profile);
    result.fold(
      (failure) => emit(HealthProfileError(failure.message)),
      (profile) => emit(HealthProfileSuccess('Profile created successfully', profile: profile)),
    );
  }

  Future<void> _onUpdateProfile(
      UpdateProfile event, Emitter<HealthProfileState> emit) async {
    emit(HealthProfileLoading());
    final result = await updateHealthProfile(event.profile);
    result.fold(
      (failure) => emit(HealthProfileError(failure.message)),
      (profile) => emit(HealthProfileSuccess('Profile updated successfully', profile: profile)),
    );
  }

  Future<void> _onDeleteProfile(
      DeleteProfile event, Emitter<HealthProfileState> emit) async {
    emit(HealthProfileLoading());
    final result = await deleteHealthProfile();
    result.fold(
      (failure) => emit(HealthProfileError(failure.message)),
      (_) => const HealthProfileSuccess('Profile deleted successfully'),
    );
  }
}
