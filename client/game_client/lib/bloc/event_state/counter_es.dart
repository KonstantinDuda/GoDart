// Events
abstract class CounterEvent {}

class CounterIncrement extends CounterEvent {}

// States
abstract class CounterState {}

class CounterInitial extends CounterState {}

class CounterLoading extends CounterState {}

class CounterLoaded extends CounterState {
  final int value;
  CounterLoaded(this.value);
}

class CounterError extends CounterState {
  final String message;
  CounterError(this.message);
}
