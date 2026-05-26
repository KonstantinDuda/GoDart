import 'dart:math';

import 'package:flame/events.dart';
//import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/event_state/game_es.dart';
import '../bloc/game_bloc.dart';

// ==========================================
// 3. ІГРОВИЙ РУШІЙ FLAME
// ==========================================

class RootPage extends FlameGame {
  final GameBloc gameBloc;
  // Конструктор гри
  RootPage({required this.gameBloc});

  // Метод onLoad викликається ОДИН раз, коли гра ініціалізується.
  // Тут ми налаштовуємо компоненти та провайдери.
  @override
  Future<void> onLoad() async {
    super.onLoad();

    final boardComponent = BoardComponent();
    final newGameButton = NewGameButton(board: boardComponent, buttonHeight: 50);
    final statusTextComponent = StatusTextComponent(board: boardComponent, textAreaHeight: 40);

    // Додаємо FlameBlocProvider. Він робить наш BLoC доступним
    // для ігрових компонентів.
    await add(
      FlameBlocProvider<GameBloc, GameState>.value(
        value: gameBloc,
        children: [
          boardComponent,
          newGameButton,
          statusTextComponent,
        ],
      ),
    );
  }

  @override
  Color backgroundColor() => const Color.fromARGB(255, 26, 28, 41); // Білий фон для гри
}

class BoardComponent extends PositionComponent
    with
        HasGameReference<RootPage>,
        TapCallbacks,
        FlameBlocReader<GameBloc, GameState>,
        FlameBlocListenable<GameBloc, GameState> {
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    print("BoardComponent resized: $size");

    // 1. Розраховуємо розміри (40% під меню, 60% під ігрову зону)
    double menuWidth = size.x * 0.4;
    double availableWidth = size.x * 0.6;
    double availableHeight = size.y;
    
    double textAreaHeight = size.y * 0.2;
    double buttonNewGameHeight = size.y * 0.2;

    // Квадрат поля з відступами під текст та кнопку початку нової гри
    double boardSize = min(availableWidth, availableHeight) - (textAreaHeight + buttonNewGameHeight) - 60;

    // 2. Рахуємо координати початку поля
    double startX = menuWidth + (availableWidth - boardSize) / 2;
    double startY = (availableHeight - boardSize) / 2;

    // 3. ЗАДАЄМО СТАН КОМПОНЕНТА ТУТ (Один раз, а не кожен кадр)
    position = Vector2(startX, startY);
    this.size = Vector2(boardSize, boardSize);
  }

  List<String> _currentField = List.filled(9, ""); // Стан поля для відображення
  @override
  void onNewState(GameState state) {
    super.onNewState(state);

    // Оновлюємо стан поля, коли отримуємо новий стан гри
    _currentField = (state is GameLoaded) ? state.field : List.filled(9, "");
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x == 0 || size.y == 0) {
      return; // Якщо розмір не встановлено, не малюємо
    }

    // 1. Налаштовуємо пензель для малювання ліній сітки
    final linePaint = Paint()
      ..color =
          const Color.fromARGB(
            255,
            96,
            97,
            63,
          ) // Приємний сіро-синій колір для ліній
      ..strokeWidth =
          5 // Товщина лінії в пікселях
      ..strokeCap = StrokeCap.round; // Закруглені краї ліній

    double width = size.x;
    double height = size.y;
    double cellSize = width / 3;

    // 2. Малюємо лінії сітки відносно координат нашого квадрата
    for (int i = 1; i < 3; i++) {
      // Вертикальні лінії
      canvas.drawLine(
        Offset(i * cellSize, 0),
        Offset(i * cellSize, height),
        linePaint,
      );

      // Горизонтальні лінії
      canvas.drawLine(
        Offset(0, i * cellSize),
        Offset(width, i * cellSize),
        linePaint,
      );
    }

    final xPaint = Paint()
      ..color = Color.fromARGB(255, 235, 94, 85)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final oPaint = Paint()
      ..color = Color.fromARGB(255, 84, 172, 230)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Відступ всередині клітинки, щоб фігурки не торкалися ліній сітки
    double padding = cellSize * 0.2;

    // 3. Малюємо X та O відповідно до стану поля
    for (int i = 0; i < 9; i++) {
      String cellValue = _currentField[i];

      int row = i ~/ 3; // Рядок (0, 1, 2)
      int col = i % 3; // Стовпець (0, 1, 2)

      double left = col * cellSize + padding;
      double top = row * cellSize + padding;
      double right = (col + 1) * cellSize - padding;
      double bottom = (row + 1) * cellSize - padding;

      if (cellValue == "X") {
        // Малюємо X
        canvas.drawLine(Offset(left, top), Offset(right, bottom), xPaint);
        canvas.drawLine(Offset(right, top), Offset(left, bottom), xPaint);
      } else if (cellValue == "O") {
        // Малюємо O
        double centerX = left + (cellSize - padding * 2) / 2;
        double centerY = top + (cellSize - padding * 2) / 2;
        double radius = (cellSize - padding * 2) / 2;

        canvas.drawCircle(Offset(centerX, centerY), radius, oPaint);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // event.localPosition дає нам координату кліку ВІДНОСНО верхнього лівого кута ПОЛЯ (від 0 до boardSize)
    double clickX = event.localPosition.x;
    double clickY = event.localPosition.y;

    // Визначаємо розмір однієї клітинки
    double cellSize = size.x / 3;

    // Вираховуємо індекс стовпчика (X) та рядка (Y)
    // Ділимо координату на розмір клітинки та відкидаємо дробову частину за допомогою toInt()
    // Результат буде від 0 до 2
    int col = (clickX / cellSize).toInt();
    int row = (clickY / cellSize).toInt();

    // Захист від випадкових виходів за межі (наприклад, клік рівно в край лінії)
    col = col.clamp(0, 2);
    row = row.clamp(0, 2);

    int cellIndex = row * 3 + col; // Індекс клітинки від 0 до 8

    // Виводимо в консоль результат для перевірки
    print(
      'Натиснуто клітинку: рядок = $row, стовпчик = $col, індекс = $cellIndex',
    );
    bloc.add(GameCellTapped(cellIndex));
  }
}

