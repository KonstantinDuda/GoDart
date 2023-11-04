import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

class ProviderEvent extends Equatable {
  const ProviderEvent();

  @override
  List<Object> get props => [];
}

class LoadingProviderEvent extends ProviderEvent {}

class AuthProviderEvent extends ProviderEvent {}

class WebSocetConnectionEvent extends ProviderEvent {}

class GameProviderEvent extends ProviderEvent {}

/*class CheckEvent extends ProviderEvent {
  final RootTaskNew task;

  CheckEvent(this.task);

  @override
  List<Object> get props => [task];
}*/

//@immutable
class ProviderState extends Equatable {
  const ProviderState();

  @override
  List<Object> get props => [];
}

class LoadingProviderState extends ProviderState {}

class AuthProviderState extends ProviderState {}

class WebSocetConnectionState extends ProviderState {}

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
    //on<LoadingProviderEvent>((event, emit) => emit(LoadingProviderState()));
    on<AuthProviderEvent>((event, emit) => emit(AuthProviderState()));
    on<WebSocetConnectionEvent>(
        (event, emit) => emit(WebSocetConnectionState()));
    on<GameProviderEvent>((event, emit) => emit(GameProviderState()));
  }
}
