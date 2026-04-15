import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/event_state/counter_es.dart';
import '../bloc/counter_bloc.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text("Root page"),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.cast_connected),
            iconSize: 48,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            BlocBuilder<CounterBloc, CounterState>(
              builder: (context, state) {
                if (state is CounterInitial) {
                  return const Text("Натисніть'+' щоб змінити значення");
                } else if (state is CounterLoading) {
                  return const CircularProgressIndicator();
                } else if (state is CounterLoaded) {
                  return Text(
                    '${state.value}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                } else if (state is CounterError) {
                  return Text(state.message);
                } else {
                  return const Text("Невідомий стан");
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<CounterBloc>().add(CounterIncrement());
        },
        backgroundColor: Colors.lightBlue,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
