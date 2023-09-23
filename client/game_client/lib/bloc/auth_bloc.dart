import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../events/auth_event_state.dart';
import 'package:http/http.dart' as http;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthAwaitState()) {
    on<AuthInEvent>(_authIn);
    on<AuthRegistrationEvent>(_registration);
    on<AuthFailEvent>(_fail);
  }

  _authIn(AuthInEvent event, Emitter emit) async {
    print(
        "Auth In Event from AuthBloc. Login: ${event.login} Password: ${event.password}");

    var data = {'name': event.login, 'password': event.password};
    var myBody = json.encode(data);
    if (event.login != '' && event.password != '') {
      print('loginText == ${event.login} && passwordText == ${event.password}');
      var url = Uri.parse('http://localhost:10000/in');
      var response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: myBody);
      /*toJson());*/ /*{'name': loginText, 'password': passwordText});*/
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      //print(await http.read(url));
      print(await http.get(url)); // Uri.https('example.com', 'foobar.txt')));
    }
    /*if (event.login == '') {
      setState(() {
        loginText += '!';
      });
    }
    if (event.password == '') {
      setState(() {
        passwordText += '!';
      });
    }*/

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
