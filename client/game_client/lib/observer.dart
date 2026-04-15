import 'package:flutter_bloc/flutter_bloc.dart';

class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    //print('OnEvent myObserver. event == $event');
    super.onEvent(bloc, event);
  }

  // onChange(Cubit cubit, Change change)
  @override
  void onChange(BlocBase bloc, Change change) {
    //print(change);
    super.onChange(bloc, change);
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    //print('onTransition myObserver. event == $transition');
    super.onTransition(bloc, transition);
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    print('onError myObserver. error == $error');
    super.onError(bloc, error, stackTrace);
  }
}
