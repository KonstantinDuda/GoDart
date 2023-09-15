import 'package:flutter_bloc/flutter_bloc.dart';

import '../events/auth_event_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthChackState()) {
    on<AuthInEvent>(_authIn);
    on<AuthRegistrationEvent>(_registration);
    on<AuthFailEvent>(_fail);
  }

  _authIn(AuthInEvent event, Emitter emit) {
    print("Auth In Event from AuthBloc");
    emit(AuthSuccessState());
  }

  _registration(AuthRegistrationEvent event, Emitter emit) {
    print("Auth Regist...");
    emit(AuthSuccessState());
  }

  _fail(AuthFailEvent event, Emitter emit) {
    print("Auth Fail Event");
    emit(AuthSuccessState());
  }
}
