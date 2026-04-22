import 'package:flutter_bloc/flutter_bloc.dart';

import 'event_state/gameplay_es.dart';

class GameplayBloc extends Bloc<GameplayEvent, GameplayState> {
  GameplayBloc() : super(TwoPlayersOnOneDevice()) {
    on<TwoPlayersOnOneDeviceEvent>((event, emit) => emit(TwoPlayersOnOneDevice()));
    on<PlayWithComputerEvent>((event, emit) => emit(PlayWithComputer()));
    on<PlayOnlineEvent>((event, emit) => emit(PlayOnline()));
  }
}