import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';

import 'package:flutter/material.dart';

import '../../bloc/event_state/game_es.dart';
import '../../bloc/game_bloc.dart';
import '../root_page.dart';

class CellAnimation {
  String value;
  double progress;

  CellAnimation({required this.value, required this.progress});
}

class BoardComponent extends PositionComponent
    with
        HasGameReference<RootPage>,
        TapCallbacks,
        FlameBlocReader<GameBloc, GameState>,
        FlameBlocListenable<GameBloc, GameState> {

List<CellAnimation> _cells = List.generate(9, (_) => CellAnimation(value: '', progress: 0.0));

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    //print("BoardComponent resized: $size");

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

  //List<String> _currentField = List.filled(9, ""); // Стан поля для відображення
  @override
  void onNewState(GameState state) {
    super.onNewState(state);

    // Оновлюємо стан поля, коли отримуємо новий стан гри
    if(state is GameLoaded) {
      for(int i = 0; i < 9; i++) {
        String newValue = state.field[i];

        if(newValue != _cells[i].value) {
          if(newValue == '') {
            // Якщо гру скинули (кнопка Нова гра) — миттєво очищаємо
          _cells[i] = CellAnimation(value: '', progress: 0.0);
          } else {
            // Якщо поставили Х або О — запускаємо анімацію з 0.0 прогресу
          _cells[i] = CellAnimation(value: newValue, progress: 0.0);
          }
        }
      }
    }
    //_currentField = (state is GameLoaded) ? state.field : List.filled(9, "");
  }

  @override
  void update(double dt) {
    super.update(dt);
  
    double animationSpeed = 4.0;

    for(var cell in _cells) {
      if(cell.value != '' && cell.progress < 1.0) {
        cell.progress += animationSpeed * dt;
        if(cell.progress > 1.0) cell.progress = 1.0;
      }
    }
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
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final oPaint = Paint()
      ..color = Color.fromARGB(255, 84, 172, 230)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Відступ всередині клітинки, щоб фігурки не торкалися ліній сітки
    double padding = cellSize * 0.2;

    // 3. Малюємо X та O відповідно до стану поля
    for (int i = 0; i < 9; i++) {
      CellAnimation cell = _cells[i];
      if (cell.value == '') continue;

      int row = i ~/ 3; // Рядок (0, 1, 2)
      int col = i % 3; // Стовпець (0, 1, 2)

      double left = col * cellSize + padding;
      double top = row * cellSize + padding;
      double right = (col + 1) * cellSize - padding;
      double bottom = (row + 1) * cellSize - padding;

      double progress = cell.progress;

      if (cell.value == "X") {
        // АНІМАЦІЯ ХРЕСТИКА: Ефект малювання ліній "від початку до кінця"
        // Перша лінія: малюється від лівого верхнього кута, довжина залежить від p
double currentRight1 = left + (right - left) * progress;
double currentBottom1 = top + (bottom - top) * progress;
        canvas.drawLine(Offset(left, top), Offset(currentRight1, currentBottom1), xPaint);
        
        // Друга лінія починає малюватися, наприклад, паралельно або трохи пізніше
        // Для ефекту послідовного малювання, малюємо її теж на основі прогресу p
        double currentLeft2 = left + (right - left) * (1 - progress);
        double currentBottom2 = top + (bottom - top) * progress;
        if(progress > 0.1) { // Невеликий зсув, щоб лінії виглядали природно
          canvas.drawLine(Offset(right, top), Offset(currentLeft2, currentBottom2), xPaint);
        }
      } else if (cell.value == "O") {
        // Малюємо O
        double centerX = left + (cellSize - padding * 2) / 2;
        double centerY = top + (cellSize - padding * 2) / 2;
        double radius = (cellSize - padding * 2) / 2;

        // Визначаємо квадратні межі для дуги
        Rect oval = Rect.fromCircle(center: Offset(centerX, centerY), radius: radius);
        
        // Початковий кут - верхня точка кола (-pi / 2 радіан або -90 градусів)
        double startAngle = -pi / 2;
        // Кінцевий кут залежить від прогресу p (повне коло — це 2 * pi радіан)
        double sweepAngle = 2 * pi * progress;


        canvas.drawArc(oval, startAngle, sweepAngle, false, oPaint);
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