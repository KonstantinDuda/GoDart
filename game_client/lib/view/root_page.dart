import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/event_state/game_es.dart';
import '../bloc/game_bloc.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  nucleus(int index, bool right, bool bottom, String text, VoidCallback onTap) {
    // Осередок
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: right == true ? BorderSide(width: 1) : BorderSide.none,
          bottom: bottom == true ? BorderSide(width: 1) : BorderSide.none,
        ),
      ),
      child: TextButton(onPressed: onTap, child: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: Text("Root page"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Push the button to play:'),
            SizedBox(
              width: 200,
              height: 200,
              child: BlocBuilder<GameBloc, GameState>(
                builder: (context, state) {
                  //child:
                  return GridView.count(
                    padding: const EdgeInsets.all(10),
                    crossAxisCount: 3,
                    children: List.generate(9, (index) {
                      return nucleus(
                        index,
                        (index % 3 != 2),
                        (index < 6),
                        (state is GameLoaded) ? state.field[index] : "",
                        () {
                          // Send to server button index
                          context.read<GameBloc>().add(GameCellTapped(index));
                        },
                      );
                    }),
                  );
                },
                /*<Widget>[
                    nucleus(true, true, ""),
                    nucleus(true, true, ""),
                    nucleus(false, true, ""),
                    nucleus(true, true, ""),
                    nucleus(true, true, ""),
                    nucleus(false, true, ""),
                    nucleus(true, false, ""),
                    nucleus(true, false, ""),
                    nucleus(false, false, ""),
                  ],*/
              ),
            ),
          ],
        ),
        /*BlocBuilder<CounterBloc, CounterState>(
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
            ),*/
        //],
        //),
        //);
        /*floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<CounterBloc>().add(CounterIncrementRequested());
        },
        backgroundColor: Colors.lightBlue,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),*/
      ),
    );
  }
}
