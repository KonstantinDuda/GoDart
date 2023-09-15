import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ProviderEvent extends Equatable {
  ProviderEvent();

  @override
  List<Object> get props => [];
}

class LoadingProviderEvent extends ProviderEvent {}

class AuthProviderEvent extends ProviderEvent {}

class GameProviderEvent extends ProviderEvent {}

/*class CheckEvent extends ProviderEvent {
  final RootTaskNew task;

  CheckEvent(this.task);

  @override
  List<Object> get props => [task];
}*/

//@immutable
class ProviderState extends Equatable {
  ProviderState();

  @override
  List<Object> get props => [];
}

class LoadingProviderState extends ProviderState {}

class AuthProviderState extends ProviderState {}

class GameProviderState extends ProviderState {}

/*class CheckState extends ProviderState {
  final RootTaskNew task;

  CheckState(this.task);

  @override
  List<Object> get props => [task];
}*/

class ProviderBloc extends Bloc<ProviderEvent, ProviderState> {
  //final _database = RootDBProvider();

  ProviderBloc() : super(AuthProviderState()) {
    on<LoadingProviderEvent>((event, emit) => emit(LoadingProviderState()));
    on<AuthProviderEvent>((event, emit) => emit(AuthProviderState()));
    on<GameProviderEvent>((event, emit) => emit(GameProviderState()));
  }
}