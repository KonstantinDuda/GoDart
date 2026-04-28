import 'dart:async';
import 'dart:convert';
//import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'event_state/game_es.dart';

class GameBloc extends Bloc<GameEvent, GameState> {
  late WebSocketChannel channel;
  var gameplayState = GameplayEnum.twoPlonePC;
  var localBoard = List<String>.filled(9, "");
  var localTurn = "X";
  var localWinner = "";
  var currentTurn = "";

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

    if (gameplayState != GameplayEnum.playOnline) {
      print("Not connecting to server, gameplay is not online. Resetting local game state.");
      emit(GameLoaded(List.from(localBoard), localWinner, gameplayState));
    } else {
      try {
        channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/ws'));

        await channel.ready.timeout(const Duration(seconds: 5));

        channel.stream.listen((message) {
          final data = jsonDecode(message);
          print("Received message from server: $data");
          if(data.containsKey("status")) {
            gameplayState = GameplayEnum.playOnline;
            if(data["status"] == "waiting") {
            print("Waiting for opponent...");
            //emit(GameLoaded(List.from(localBoard), "Очікування суперника...", gameplayState));
            add(GameUpdateReceived(List.from(localBoard), "Очікування суперника..."));
            //return;
            } else if(data["status"] == "started") {

              localBoard = List<String>.from(data["board"]);
              currentTurn = data["turn"];
              localTurn = data["symbol"] ?? localTurn;
              print("Game started! Your symbol: $localTurn");

              if(data.containsKey("winner")) {
                localWinner = data["winner"];
                if(localWinner != "" && localWinner != "Draw") {
                print("Game ended. Winner: $localWinner");
                add(GameUpdateReceived(List.from(localBoard), "Гра завершена! Ваш символ: $localTurn. Переможець: $localWinner"));
                return;
                } else if(localWinner == "Draw") {
                  print("Game ended in a draw.");
                  add(GameUpdateReceived(List.from(localBoard), localWinner));
                  return;
                }
              }
              print('winner != "" && winner != "Draw". localBoard: $localBoard');
              add(GameUpdateReceived(List.from(localBoard), "Ваш символ: $localTurn. Хід: $currentTurn"));
              //return;
            }
          }
        });

        // if (channel.closeCode == null) {
        //   channel.sink.add(jsonEncode({"new_game": 1}));
        // } else {
        //   print("WebSocket channel is not initialized");
        //   emit(GameError("Помилка з'єднання з сервером", gameplayState));
        // }
      // } on TimeoutException {
      //   print("Connection timeout");
      //   emit(GameError("Не вдалося підключитись: таймаут", gameplayState));
      } on WebSocketChannelException catch (e) {
        print("Socket error: $e");
        emit(
          GameError("Сервер недоступний або порт закритий: $e", gameplayState),
        );
      } catch (e) {
        print("Unexpected error: $e");
        emit(GameError("Не вдалося підключитись", gameplayState));
        add(GameUpdateReceived(List.from(localBoard), ""));
      }
    }
  }

  _update(GameUpdateReceived event, Emitter<GameState> emit) /*async*/ {
    emit(GameLoaded(event.field, event.winner, gameplayState));
  }

  _tap(GameCellTapped event, Emitter<GameState> emit) async {
    //var draw = false;
print("Cell tapped: ${event.index}, gameplay: $gameplayState, current turn: $currentTurn, local turn: $localTurn, local winner: $localWinner");

    if (gameplayState != GameplayEnum.playOnline && 
    (localBoard[event.index] != "" || localWinner != "")) {
      print("Cell already occupied or game over");
      return;
    } else if (gameplayState == GameplayEnum.playOnline && currentTurn != localTurn) {
      print("It's not your turn. Current turn: $currentTurn, your symbol: $localTurn");
      add(GameUpdateReceived(List.from(localBoard), "Очікування ходу суперника..."));
      return;
    } else if(gameplayState == GameplayEnum.playOnline && currentTurn == localTurn) {
      channel.sink.add(jsonEncode({"index": event.index}));
      print("Sent move to server: ${event.index}");
      return;
    }

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
          localWinner = localTurn;
          return localTurn;
        }
      }

      if (localBoard.contains("")) {
        isFull = false;
      }

      if (isFull) {
        localWinner = "Draw";
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
          print("At least one winning pattern is still possible: $p");
          canAnyoneWin = true;
          break;
        } else {
          canAnyoneWin = false;
        }
      }

      if (canAnyoneWin == false) {
        print("It's a draw!");
        localWinner = "Draw";
        return "Draw";
      }
      return "";
    }

    winnerDrawCheck(bool isLocalTurnChange) {
      var winner = checkWinner();
      if (winner != "") {
        print("Winner: $winner");
        emit(GameLoaded(localBoard, winner, gameplayState));
        return winner;
      } else {
        // print("No winner yet");
        var check = checkDraw();
        if (check == "Draw") {
          print("It's a draw!");
          emit(GameLoaded(List.from(localBoard), "Draw", gameplayState));
          return "Draw";
        } else {
          // print("Switching turn");
          if (isLocalTurnChange) {
            localTurn = localTurn == "X" ? "O" : "X";
          }
          emit(GameLoaded(List.from(localBoard), "", gameplayState));
        }
      }
      return "";
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
      localBoard[event.index] = "X";
      var wd = winnerDrawCheck(false);
      print("tap. WinnerDrawCheck done, winner/draw: $wd");
      if (wd != "") {
        return;
      }
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
      } else if (stepCounter == 6 &&
          localBoard[4] == "X" &&
          localBoard[8] == "X") {
        localBoard[2] = "O";
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
      print("tap. WinnerDrawCheck done after AI move, winner/draw: $wd");

      localTurn = "X";

      //emit(GameLoaded(List.from(localBoard), "", gameplayState));
    }
  }

  _newGame(NewGameRequested event, Emitter<GameState> emit) /*async*/ {
    if (gameplayState == GameplayEnum.playOnline) {
      channel.sink.add(jsonEncode({"new_game": 1}));
    } else {
      localBoard = List<String>.filled(9, "");
      localTurn = "X";
      localWinner = "";
      emit(GameLoaded(List.from(localBoard), "", gameplayState));
    }
  }

  _changeGameplay(ChangeGameplay event, Emitter<GameState> emit) /*async*/ {
    gameplayState = event.gameplay;
    print("Gameplay changed to: $gameplayState");
    if (gameplayState != GameplayEnum.playOnline) {
      localBoard = List<String>.filled(9, "");
      localTurn = "X";
      localWinner = "";
      emit(GameLoaded(List.from(localBoard), "", gameplayState));
    } else {
      add(GameConnectToServer());
      // try {
      //   if (channel.closeCode == null) {
      //     channel.sink.add(jsonEncode({"new_game": 1}));
      //   } else {
      //     print("WebSocket channel is not initialized");
      //     emit(GameError("Помилка з'єднання з сервером", gameplayState));
      //   }
      // } on WebSocketChannelException catch (e) {
      //   print("Socket error: $e");
      //   emit(
      //     GameError("Сервер недоступний або порт закритий: $e", gameplayState),
      //   );
      // } catch (e) {
      //   print("Unexpected error: $e");
      //   emit(GameError("Не вдалося підключитись", gameplayState));
      //   add(GameUpdateReceived(List.from(localBoard), ""));
      // }
    }
  }

  @override
  Future<void> close() {
    channel.sink.close();
    return super.close();
  }
}
