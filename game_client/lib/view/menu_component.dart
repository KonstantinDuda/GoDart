import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/event_state/game_es.dart';
import '../bloc/game_bloc.dart';
import 'root_page.dart';

// ==========================================
// 1. КОМПОНЕНТ КОНТЕЙНЕРА ЛІВОГО МЕНЮ
// ==========================================
class MenuComponent extends PositionComponent with HasGameReference<RootPage> {
  late final MenuButtonComponent localBtn;
  late final MenuButtonComponent aiBtn;
  late final MenuButtonComponent onlineBtn;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Меню займає 30% ширини екрана і 100% його висоти
    position = Vector2(0, 0);
    this.size = Vector2(size.x * 0.3, size.y);

    if (!isLoaded) return;

    // Рахуємо нову ширину для кнопок на основі СВІЖОГО розміру меню
    double targetButtonWidth = this.size.x * 0.8;
    double targetX = (this.size.x - targetButtonWidth) / 2;

    // Передаємо нові розміри кожній кнопці примусово!
    localBtn.updateLayout(targetX, targetButtonWidth);
    aiBtn.updateLayout(targetX, targetButtonWidth);
    onlineBtn.updateLayout(targetX, targetButtonWidth);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // Висота однієї кнопки меню та відступ між ними
    double btnHeight = 50.0;
    double gap = 20.0;

    // Додаємо 3 кнопки всередину меню, розподіляючи їх по вертикалі
    // Кнопка 1: Локальна гра
    localBtn = MenuButtonComponent(
      text: '2 Гравці',
      yPosition: 100.0,
      buttonHeight: btnHeight,
      modeValue: GameplayEnum.twoPlonePC, // Значення режиму для твого Блоку
    );

    // Кнопка 2: Гра проти робота
    aiBtn = MenuButtonComponent(
      text: 'Проти ШІ',
      yPosition: 100.0 + btnHeight + gap,
      buttonHeight: btnHeight,
      modeValue: GameplayEnum.vsAI,
    );

    // Кнопка 3: Мережева гра
    onlineBtn = MenuButtonComponent(
      text: 'Грати онлайн',
      yPosition: 100.0 + (btnHeight + gap) * 2,
      buttonHeight: btnHeight,
      modeValue: GameplayEnum.playOnline,
    );

    await add(localBtn);
    await add(aiBtn);
    await add(onlineBtn);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x == 0 || size.y == 0) return;

    // Малюємо фон для панелі меню (трохи темніший за основний фон гри)
    final menuBackgroundPaint = Paint()
      ..color =
          const Color.fromARGB(255, 20, 21, 30) // Насичений темний колір
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), menuBackgroundPaint);

    // Додатково малюємо тонку роздільну лінію справа, що відокремлює меню від ігрової зони
    final borderPaint = Paint()
      ..color = const Color.fromARGB(255, 38, 41, 56)
      ..strokeWidth = 2;

    canvas.drawLine(Offset(size.x, 0), Offset(size.x, size.y), borderPaint);
  }
}

// ==========================================
// 2. КОМПОНЕНТ КНОПКИ МЕНЮ
// ==========================================
class MenuButtonComponent extends PositionComponent
    with
        HasGameReference<RootPage>,
        TapCallbacks,
        FlameBlocReader<GameBloc, GameState>,
        FlameBlocListenable<GameBloc, GameState> {
  final String text;
  final double yPosition;
  final double buttonHeight;
  final GameplayEnum
  modeValue; // Передаємо унікальне значення режиму ('local', 'ai', 'online')

  // Локальний прапорець: чи є цей режим активним наразі
  bool _isActive = false;

  MenuButtonComponent({
    required this.text,
    required this.yPosition,
    required this.buttonHeight,
    required this.modeValue,
  });

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    // Батьківський компонент тут — це MenuComponent (ліві 30% екрана)
    // Робимо кнопку шириною в 80% від ширини меню
    final parentSize = (parent as PositionComponent).size;
    double buttonWidth = parentSize.x * 0.8;

    // Центруємо кнопку по горизонталі всередині меню
    double x = (parentSize.x - buttonWidth) / 2;

    position = Vector2(x, yPosition);
    this.size = Vector2(buttonWidth, buttonHeight);
  }

  void updateLayout(double x, double width) {
    position = Vector2(x, yPosition);
    size = Vector2(width, buttonHeight);
  }

  _checkIsActive(GameState state) {
    if (state is GameLoaded) {
      _isActive = (state.gameplay == modeValue);
    } else {
      _isActive = false;
    }
  }

  @override
  void onMount() {
     super.onMount();
    
    // Оскільки ця кнопка є дитиною всередині FlameBlocProvider,
    // на момент завершення super.onLoad() Блок уже 100% підключений і доступний!
    try {
      print("MenuButtonComponent: Блок доступний, перевіряємо початковий стан.");
      final initialState = bloc.state;
      _checkIsActive(initialState);
    } catch (e) {
      // Страховка: якщо у твоїй версії пакета Блок ініціалізується ще трохи пізніше,
      // ми просто відкладемо перевірку на один фрейм додатка
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (isMounted) {
          print("MenuButtonComponent: Блок став доступним після затримки, перевіряємо стан знову.");
          _checkIsActive(bloc.state);
        }
      });
    }
  }

  @override
  void onNewState(GameState state) {
    super.onNewState(state);

    _checkIsActive(state);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (size.x == 0 || size.y == 0) return;

    // ВИТБІР КОЛЬОРУ НА ОСНОВІ СТАТУСУ КНОПКИ
    final Color buttonColor = _isActive
        ? const Color.fromARGB(
            255,
            96,
            97,
            63,
          ) // const Color.fromARGB(255, 33, 150, 243)  // Яскравий синій колір для ОБРАНОГО режиму
        : const Color.fromARGB(
            255,
            38,
            41,
            56,
          ); // Стандартний темно-сірий для неактивних

    final Color textColor = _isActive
        ? const Color.fromARGB(
            255,
            255,
            255,
            255,
          ) // Білий текст для активної кнопки
        : const Color.fromARGB(
            255,
            170,
            170,
            180,
          ); // Тьмяніший сірий для неактивних

    // Малюємо тіло кнопки (темно-сіра плашка)
    final btnPaint = Paint()
      ..color = buttonColor
      ..style = PaintingStyle.fill;

    final rrect = RRect.fromRectAndRadius(
      size.toRect(),
      const Radius.circular(8),
    );
    canvas.drawRRect(rrect, btnPaint);

    // Малюємо текст на кнопці за допомогою TextPainter
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor, // Використовуємо змінну textColor
          fontSize: 16,
          fontWeight: _isActive ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Рівняємо текст рівно по центру кнопки
    double textX = (size.x - textPainter.width) / 2;
    double textY = (size.y - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(textX, textY));
  }

  // ОБРОБКА ТАПУ НА КНОПКУ РЕЖИМУ
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // ВІДПРАВЛЯЄМО ІВЕНТ ЗМІНИ РЕЖИМУ У ТВІЙ БЛОК
    // Заміни SelectGameModeEvent на назву твого реального івенту (наприклад, ChangeMode(modeValue))
    bloc.add(ChangeGameplay(modeValue));

    print('Обрано режим гри: $modeValue. Івент надіслано в Блок.');
  }
}
