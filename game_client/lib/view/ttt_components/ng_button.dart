import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';

import 'package:flutter/material.dart';

import '../../bloc/event_state/game_es.dart';
import '../../bloc/game_bloc.dart';
import '../root_page.dart';
import 'board.dart';

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