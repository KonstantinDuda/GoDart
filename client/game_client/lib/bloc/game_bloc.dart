import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_client/events/game_event_state.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  GameBloc() : super(GameStateAwait()) {
    on<GameEventConnection>(_connection);
    on<GameEventTap>(_tap);
    on<GameEventClose>(_close);
  }

  _connection(GameEvent event, Emitter emit) {}
  _tap(GameEvent event, Emitter emit) {}
  _close(GameEvent event, Emitter emit) {}
}
