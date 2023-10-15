import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_client/bloc/game_bloc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

import '../bloc/provider_bloc.dart';
import '../events/game_event_state.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePage();
}

class _GamePage extends State<GamePage> {
  var screenSize = const Size(700, 700);

  /*var iconO = Icons.clear_rounded;

  var iconX = Icons.brightness_1_outlined;

  var iconEmpty = Icons.brightness_1;

  var iconStartSize = 0.0;

  var iconFinishSize = 100.0;*/

  var iconO = const Icon(Icons.clear_rounded, size: 100);

  var iconX = const Icon(Icons.brightness_1_outlined, size: 100);

  var iconEmpty = const Icon(Icons.brightness_1, size: 0);

  //late final WebSocketChannel _channel;
  late BuildContext localContext;
  //final _messages = <String>[];
  List<GestureDetector> xoWidgets = [];
  //List<int> list = [];

  @override
  void initState() {
    //_createConnection();
    //_myButtoms();
    super.initState();
  }

  /*_createConnection(BuildContext context) async {
    context.read<GameBloc>().add(GameEventConnection());
  }*/
  /*void _createConnection() async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:10000/ws'));

    _channel.stream.listen(
        (event) => setState(() {
              _messages.add(event);
              print(event);
            }),
        onError: (error) => setState(() => _messages.add('Error: $error')));

    _channel.sink.add("Success connection");
  }*/

  /*_myButtoms() {
    for (var i = 0; i < 9; i++) {
      xoWidgets.add(
        GestureDetector(
          child: Container(
            width: 15,
            height: 15,
            color: Colors.blue,
            child: Icon(iconEmpty, size: iconStartSize),
          ),
          onTap: () {
            //var data = i.toString();
            //var data = json.encode(i.toString());
            //print("sink: $data");
            list[i] = 1;

            localContext.read<GameBloc>().add(GameEventTap(list));
            //_channel.sink.add(data);
          },
        ),
      );
    }
  }*/

  _myButtoms(List<int> list) {
    List<Widget> widgets = [];

    _icon(int element) {
      if (element == 0) {
        return iconEmpty;
      } else if (element == 1) {
        return iconX;
      } else {
        return iconO;
      }
    }

    for (var i = 0; i < 9; i++) {
      widgets.add(GestureDetector(
          child: Container(
            width: 15,
            height: 15,
            color: Colors.blue,
            child: _icon(list[i]),
          ),
          onTap: () {
            //list[i] = 1;
            print("Tile == $i");
            localContext.read<GameBloc>().add(GameEventTap(i));
          }));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, List<int>>(builder: ((context, state) {
      localContext = context;
      //list = state;
      //_createConnection(context);
      //if (context.read<GameBloc>().state == GameStateSuccess()) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: GridView.count(
                primary: false,
                padding: const EdgeInsets.all(10),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                crossAxisCount: 3,
                children: _myButtoms(state) //xoWidgets,
                ),
          ),
        ),
      );
    }));
  }

  /*@override
  Widget build(BuildContext context) {
    return BlocBuilder<GameBloc, GameState>(builder: ((context, state) {
      localContext = context;
      //_createConnection(context);
      //if (context.read<GameBloc>().state == GameStateSuccess()) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: GridView.count(
              primary: false,
              padding: const EdgeInsets.all(10),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              crossAxisCount: 3,
              children: xoWidgets,
            ),
          ),
        ),
      );
    }));
  }*/
}
