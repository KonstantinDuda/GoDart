import 'dart:math';

import 'package:flame/events.dart';
//import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/event_state/game_es.dart';
import '../bloc/game_bloc.dart';
import 'menu_component.dart';

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
    final newGameButton = NewGameButton(
      board: boardComponent,
      buttonHeight: 50,
    );
    final statusTextComponent = StatusTextComponent(
      board: boardComponent,
      textAreaHeight: 40,
    );

    final menuComponent = MenuComponent();

    // Додаємо FlameBlocProvider. Він робить наш BLoC доступним
    // для ігрових компонентів.
    await add(
      FlameBlocProvider<GameBloc, GameState>.value(
        value: gameBloc,
        children: [
          boardComponent,
          newGameButton,
          statusTextComponent,
          menuComponent,
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
    double boardSize =
        min(availableWidth, availableHeight) -
        (textAreaHeight + buttonNewGameHeight) -
        60;

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
    with
        HasGameReference<RootPage>,
        TapCallbacks,
        FlameBlocReader<GameBloc, GameState> {
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
      ..color = const Color.fromARGB(255, 96, 97, 63)
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
    canvas.drawRRect(rrect, buttonPaint);

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
  Color _textColor = Colors.green;

  StatusTextComponent({required this.board, required this.textAreaHeight});

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    if (board.size.x == 0) return;
    double textWidth = size.x * 0.65; // board.size.x;

    double menuWidth = size.x * 0.3;
    double availableWidth = size.x * 0.7;

    // double x = board.position.x;
    // double y = board.position.y - textAreaHeight - 20;

    double x = menuWidth + (availableWidth - textWidth) / 2;
    double y = board.position.y - textAreaHeight - 15;

    position = Vector2(x, y);
    this.size = Vector2(textWidth, textAreaHeight);
  }

  @override
  void onNewState(GameState state) {
    super.onNewState(state);

    if (state is GameLoaded) {
      print(
        "StatusTextComponent received new GameLoaded state with winner: ${state.winner}",
      );
      _winner = state.winner;
      if (state.winner == "new_game_requested") {
        _winner = "";
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Перевіряємо, чи оверлей СУДЯЧИ З УСЬОГО ще не відкритий, щоб не дублювати
          if (!game.overlays.isActive('InviteDialog')) {
            game.overlays.add('InviteDialog');
          }
        });
      } else if (_winner == "Draw") {
      _winner = "Нічия!";
      _textColor = Colors.orange;
      //print("rendr: Winner is: $_winner");
    } else if (_winner == "X" || _winner == "O") {
      //print("rendr: Winner is: $_winner");
      _winner = "Переміг гравець: $_winner!";
    } else if (_winner.isNotEmpty) {
      //print("rendr: Winner is: $_winner");
      _winner = _winner;
      _textColor = Colors.white60;
    } else {
      _winner = "";
      //print("Winner is empty");
    }
    } else if (state is GameError) {
      print(
        "StatusTextComponent received new GameError state with message: ${state.message}",
      );
      _winner = state.message;
    } else {
      _winner = '';
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x == 0 || size.y == 0) {
      print("render: size is zero, skipping render");
      return; // Якщо розмір не встановлено, не малюємо
    }

    //String displayText = _winner;
    //Color textColor = Colors.green;

    final textPainter = TextPainter(
      text: TextSpan(
        text: _winner, //displayText,
        style: TextStyle(
          color: _textColor,
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

class OnlineRequestDialog extends StatelessWidget {
  final RootPage game;

  const OnlineRequestDialog({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocBuilder<GameBloc, GameState>(
        builder: (context, state) {
          return Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                38,
                41,
                56,
              ), // Наш фірмовий сіро-синій колір
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color.fromARGB(255, 33, 150, 243),
                width: 2,
              ), // Синя рамка
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Запит на нову гру',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Інший гравець пропонує почати новий раунд. Погодитись?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color.fromARGB(255, 170, 170, 180),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Кнопка Відхилити
                      TextButton(
                        onPressed: () {
                          // 1. Відправляємо івент відмови в твій Блок
                          // game.gameCubit.add(RejectGameEvent());
                          context.read<GameBloc>().add(NewGameResponse(false));
              
                          // 2. Ховаємо це віконце
                          game.overlays.remove('InviteDialog');
                        },
                        child: const Text(
                          'Відхилити',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      // Кнопка Погодитись
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        onPressed: () {
                          // 1. Відправляємо івент згоди в Блок (очищення поля тощо)
                          // game.gameCubit.add(AcceptGameEvent());
                          context.read<GameBloc>().add(NewGameResponse(true));
              
                          // 2. Ховаємо віконце
                          game.overlays.remove('InviteDialog');
                        },
                        child: const Text(
                          'Грати',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}