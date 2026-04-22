import 'package:equatable/equatable.dart';

// Events
abstract class GameplayEvent extends Equatable {}

class TwoPlayersOnOneDeviceEvent extends GameplayEvent {
  @override
  List<Object?> get props => throw UnimplementedError();
}
  
class PlayWithComputerEvent extends GameplayEvent {
  @override
  List<Object?> get props => throw UnimplementedError();
}

class PlayOnlineEvent extends GameplayEvent {
  @override
  List<Object?> get props => throw UnimplementedError();
}

// States
abstract class GameplayState extends Equatable {}

class TwoPlayersOnOneDevice extends GameplayState {
  @override
  List<Object?> get props => throw UnimplementedError();
}

class PlayWithComputer extends GameplayState {
  @override
  List<Object?> get props => throw UnimplementedError();
}

class PlayOnline extends GameplayState {
  @override
  List<Object?> get props => throw UnimplementedError();
}