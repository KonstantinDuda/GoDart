import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocetConnectionPage extends StatelessWidget {
  WebSocetConnectionPage({super.key}) {
    _createConnection();
  }

  late final WebSocketChannel _channel;
  final _messages = <String>[];

  void _createConnection() async {
    _channel = WebSocketChannel.connect(Uri.parse('ws://localhost:10000/ws'));

    _channel.stream.listen((event) => {_messages.add(event)},
        onError: (error) => _messages.add('Error: $error'));

    _channel.sink.add("Success connection");
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("WSS З'єднання з сервером"));
  }
}
