import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_client/bloc/auth_bloc.dart';
import 'package:game_client/bloc/game_bloc.dart';
import 'package:game_client/view/game_page.dart';
//import 'package:game_client/bloc/provider_bloc.dart';
//import 'package:game_client/view/game_page.dart';

import 'bloc/observer.dart';
import 'bloc/provider_bloc.dart';
//import 'events/auth_event_state.dart';
import 'view/authorisation_page.dart';

Future<void> main() async {
  Bloc.observer = SimpleBlocObserver();
  /*BlocProvider(
    create: (context) => ProviderBloc(),
    child: const App(),
  );
  */ //runApp(const AuthorisationPage());
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    print("App build");
    return BlocProvider(
      create: (_) => ProviderBloc(),
      child: BlocProvider(
        create: (_) => AuthBloc(),
        child: BlocProvider(
          create: (_) => GameBloc(),
          child: BlocBuilder<ProviderBloc, ProviderState>(
            builder: (_, state) {
              if (state is AuthProviderState) {
                print("state is AuthorisationPage");
                return const AuthorisationPage();
              }
              /*if (state is WebSocetConnectionState) {
                print("state is WebSocetConnectionState");
                return const WebSocetConnectionPage();
              }*/
              if (state is GameProviderState) {
                print("state is GameProviderState");
                return const GamePage();
              } else {
                print("state isn't AuthorisationPage");
                return const AuthorisationPage();
              }
            },
          ),
        ),
      ),
    );
  }
  /*  // It is work
  @override
  Widget build(BuildContext context) {
    print("App build");
    return MaterialApp(
      home: BlocProvider(
        create: (_) => AuthBloc(),
        child: const AuthorisationPage(),
      ),
    );
  }
  */
  /*@override   // It isn't work
  Widget build(BuildContext context) {
    print("App Build");
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: BlocBuilder<ProviderBloc, ProviderState>(
        builder: (_, state) {
          /*if(state is LoadingState) {
                  print("LoadingPage");
                  return LoadingPage();
                } else*/
          if (state is AuthProviderState) {
            print("Auth State");
            return const AuthorisationPage();
          } else if (state is GameProviderState) {
            print("Game State");
            return const GamePage();
          } else {
            print("else Auth State");
            return const AuthorisationPage();
          }
        },
      ),
    );
  }*/
}
