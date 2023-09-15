import 'package:equatable/equatable.dart';

class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthInEvent extends AuthEvent {}

class AuthRegistrationEvent extends AuthEvent {}

class AuthFailEvent extends AuthEvent {}

// States

class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthChackState extends AuthState {}

class AuthSuccessState extends AuthState {}

class AuthFailState extends AuthState {}
