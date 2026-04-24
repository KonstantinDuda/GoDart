import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'event_state/game_es.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  late WebSocketChannel channel;
  var gameplayState = GameplayEnum.twoPlonePC;
  var localBoard = List<String>.filled(9, "");
  var localTurn = "X";

  GameBloc() : super(GameInitial()) {
    on<GameConnectToServer>(_connect);
    on<GameUpdateReceived>(_update);
    on<GameCellTapped>(_tap);
    on<NewGameRequested>(_newGame);
    on<ChangeGameplay>(_changeGameplay);
  }

  _connect(GameConnectToServer event, Emitter<GameState> emit) async {
    emit(GameLoading());
    print("Connecting to WebSocket server..., gameplay = $gameplayState");

    try {
      channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

      await channel.ready.timeout(const Duration(seconds: 5));

      channel.stream.listen(
        (message) {
          final data = jsonDecode(message);
          final board = List<String>.from(data["board"]);
          final winner = (data["winner"] ?? "") as String;
          add(GameUpdateReceived(board, winner));
        },
        onError: (error) {
          print("WebSocket error: $error");
          emit(GameError("Помилка з'єднання: $error", gameplayState));
        },
        onDone: () {
          print("WebSocket connection closed");
          emit(GameError("З'єднання закрито", gameplayState));
        },
      );
    } on TimeoutException {
      print("Connection timeout");
      emit(GameError("Не вдалося підключитись: таймаут", gameplayState));
    } catch (e) {
      print("Unexpected error: $e");
      emit(GameError("Не вдалося підключитись", gameplayState));
      add(GameUpdateReceived(List.from(localBoard), ""));
    }
  }

  _update(GameUpdateReceived event, Emitter<GameState> emit) async {
    emit(GameLoaded(event.field, event.winner, gameplayState));
  }

  _tap(GameCellTapped event, Emitter<GameState> emit) async {
    var draw = false;

    var winPatterns = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];

    var isFull = true;
    checkWinner() {
      for (var pattern in winPatterns) {
        if (localBoard[pattern[0]] != "" &&
            localBoard[pattern[0]] == localBoard[pattern[1]] &&
            localBoard[pattern[1]] == localBoard[pattern[2]]) {
          return localTurn;
        }
      }

      if (localBoard.contains("")) {
        isFull = false;
      }

      if (isFull) {
        return "Draw";
      }

      return "";
    }

    var canAnyoneWin = false;
    checkDraw() {
      print("Checking for draw...");
      for (var p in winPatterns) {
        bool hasX = false;
        bool hasO = false;
        for (var index in p) {
          if (localBoard[index] == "X") hasX = true;
          if (localBoard[index] == "O") hasO = true;
        }
        if (!(hasX && hasO)) {
          canAnyoneWin = true;
          break;
        }
      }

      if (!canAnyoneWin) {
        return "Draw";
      }
      return "";
    }

    winnerDrawCheck(bool isLocalTurnChange) {
      var winner = checkWinner();
      if (winner != "") {
        // print("Winner: $winner");
        emit(GameLoaded(localBoard, winner, gameplayState));
      } else {
        // print("No winner yet");
        var check = checkDraw();
        if (check == "Draw") {
          print("It's a draw!");
          emit(GameLoaded(List.from(localBoard), "Draw", gameplayState));
        } else {
          // print("Switching turn");
          if (isLocalTurnChange) {
            localTurn = localTurn == "X" ? "O" : "X";
          }
          emit(GameLoaded(List.from(localBoard), "", gameplayState));
        }
      }
    }

    if (gameplayState == GameplayEnum.playOnline) {
      final map = jsonEncode({"index": event.index});
      channel.sink.add(map);
    } else if (gameplayState == GameplayEnum.twoPlonePC) {
      // print("Tapped cell index: ${event.index}, current turn: $localTurn");
      if (localBoard[event.index] != "") {
        print("Cell already occupied");
        return;
      } else {
        localBoard[event.index] = localTurn;
        /*var winner = checkWinner();
        if (winner != "") {
          // print("Winner: $winner");
          emit(GameLoaded(localBoard, winner, gameplayState));
        } else {
          // print("No winner yet");
          var check = checkDraw();
          if (check == "Draw") {
            print("It's a draw!");
            emit(GameLoaded(List.from(localBoard), "Draw", gameplayState));
          } else {
            // print("Switching turn");
            localTurn = localTurn == "X" ? "O" : "X";
            emit(GameLoaded(List.from(localBoard), "", gameplayState));
          }
        }*/
        winnerDrawCheck(true);
      }
    } else {
      // TODO: Implement AI move logic here
      localBoard[event.index] = "X";
      localTurn = "O";
      var stepCounter = 0;
      for (var i = 0; i < localBoard.length; i++) {
        if (localBoard[i] == "") {
          stepCounter++;
        }
      }
      if (stepCounter == 8) {
        if (localBoard[4] == "") {
          localBoard[4] = "O";
        } else {
          localBoard[0] = "O";
        }
      } else {
        canXwin(String symbol) {
          var canIsXwin = false;
          for (var p in winPatterns) {
            int isXcount = 0;
            int emptyCount = 0;
            int emptyIndex = -1;
            for (var index in p) {
              if (localBoard[index] == symbol) isXcount++;
              if (localBoard[index] == "") {
                emptyCount++;
                emptyIndex = index;
              }
            }
            if (isXcount == 2 && emptyCount == 1) {
              localBoard[emptyIndex] = "O";
              return true;
            }
          }
          return canIsXwin;
        }

        var canAiWin = canXwin("O");
        if (!canAiWin) {
          var canPlayerWin = canXwin("X");
          if (!canPlayerWin) {
            var emptyCells = <int>[];
            for (var i = 0; i < localBoard.length; i++) {
              if (localBoard[i] == "") {
                emptyCells.add(i);
              }
            }
            if (emptyCells.isNotEmpty) {
              for (int index in emptyCells) {
                var isStepDone = false;
                for (var p in winPatterns) {
                  if (p.contains(index)) {
                    localBoard[index] = "O";
                    isStepDone = true;
                    break;
                  }
                }
                if (isStepDone) {
                  break;
                }
              }
            }
          }
        }
      }

      winnerDrawCheck(false);
      localTurn = "X";

      //emit(GameLoaded(List.from(localBoard), "", gameplayState));
    }
  }

  _newGame(NewGameRequested event, Emitter<GameState> emit) async {
    if (gameplayState == GameplayEnum.playOnline) {
      channel.sink.add(jsonEncode({"new_game": 1}));
    } else {
      localBoard = List<String>.filled(9, "");
      localTurn = "X";
      emit(GameLoaded(List.from(localBoard), "", gameplayState));
    }
  }

  _changeGameplay(ChangeGameplay event, Emitter<GameState> emit) async {
    gameplayState = event.gameplay;
    print("Gameplay changed to: $gameplayState");
    localBoard = List<String>.filled(9, "");
    if (gameplayState != GameplayEnum.playOnline) {
      emit(GameLoaded(List.from(localBoard), "", gameplayState));
    } else {
      if(channel.closeCode != null) {
      channel.sink.add(jsonEncode({"new_game": 1}));
      } else {
        print("WebSocket channel is not initialized");
        emit(GameError("Помилка з'єднання з сервером", gameplayState));
      }


    }
  }

  @override
  Future<void> close() {
    channel.sink.close();
    return super.close();
  }
}
