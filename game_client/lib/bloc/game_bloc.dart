import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'event_state/game_es.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  late WebSocketChannel channel;

  GameBloc() : super(GameInitial()) {
    on<GameConnectToServer>(_connect);
    on<GameUpdateReceived>(_update);
    on<GameCellTapped>(_increment);
  }

  _connect(GameConnectToServer event, Emitter<GameState> emit) async {
    emit(GameLoading());

    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

      channel.stream.listen((message) {
        final data = jsonDecode(message);
        final board = List<String>.from(data["board"]);
        final winner = (data["winner"] ?? "") as String;
        add(GameUpdateReceived(board, winner));
      });
    } catch (e) {
      emit(GameError("Не вдалося підключитись"));
    }
  }

  _update(GameUpdateReceived event, Emitter<GameState> emit) async {
    emit(GameLoaded(event.field, event.winner));
  }

  _increment(GameCellTapped event, Emitter<GameState> emit) async {
    final map = jsonEncode({"index": event.index});
    channel.sink.add(map);
    // emit(GameLoading());

    // try {
    //   final response = await http.post(
    //     Uri.parse('http://localhost:8080/increment'),
    //   );

    //   if (response.statusCode == 200) {
    //     final data = jsonDecode(response.body);
    //     final newValue = data['count'] as int;
    //     emit(GameLoaded(newValue));
    //   } else {
    //     emit(GameError("Помилка сервера: ${response.statusCode}"));
    //   }
    // } catch (e) {
    //   emit(GameError("Не вдалось з'єднатись з сервером"));
    // }
  }

  @override
  Future<void> close() {
    channel.sink.close();
    return super.close();
  }
}
