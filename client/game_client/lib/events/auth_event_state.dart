import 'package:equatable/equatable.dart';

class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthInEvent extends AuthEvent {
  final String login;
  final String password;

  const AuthInEvent(this.login, this.password);

  @override
  List<Object> get props => [login, password];
}

class AuthRegistrationEvent extends AuthEvent {}

class AuthFailEvent extends AuthEvent {}

// States

class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthAwaitState extends AuthState {}

class AuthSuccessState extends AuthState {}

class AuthFailState extends AuthState {}
