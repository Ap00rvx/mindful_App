import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthSignInWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthSignInWithEmail({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthSignUpWithEmail extends AuthEvent {
  final String email;
  final String password;

  const AuthSignUpWithEmail({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthSignInWithGoogle extends AuthEvent {}

class AuthSignInWithGithub extends AuthEvent {}

class AuthSignOut extends AuthEvent {}
