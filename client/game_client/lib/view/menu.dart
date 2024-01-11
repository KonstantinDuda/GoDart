import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/provider_bloc.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: <Widget>[
            TextButton(
                onPressed: () {
                  context.read<ProviderBloc>().add(GameProviderEvent(true));
                },
                child: const Text("Грати проти людини")),
            TextButton(
                onPressed: () {
                  context.read<ProviderBloc>().add(GameProviderEvent(false));
                },
                child: const Text("Грати проти програми")),
          ],
        ),
      ),
    );
  }
}
