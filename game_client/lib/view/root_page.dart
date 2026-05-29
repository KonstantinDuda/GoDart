import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flame/game.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/event_state/game_es.dart';
import '../bloc/game_bloc.dart';
import 'menu_component.dart';
import 'ttt_components/board.dart';
import 'ttt_components/ng_button.dart';
import 'ttt_components/status_text.dart';

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