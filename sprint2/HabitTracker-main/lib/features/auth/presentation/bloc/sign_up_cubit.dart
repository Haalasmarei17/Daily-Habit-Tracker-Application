import 'package:flutter_bloc/flutter_bloc.dart';
import 'sign_up_state.dart';
import 'auth_cubit.dart';

class SignUpCubit extends Cubit<SignUpState> {
  final AuthCubit _authCubit;

  SignUpCubit({required AuthCubit authCubit})
    : _authCubit = authCubit,
      super(const SignUpInitial());

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      emit(const SignUpLoading());

      // TODO: Implement actual sign up logic with repository
      await Future.delayed(const Duration(seconds: 2));

      // Authenticate user after successful sign up
      await _authCubit.signUp(email: email, password: password);

      emit(const SignUpSuccess(message: 'Account created successfully!'));
    } catch (e) {
      emit(SignUpFailure(error: e.toString()));
    }
  }

  Future<void> signUpWithGoogle() async {
    try {
      emit(const SocialSignUpLoading(provider: 'Google'));

      // TODO: Implement Google sign in logic
      await Future.delayed(const Duration(seconds: 2));

      // Authenticate user after successful Google sign in
      await _authCubit.login(
        email: 'google_user@example.com',
        password: 'google_auth',
      );

      emit(const SignUpSuccess(message: 'Signed in with Google successfully!'));
    } catch (e) {
      emit(SignUpFailure(error: e.toString()));
    }
  }

  Future<void> signUpWithApple() async {
    try {
      emit(const SocialSignUpLoading(provider: 'Apple'));

      // TODO: Implement Apple sign in logic
      await Future.delayed(const Duration(seconds: 2));

      // Authenticate user after successful Apple sign in
      await _authCubit.login(
        email: 'apple_user@example.com',
        password: 'apple_auth',
      );

      emit(const SignUpSuccess(message: 'Signed in with Apple successfully!'));
    } catch (e) {
      emit(SignUpFailure(error: e.toString()));
    }
  }

  void reset() {
    emit(const SignUpInitial());
  }
}
