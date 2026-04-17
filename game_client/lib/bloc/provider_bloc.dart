import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
class ProviderEvent extends Equatable {
 const ProviderEvent();
  @override
  List<Object?> get props => [];
}

class RootEvent extends ProviderEvent {}

// States
class ProviderState extends Equatable {
  const ProviderState();
  @override
  List<Object?> get props => [];
}

class RootState extends ProviderState {}

class ProviderBloc extends Bloc<ProviderEvent, ProviderState> {
  ProviderBloc() : super(RootState()) {
    on<RootEvent>((event, emit) {
      emit(RootState());
    });
  }
}