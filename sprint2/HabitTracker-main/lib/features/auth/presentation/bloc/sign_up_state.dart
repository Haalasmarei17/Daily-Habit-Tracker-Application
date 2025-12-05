import 'package:equatable/equatable.dart';

abstract class SignUpState extends Equatable {
  const SignUpState();

  @override
  List<Object?> get props => [];
}

class SignUpInitial extends SignUpState {
  const SignUpInitial();
}

class SignUpLoading extends SignUpState {
  const SignUpLoading();
}

class SignUpSuccess extends SignUpState {
  final String message;

  const SignUpSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class SignUpFailure extends SignUpState {
  final String error;

  const SignUpFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class SocialSignUpLoading extends SignUpState {
  final String provider;

  const SocialSignUpLoading({required this.provider});

  @override
  List<Object?> get props => [provider];
}
