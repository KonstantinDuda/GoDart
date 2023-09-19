import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_client/bloc/auth_bloc.dart';
import 'package:game_client/bloc/provider_bloc.dart';
import 'package:game_client/events/auth_event_state.dart';
import 'package:http/http.dart' as http;

class AuthorisationPage extends StatefulWidget {
  const AuthorisationPage({super.key});

  @override
  State<AuthorisationPage> createState() => _AuthorisationPage();
}

class _AuthorisationPage extends State<AuthorisationPage> {
  String loginText = 'Enter your Login';
  String passwordText = 'Enter your Password';

  checkPost(String login, String password, BuildContext context) async {
    /*var data = {'name': login, 'password': password};
    var myBody = json.encode(data);
    if (login != '' && password != '') {
      print('loginText == $login && passwordText == $password');
      var url = Uri.parse('http://localhost:10000/in');
      var response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: myBody);
      /*toJson());*/ /*{'name': loginText, 'password': passwordText});*/
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      //print(await http.read(url));
      print(await http.get(url)); // Uri.https('example.com', 'foobar.txt')));
    }*/

    if (login == '') {
      setState(() {
        loginText += '!';
      });
    }
    if (password == '') {
      setState(() {
        passwordText += '!';
      });
    } else {
      context.read<AuthBloc>().add(AuthInEvent(login, password));
      if (context.read<AuthBloc>().state == AuthSuccessState()) {
        print("context.read<AuthBloc>().state == AuthSuccessState()");
        context.read<ProviderBloc>().add(GameProviderEvent());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String login = '';
    String password = '';
    return BlocBuilder<AuthBloc, AuthState>(builder: ((context, state) {
      return MaterialApp(
        home: Scaffold(
            body: Column(
          children: <Widget>[
            Text(loginText),
            TextField(
              controller: TextEditingController(text: login),
              onChanged: (value) {
                login = value;
              },
            ),
            const Text(""),
            Text(passwordText),
            TextField(
              onChanged: (value) {
                password = value;
              },
              controller: TextEditingController(text: password),
            ),
            TextButton(
                onPressed: () {
                  print(
                      "Button is pressed. Login == $login. Password == $password");
                  checkPost(login, password, context);
                  //context.read<AuthBloc>().add(AuthInEvent(login, password));
                },
                child: const Text("Auth.")),
          ],
        )),
      );
    }));
  }

  /*@override
  Widget build(BuildContext context) {
    String login = '';
    String password = '';
    return MaterialApp(
      home: Scaffold(
          body: Column(
        children: <Widget>[
          Text(loginText),
          TextField(
            controller: TextEditingController(text: login),
          ),
          const Text(""),
          Text(passwordText),
          TextField(
            controller: TextEditingController(text: password),
          ),
          TextButton(
              onPressed: () {
                print("Button is pressed");
                checkPost(login, password);
              },
              child: const Text("Auth.")),
        ],
      )),
    );
  }*/
}
