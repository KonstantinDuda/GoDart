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
        title: Text("Гра в хрестики-нулики"),
      ),
      body: Center(
        child: SizedBox(
          width: 300,
          height: 350,
          child: BlocBuilder<GameBloc, GameState>(
            builder: (context, state) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  //const Text('Push the button to play:'),
                  if (state is GameLoaded && state.winner.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          state.winner == "Draw"
                              ? "Нічия!"
                              : "Переможець: ${state.winner}",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ),
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: GridView.count(
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
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.read<GameBloc>().add(NewGameRequested());
        },
        backgroundColor: Colors.lightBlue,
        foregroundColor: Colors.black,
        tooltip: 'New Game',
        label: const Text("Нова гра", style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
