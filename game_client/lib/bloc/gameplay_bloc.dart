import 'package:flutter_bloc/flutter_bloc.dart';

import 'event_state/gameplay_es.dart';

class GameplayBloc extends Bloc<GameplayEvent, GameplayState> {
  GameplayBloc() : super(TwoPlayersOnOneDevice()) {
    on<TwoPlayersOnOneDeviceEvent>((event, emit) => emit(TwoPlayersOnOneDevice()));
    on<PlayWithComputerEvent>((event, emit) => emit(PlayWithComputer()));
    on<PlayOnlineEvent>((event, emit) => emit(PlayOnline()));
    on<CellTapped>(_cellTapped);
  }

  _cellTapped(CellTapped event, Emitter<GameplayState> emit) {
    var board = List<String>.filled(9, ""); 

    var winPatterns = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6]
    ];

    if (state is TwoPlayersOnOneDevice) {
      // Handle local game logic for two players on one device
    } else if (state is PlayWithComputer) {
      // Handle game logic for playing with computer
    }
  }
}