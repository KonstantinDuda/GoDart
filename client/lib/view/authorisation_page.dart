import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AuthorisationPage extends StatefulWidget {
  const AuthorisationPage({super.key});

  @override
  State<AuthorisationPage> createState() => _AuthorisationPage();
}

class _AuthorisationPage extends State<AuthorisationPage> {
  String loginText = 'Enter your Login';
  String passwordText = 'Enter your Password';

  checkPost() async {
    /*Map<String, String> toJson() {
      return {
        'name': loginText,
        'password': passwordText,
      };
    }*/
    var data = {'name': loginText, 'password': passwordText};
    var myBody = json.encode(data);
    if (loginText != '' && passwordText != '') {
      print('loginText == $loginText && passwordText == $passwordText');
      var url = Uri.parse(
          'http://localhost:10000/in'); //Uri.https('://localhost:10000', '/in');
      var response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: myBody);
      /*toJson());*/ /*{'name': loginText, 'password': passwordText});*/
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      //print(await http.read(url));
      print(await http.get(url)); // Uri.https('example.com', 'foobar.txt')));
    }
    if (loginText == '') {
      loginText += '!';
    }
    if (passwordText == '') {
      passwordText += '!';
    }
  }

  @override
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
                checkPost();
              },
              child: const Text("Auth.")),
        ],
      )),
    );
  }
}
