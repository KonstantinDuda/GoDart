import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/event_state/game_es.dart';
import 'observer.dart';
import 'bloc/provider_bloc.dart';
import 'bloc/game_bloc.dart';
import 'view/root_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  Bloc.observer = SimpleBlocObserver();

  runApp(
    BlocProvider(create: (context) => ProviderBloc(), child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Game',
      home: BlocProvider(
        create: (_) => GameBloc()..add(GameConnectToServer()),
        child: const RootPage(),
      ),
    );
  }
}
