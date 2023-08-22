import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  var screenSize = const Size(700, 700);

  var iconO = Icons.clear_rounded;

  var iconX = Icons.brightness_1_outlined;

  var iconEmpty = Icons.brightness_1;

  var iconStartSize = 0.0;

  var iconFinishSize = 100.0;

  late final WebSocketChannel _channel;
  final _messages = <String>[];
  List<GestureDetector> xoWidgets = [];

  @override
  void initState() {
    _createConnection();
    _myButtoms();
    super.initState();
  }

  void _createConnection() async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:10000/ws'));

    _channel.stream.listen(
        (event) => setState(() {
              _messages.add(event);
              print(event);
            }),
        onError: (error) => setState(() => _messages.add('Error: $error')));

    _channel.sink.add("Success connection");
  }

  _myButtoms() {
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
            var data = json.encode(i.toString());
            print("sink: $data");
            _channel.sink.add(data);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
