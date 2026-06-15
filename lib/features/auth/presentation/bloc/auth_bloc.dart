import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:modern_go/features/auth/domain/repositories/auth_repository.dart';
import 'package:modern_go/features/auth/domain/entities/customer.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final Map<String, dynamic> params;
  RegisterRequested(this.params);
  @override
  List<Object?> get props => [params];
}

class LogoutRequested extends AuthEvent {}

class UpdateProfileRequested extends AuthEvent {
  final String customerId;
  final Map<String, dynamic> updateData;
  UpdateProfileRequested({required this.customerId, required this.updateData});
  @override
  List<Object?> get props => [customerId, updateData];
}

class UpdatePasswordRequested extends AuthEvent {
  final String customerId;
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  UpdatePasswordRequested({
    required this.customerId,
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
  @override
  List<Object?> get props =>
      [customerId, currentPassword, newPassword, confirmPassword];
}

class VerifyPhotoRequested extends AuthEvent {
  final String customerId;
  final String photoPath;
  VerifyPhotoRequested({required this.customerId, required this.photoPath});
  @override
  List<Object?> get props => [customerId, photoPath];
}

/// Check if the stored JWT token is still valid (auto-login on app launch).
class CheckTokenRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final Customer customer;
  AuthSuccess(this.customer);
  @override
  List<Object?> get props => [customer];
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthPhotoVerificationRequired extends AuthState {
  final Customer customer;
  AuthPhotoVerificationRequired(this.customer);
  @override
  List<Object?> get props => [customer];
}

class VerifyPhotoLoading extends AuthState {}

class VerifyPhotoFailure extends AuthState {
  final String message;
  VerifyPhotoFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class VerifyPhotoMismatch extends AuthState {
  final String reason;
  final bool canRetry;
  VerifyPhotoMismatch({required this.reason, this.canRetry = true});
  @override
  List<Object?> get props => [reason, canRetry];
}

/// Token is missing or invalid — user must log in.
class AuthUnauthenticated extends AuthState {}

// Bloc
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final FlutterSecureStorage storage;

  AuthBloc({required this.authRepository, required this.storage})
      : super(AuthInitial()) {
    on<CheckTokenRequested>(_onCheckToken);
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<LogoutRequested>(_onLogout);
    on<UpdateProfileRequested>(_onUpdateProfile);
    on<UpdatePasswordRequested>(_onUpdatePassword);
    on<VerifyPhotoRequested>(_onVerifyPhoto);
  }

  Future<void> _onVerifyPhoto(
      VerifyPhotoRequested event, Emitter<AuthState> emit) async {
    Customer? currentCustomer;
    if (state is AuthPhotoVerificationRequired) {
      currentCustomer = (state as AuthPhotoVerificationRequired).customer;
    }

    emit(VerifyPhotoLoading());
    final result = await authRepository.verifyPhoto(
      event.customerId,
      event.photoPath,
    );

    result.fold(
      (failure) {
        emit(VerifyPhotoFailure(failure.message));
        if (currentCustomer != null) {
          emit(AuthPhotoVerificationRequired(currentCustomer));
        }
      },
      (verifyResult) {
        if (currentCustomer == null) return;

        if (verifyResult.matched) {
          emit(AuthSuccess(currentCustomer));
        } else {
          final reason = verifyResult.detail ?? _mapVerificationStatus(verifyResult.status);
          emit(VerifyPhotoMismatch(reason: reason));
          emit(AuthPhotoVerificationRequired(currentCustomer));
        }
      },
    );
  }

  String _mapVerificationStatus(String status) {
    switch (status) {
      case 'face_mismatch':
        return 'Your face does not match your profile photo. Please ensure good lighting and retake.';
      case 'no_face_detected':
        return 'No face detected. Please position your face clearly in the frame and retake.';
      default:
        return 'Verification failed. Please retake your photo.';
    }
  }

  Future<void> _onCheckToken(
      CheckTokenRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final token = await storage.read(key: 'token');
    debugPrint(
        '[Auth] Stored token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');

    if (token == null) {
      debugPrint('[Auth] No token found — login required');
      emit(AuthUnauthenticated());
      return;
    }

    debugPrint('[Auth] Token found, validating with /customers/me ...');
    final result = await authRepository.validateToken();
    result.fold(
      (failure) {
        debugPrint('[Auth] ❌ Token validation failed: ${failure.message}');
        if (failure.message.contains('expired') ||
            failure.message.contains('invalid') ||
            failure.message.contains('no longer exists') ||
            failure.message.contains('No token provided')) {
          storage.delete(key: 'token');
          storage.delete(key: 'customer_id');
        }
        emit(AuthUnauthenticated());
      },
      (customer) {
        debugPrint(
            '[Auth] ✅ Token valid — photo verification required as ${customer.firstName}');
        emit(AuthPhotoVerificationRequired(customer));
      },
    );
  }

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final result = await authRepository.login(
        email: event.email,
        password: event.password,
      );

      await result.fold(
        (failure) async => emit(AuthFailure(failure.message)),
        (response) async {
          await storage.write(key: 'token', value: response.token);
          await storage.write(key: 'customer_id', value: response.customer.id);
          emit(AuthPhotoVerificationRequired(response.customer));
        },
      );
    } catch (e) {
      emit(AuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onRegister(
      RegisterRequested event, Emitter<AuthState> emit) async {
    try {
      emit(AuthLoading());
      final result = await authRepository.register(
        firstName: event.params['firstName'],
        lastName: event.params['lastName'],
        email: event.params['email'],
        phone: event.params['phone'],
        password: event.params['password'],
        confirmPassword: event.params['confirmPassword'],
        street: event.params['street'],
        city: event.params['city'],
        state: event.params['state'],
        postalCode: event.params['postalCode'],
        country: event.params['country'],
        profilePhotoPath: event.params['profilePhotoPath'],
      );

      await result.fold(
        (failure) async => emit(AuthFailure(failure.message)),
        (response) async {
          await storage.write(key: 'token', value: response.token);
          await storage.write(key: 'customer_id', value: response.customer.id);
          emit(AuthPhotoVerificationRequired(response.customer));
        },
      );
    } catch (e) {
      emit(AuthFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    await storage.delete(key: 'token');
    await storage.delete(key: 'customer_id');
    emit(AuthInitial());
  }

  Future<void> _onUpdateProfile(
      UpdateProfileRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result =
        await authRepository.updateProfile(event.customerId, event.updateData);

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (customer) => emit(AuthSuccess(customer)),
    );
  }

  Future<void> _onUpdatePassword(
      UpdatePasswordRequested event, Emitter<AuthState> emit) async {
    Customer? currentCustomer;
    if (state is AuthSuccess) {
      currentCustomer = (state as AuthSuccess).customer;
    }

    emit(AuthLoading());
    final result = await authRepository.updatePassword(
      event.customerId,
      event.currentPassword,
      event.newPassword,
      event.confirmPassword,
    );

    result.fold(
      (failure) {
        emit(AuthFailure(failure.message));
        if (currentCustomer != null) {
        }
      },
      (successMessage) {
        if (currentCustomer != null) {
          emit(AuthSuccess(currentCustomer));
        } else {
          add(CheckTokenRequested());
        }
      },
    );
  }
}
