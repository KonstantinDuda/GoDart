import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import './event_state/counter_es.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(CounterInitial()) {
    on<CounterIncrement>(_increment);
  }

  _increment(CounterIncrement event, Emitter<CounterState> emit) async {
    emit(CounterLoading());

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/increment'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newValue = data['count'] as int;
        emit(CounterLoaded(newValue));
      } else {
        emit(CounterError("Помилка сервера: ${response.statusCode}"));
      }
    } catch (e) {
      emit(CounterError("Не вдалось з'єднатись з сервером"));
    }
  }
}
