/*import 'package:flutter_bloc/flutter_bloc.dart';
import '../events/menu_event_state.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  MenuBloc() : super(const MenuState()) {
    _connection();
    on<MenuEventGame>(_game);
    on<MenuEventGameVsAI>(_gameAI);
  }

  var messages = <String>[];
  var channel =
      WebSocketChannel.connect(Uri.parse('ws://localhost:10000/menu'));

  _connection() {
    print("connection in MenuBloc");
    channel.stream.listen(
        (listenEvent) => (() {
              messages.add(listenEvent);
              print("listenEvent in MenuBloc == $listenEvent");
            }), onError: (error) {
      //emit(GameStateFail());
      return messages.add('Error: $error');
    });
    channel.sink.add("Success connection");
  }

  _game(MenuEventGame event, Emitter emit) {}

  _gameAI(MenuEventGameVsAI event, Emitter emit) {}
}*/
