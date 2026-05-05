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
  }

  Future<void> _onCheckToken(
      CheckTokenRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final token = await storage.read(key: 'token');
    debugPrint(
        '[Auth] Stored token: ${token != null ? "${token.substring(0, 20)}..." : "NULL"}');

    if (token == null) {
      debugPrint('[Auth] No token found → login required');
      emit(AuthUnauthenticated());
      return;
    }

    debugPrint('[Auth] Token found, validating with /customers/me ...');
    final result = await authRepository.validateToken();
    result.fold(
      (failure) {
        debugPrint('[Auth] ❌ Token validation failed: ${failure.message}');
        // Only clear token for auth errors, NOT network errors
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
            '[Auth] ✅ Token valid → auto-login as ${customer.firstName}');
        emit(AuthSuccess(customer));
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
          emit(AuthSuccess(response.customer));
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
          emit(AuthSuccess(response.customer));
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
    // We emit AuthLoading but want to keep the current user in state ideally.
    // However, AuthLoading clears the user unless it's a specific UpdateLoading state.
    // For simplicity, we just use AuthLoading and then re-emit AuthSuccess.
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
    // Current customer might be lost during AuthLoading unless preserved.
    // We can fetch it from current state or assume UI handles it.
    // For simplicity since we just want to update password, we'll try to preserve it if possible:
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
          // Revert to success to allow user to retry without login requirement
          // emit(AuthSuccess(currentCustomer));
          // usually UI handles error dialog
        }
      },
      (successMessage) {
        if (currentCustomer != null) {
          emit(AuthSuccess(currentCustomer));
        } else {
          // Fallback if state was lost
          add(CheckTokenRequested());
        }
      },
    );
  }
}
