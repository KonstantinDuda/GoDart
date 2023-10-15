import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_client/events/game_event_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/*class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(GameStateAwait()) {
    _connection();
    //on<GameEventConnection>(_connection);
    on<GameEventTap>(_tap);
    on<GameEventClose>(_close);
  }
  var messages = <String>[];
  var channel = WebSocketChannel.connect(Uri.parse('ws://localhost:10000/ws'));

  _connection(/*GameEvent event, Emitter emit*/) {
    //messages = <String>[];
    //channel = WebSocketChannel.connect(Uri.parse('ws://localhost:10000/ws'));
    print("connection in GameBloc");
    channel.stream.listen(
        (listenEvent) => (() {
              messages.add(listenEvent);
              print("listenEvent in GameBloc == $listenEvent");
            }), onError: (error) {
      //emit(GameStateFail());
      return messages.add('Error: $error');
    });
    channel.sink.add("Success connection");

    //emit(GameStateSuccess());
  }

  _tap(GameEventTap event, Emitter emit) {
    print("_tap in GameBloc on ${event.tile}");
    channel.sink.add(event.tile);
    emit(GameStateSuccess());
  }

  _close(GameEventClose event, Emitter emit) {}
}*/

class GameBloc extends Bloc<GameEvent, List<int>> {
  GameBloc() : super([0, 0, 0, 0, 0, 0, 0, 0, 0]) {
    _connection();
    on<GameEventTap>(_tap);
    on<GameEventClose>(_close);
  }
  List<int> list = [];
  var messages = <String>[];
  var channel = WebSocketChannel.connect(Uri.parse('ws://localhost:10000/ws'));

  _connection() {
    print("connection in GameBloc");
    channel.stream.listen(
        (listenEvent) => (() {
              messages.add(listenEvent);
              print("listenEvent in GameBloc == $listenEvent");
            }), onError: (error) {
      //emit(GameStateFail());
      return messages.add('Error: $error');
    });
    channel.sink.add("Success connection");
  }

  _tap(GameEventTap event, Emitter emit) {
    print("_tap in GameBloc on ${event.tile}");
    channel.sink.add(event.tile);
    //var lastMessage = int.parse(messages.last);
    //print("last message == $lastMessage");
    emit(list);
  }

  _close(GameEventClose event, Emitter emit) {}
}