class NewGameButton extends PositionComponent
    with HasGameReference<RootPage>, TapCallbacks,
        FlameBlocReader<GameBloc, GameState>{
  final BoardComponent board;
  final double buttonHeight;
  
  NewGameButton({required this.board, required this.buttonHeight});

// Метод onGameResize стежить за тим, щоб кнопка ЗАВЖДИ була строго під полем
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Чекаємо, поки поле прорахує свої розміри
    if (board.size.x == 0) return;

    // Ширина кнопки дорівнюватиме ширині ігрового поля
    double buttonWidth = board.size.x;
    
    // Відступ між полем та кнопкою
    double gap = (size.y * 0.2) / 2; // 20; 

    // Позиція X: така сама, як у поля (вирівняно по лівому краю поля)
    double x = board.position.x;
    // Позиція Y: нижній край поля + відступ
    double y = board.position.y + board.size.y + gap;

    position = Vector2(x, y);
    this.size = Vector2(buttonWidth, buttonHeight);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x == 0 || size.y == 0) {
      return; // Якщо розмір не встановлено, не малюємо
    }

    // Малюємо кнопку "Нова гра"
    final buttonPaint = Paint()
      ..color = const Color.fromARGB(
            255,
            96,
            97,
            63,
          )
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Нова гра',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

final rrect = RRect.fromRectAndRadius(
      size.toRect(), //Rect.fromLTWH(0, 0, buttonWidth, buttonHeight),
      const Radius.circular(12),
    );
    // Малюємо прямокутник кнопки
    canvas.drawRRect(
      rrect,
      buttonPaint,
    );

    // Малюємо текст на кнопці
    double textX = (size.x - textPainter.width) / 2;
    double textY = (size.y - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    bloc.add(NewGameRequested());
    // Тут можна додати логіку для початку нової гри
    print('Натиснуто кнопку "Нова гра"');
  }
}

