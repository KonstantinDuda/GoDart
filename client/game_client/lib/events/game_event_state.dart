import 'package:equatable/equatable.dart';

class GameEvent extends Equatable {
  const GameEvent();

  @override
  List<Object> get props => [];
}

class GameEventConnection extends GameEvent {}

class GameEventTap extends GameEvent {
  final String tile;
  const GameEventTap(this.tile);

  @override
  List<Object> get props => [tile];
}

class GameEventClose extends GameEvent {}

//

class GameState extends Equatable {
  const GameState();

  @override
  List<Object> get props => [];
}

class GameStateAwait extends GameState {}

class GameStateSuccess extends GameState {}

class GameStateFail extends GameState {}
