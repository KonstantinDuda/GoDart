// Events
abstract class GameEvent {}

//class GameIncrement extends GameEvent {}
class GameConnectToServer extends GameEvent {}

class GameCellTapped extends GameEvent {
  final int index;
  GameCellTapped(this.index);
}

class GameUpdateReceived extends GameEvent {
  final List<String> field;
  final String winner;
  GameUpdateReceived(this.field, this.winner);
}

class NewGameRequested extends GameEvent {}

// States
abstract class GameState {}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final List<String> field;
  final String winner;
  GameLoaded(this.field, this.winner);
}

class GameError extends GameState {
  final String message;
  GameError(this.message);
}