class StatusTextComponent extends PositionComponent
    with HasGameReference<RootPage>, FlameBlocListenable<GameBloc, GameState> {
  final BoardComponent board;
  final double textAreaHeight;

  //String _currentTurn = 'X';
  String _winner = '';

  StatusTextComponent({required this.board, required this.textAreaHeight});
  
  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if(board.size.x == 0) return;

    double textWidth = board.size.x;
    double x = board.position.x;
    double y = board.position.y - textAreaHeight - 20;

    position = Vector2(x, y);
    this.size = Vector2(textWidth, textAreaHeight);
  }
  
  @override
  void onNewState(GameState state) {
    super.onNewState(state);

  if(state is GameLoaded) {
    print("StatusTextComponent received new GameLoaded state with winner: ${state.winner}");
      _winner = state.winner;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
  
    if (size.x == 0 || size.y == 0) {
      print("render: size is zero, skipping render");
      return; // Якщо розмір не встановлено, не малюємо
    }

    String displayText = _winner;
    Color textColor = Colors.green;

    if (_winner == "Draw") {
      displayText = "Нічия!";
      textColor = Colors.orange;
      //print("rendr: Winner is: $_winner");
    } else if (_winner == "X" || _winner == "O") {
      //print("rendr: Winner is: $_winner");
      displayText = "Переміг гравець: $_winner!";
    } else if (_winner == "new_game_requested") {
      //print("rendr: Winner is: $_winner");
      displayText = "Суперник запросив нову гру. Чекаємо на відповідь...";
      textColor = Colors.blue;
    } else if(_winner.isNotEmpty) {
      //print("rendr: Winner is: $_winner");
      displayText = _winner;
      textColor = Colors.white;
    } else {
      displayText = "";
      //print("Winner is empty");
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x);


    double textX = (size.x - textPainter.width) / 2;
    double textY = (size.y - textPainter.height) / 2;
    textPainter.paint(canvas, Offset(textX, textY));
  }
}

/*class RootPage extends StatelessWidget {
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

  exitOnlineDialog(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Вихід з онлайн гри'),
        content: const Text('Ви впевнені, що хочете вийти з онлайн гри?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Ні'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Так'),
          ),
        ],
      ),
    ) ?? false;

    return shouldExit;
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
          var gameplay = GameplayEnum.twoPlonePC;
          var messageColor = Colors.green;
          var winner = "";

          if (state is GameLoaded) {
            gameplay = state.gameplay;
            if(state.winner.isNotEmpty) {
              messageColor = Colors.green;
              if(state.winner == "Draw") {
                winner = "Нічия!";
                messageColor = Colors.orange;
              } else if(state.winner == "X" || state.winner == "O") {
                winner = "Переміг гравець ${state.winner}!";
              } else if(state.winner == "new_game_requested") {
                return AlertDialog(
                  title: const Text('Нова гра'),
                  content: const Text('Суперник запросив нову гру. Ви хочете почати?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        //Navigator.of(context).pop();
                        context.read<GameBloc>().add(NewGameResponse(false));
                      },
                      child: const Text('Ні'),
                    ),
                    TextButton(
                      onPressed: () {
                        //Navigator.of(context).pop();
                        context.read<GameBloc>().add(NewGameResponse(true));
                      },
                      child: const Text('Так'),
                    ),
                  ],
                );
              }
              else {
                winner = state.winner;
              }
            }
          } else  if(state is GameError) {
            //print("State isn't GameLoaded");
            gameplay = state.gameplay;
            winner = state.message;
            messageColor = Colors.red;
            print(winner);
          }
              return Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () async {
                          if(gameplay == GameplayEnum.playOnline) {
                            final shouldExit = await exitOnlineDialog(context);
                            if (shouldExit) {
                              context.read<GameBloc>().add(
                                ChangeGameplay(GameplayEnum.twoPlonePC),
                              );
                            }
                          } else {
                          context.read<GameBloc>().add(
                            ChangeGameplay(GameplayEnum.twoPlonePC),
                          );
                        }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: gameplay == GameplayEnum.twoPlonePC
                              ? Colors.lightBlue
                              : Colors.grey,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("2 гравці на одному пристрої"),
                      ),
                      TextButton(
                        onPressed: () async {
                          if(gameplay == GameplayEnum.playOnline) {
                            final shouldExit = await exitOnlineDialog(context);
                            if (shouldExit) {
                              context.read<GameBloc>().add(
                                ChangeGameplay(GameplayEnum.vsAI),
                              );
                            }
                          } else {
                          context.read<GameBloc>().add(
                            ChangeGameplay(GameplayEnum.vsAI),
                          );
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: gameplay == GameplayEnum.vsAI
                              ? Colors.lightBlue
                              : Colors.grey,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text("Грати з комп'ютером"),
                      ),
                      TextButton(
                        onPressed: () {
                          context.read<GameBloc>().add(
                            ChangeGameplay(GameplayEnum.playOnline),
                          );
                          
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: gameplay == GameplayEnum.playOnline
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
                        SizedBox(
                          height: 30,
                          child: Text(
                            winner,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              color: messageColor, //Colors.green,
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
            //},
          //);
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
}*/
