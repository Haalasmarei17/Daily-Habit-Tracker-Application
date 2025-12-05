import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;

  AuthAuthenticated({required this.userId, required this.email});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});
}

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    // Check if user is already authenticated
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    // TODO: Check shared preferences or secure storage for auth token
    // For now, start with unauthenticated state to show sign-up page
    emit(AuthUnauthenticated());
  }

  Future<void> login({required String email, required String password}) async {
    try {
      emit(AuthLoading());

      // TODO: Implement actual login logic
      await Future.delayed(const Duration(seconds: 1));

      emit(AuthAuthenticated(userId: 'user_123', email: email));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      emit(AuthLoading());

      // TODO: Clear auth token from storage
      // TODO: Call logout API if needed
      await Future.delayed(const Duration(milliseconds: 500));

      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    try {
      emit(AuthLoading());

      // TODO: Implement actual sign up logic
      await Future.delayed(const Duration(seconds: 1));

      emit(AuthAuthenticated(userId: 'user_123', email: email));
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }
}
