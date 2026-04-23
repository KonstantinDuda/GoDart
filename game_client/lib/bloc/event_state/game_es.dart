import 'package:equatable/equatable.dart';

enum GameplayEnum { twoPlonePC, vsAI, playOnline }

// Events
abstract class GameEvent extends Equatable{}

class GameConnectToServer extends GameEvent {
  @override
  List<Object?> get props => [];
}

class GameCellTapped extends GameEvent {
  final int index;
  GameCellTapped(this.index);

   @override
  List<Object?> get props => [index];
}

class GameUpdateReceived extends GameEvent {
  final List<String> field;
  final String winner;
  GameUpdateReceived(this.field, this.winner);
  
   @override
  List<Object?> get props => [field, winner];
}

class NewGameRequested extends GameEvent {

   @override
  List<Object?> get props => [];
}

class ChangeGameplay extends GameEvent {
  final GameplayEnum gameplay;
  ChangeGameplay(this.gameplay);
  
   @override
  List<Object?> get props => [gameplay];
}

// States
abstract class GameState extends Equatable {}

class GameInitial extends GameState {

   @override
  List<Object?> get props => [];
}

class GameLoading extends GameState {

   @override
  List<Object?> get props => [];
}

class GameLoaded extends GameState {
  final List<String> field;
  final String winner;
  final GameplayEnum gameplay;
  GameLoaded(this.field, this.winner, this.gameplay);
  
   @override
  List<Object?> get props => [field, winner, gameplay];
}

class GameError extends GameState {
  final String message;
  final GameplayEnum gameplay;
  GameError(this.message, this.gameplay);
  
   @override
  List<Object?> get props => [message, gameplay];
}
