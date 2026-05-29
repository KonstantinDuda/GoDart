import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';
import 'package:flutter/material.dart';

import '../../bloc/event_state/game_es.dart';
import '../../bloc/game_bloc.dart';
import '../root_page.dart';
import 'board.dart';

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