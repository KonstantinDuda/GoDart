import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/gameplay_bloc.dart';

import '../bloc/event_state/game_es.dart';
import '../bloc/event_state/gameplay_es.dart';
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
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 50),
            icon: Icon(Icons.refresh),
            onPressed: () {
              context.read<GameBloc>().add(GameConnectToServer());
            },
          ),
        ],
      ),
      body: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          return BlocBuilder<GameplayBloc, GameplayState>(
            builder: (context, gameplayState) {
              return Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          context.read<GameplayBloc>().add(TwoPlayersOnOneDeviceEvent());
                        },
                        style: TextButton.styleFrom(
                          backgroundColor:
                              gameplayState is TwoPlayersOnOneDevice
                              ? Colors.lightBlue
                              : Colors.grey,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("2 гравці на одному пристрої"),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<GameplayBloc>().add(PlayWithComputerEvent());
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: gameplayState is PlayWithComputer
                              ? Colors.lightBlue
                              : Colors.grey,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Грати з комп'ютером"),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<GameplayBloc>().add(PlayOnlineEvent());
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: gameplayState is PlayOnline
                              ? Colors.lightBlue
                              : Colors.grey,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Грати онлайн"),
                      ),
                    ],
                  ),
                  //Center(
                  //child:
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.7,
                    height: 350,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                  context.read<GameBloc>().add(
                                    GameCellTapped(index),
                                  );
                                },
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  //),
                ],
              );
            },
          );
        },
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
